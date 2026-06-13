from contextlib import asynccontextmanager
from typing import AsyncGenerator, Optional

from sqlalchemy import event, text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.config import Config
from app.core.logging import get_logger

logger = get_logger(__name__)


class AsyncDatabase:
    def __init__(self) -> None:
        self._engine: Optional[AsyncEngine] = None
        self._session_factory: Optional[async_sessionmaker[AsyncSession]] = None

    def create_engine(self) -> AsyncEngine:
        if self._engine is not None:
            return self._engine
        self._engine = create_async_engine(
            url=Config.database_url,
            echo=Config.DEBUG,
            pool_size=Config.DB_POOL_SIZE,
            max_overflow=Config.DB_MAX_OVERFLOW,
            pool_timeout=Config.DB_POOL_TIMEOUT,
            pool_recycle=Config.DB_POOL_RECYCLE,
            pool_pre_ping=True,
        )

        @event.listens_for(self._engine.sync_engine, "connect")
        def _on_connect(_dbapi_connection, _connection_record):
            logger.debug("DB connection established")

        return self._engine

    def create_session_factory(self) -> async_sessionmaker[AsyncSession]:
        if self._session_factory is not None:
            return self._session_factory
        if self._engine is None:
            self.create_engine()
        self._session_factory = async_sessionmaker(
            bind=self._engine,
            class_=AsyncSession,
            expire_on_commit=False,
            autoflush=True,
        )
        return self._session_factory

    @asynccontextmanager
    async def get_session(self) -> AsyncGenerator[AsyncSession, None]:
        factory = self.create_session_factory()
        session = factory()
        try:
            yield session
            if session.in_transaction():
                await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

    async def startup(self) -> None:
        self.create_session_factory()
        if not await self._health_check():
            raise RuntimeError("Failed to connect to database")
        logger.info("Database connection established")

    async def shutdown(self) -> None:
        if self._engine:
            await self._engine.dispose()
            logger.info("Database connections closed")

    async def _health_check(self) -> bool:
        try:
            async with self.get_session() as session:
                result = await session.execute(text("SELECT 1"))
                return result.scalar() == 1
        except Exception as e:
            logger.error("Database health check failed: %s", e)
            return False


database = AsyncDatabase()


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    async with database.get_session() as session:
        yield session
