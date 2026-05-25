from apscheduler.schedulers.asyncio import AsyncIOScheduler

from app.core.logging import get_logger
from app.db.session import database
from app.services.listing import expire_past_deadline

logger = get_logger(__name__)
scheduler = AsyncIOScheduler()


async def _expire_listings_job() -> None:
    async with database.get_session() as db:
        count = await expire_past_deadline(db)
        if count:
            logger.info("Expired %s listing(s)", count)


def setup_scheduler() -> None:
    scheduler.add_job(_expire_listings_job, "interval", minutes=15, id="expire_listings")
