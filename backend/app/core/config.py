from enum import Enum

from pydantic_settings import BaseSettings, SettingsConfigDict


class EnvironmentEnum(str, Enum):
    DEV = "dev"
    STAGING = "staging"
    PRODUCTION = "production"


class Settings(BaseSettings):
    ENVIRONMENT: EnvironmentEnum = EnvironmentEnum.DEV
    LOG_LEVEL: str = "INFO"

    APP_NAME: str = "Zero Hunger API"
    APP_DESCRIPTION: str = "Food redistribution platform API"
    APP_VERSION: str = "1.0.0"

    SECRET_KEY: str = "dev-secret-change-in-production"
    ACCESS_SECRET: str = "dev-access-secret-change-in-production"
    REFRESH_SECRET: str = "dev-refresh-secret-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    DB_NAME: str = "zerohunger"
    DB_USER: str = "postgres"
    DB_PASSWORD: str = "postgres"
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_TYPE: str = "postgresql+asyncpg"
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 10
    DB_POOL_TIMEOUT: int = 30
    DB_POOL_RECYCLE: int = 7200

    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080"
    CORS_METHODS: str = "GET,POST,PUT,PATCH,DELETE,OPTIONS"
    CORS_HEADERS: str = "Authorization,Content-Type,X-Request-ID"
    MAX_REQUEST_BODY_BYTES: int = 10 * 1024 * 1024
    RATE_LIMIT_ENABLED: bool = True

    DEFAULT_SEARCH_RADIUS_KM: float = 5.0
    MAX_SEARCH_RADIUS_KM: float = 50.0

    MAX_ACTIVE_CLAIMS_PER_RECEIVER: int = 2
    CLAIM_COOLDOWN_HOURS: int = 6
    MAX_CLAIM_NO_SHOWS: int = 3

    FCM_ENABLED: bool = False
    FIREBASE_CREDENTIALS_PATH: str = ""

    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""
    GOOGLE_REDIRECT_URI: str = "http://localhost:8000/api/v1/oauth/google/callback"
    FRONTEND_REDIRECT_URL: str = "http://localhost:8080/auth/google/callback"

    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        env_ignore_empty=True,
    )

    @property
    def DEBUG(self) -> bool:
        return self.ENVIRONMENT == EnvironmentEnum.DEV

    @property
    def database_url(self) -> str:
        return (
            f"{self.DB_TYPE}://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )

    @property
    def google_configured(self) -> bool:
        return bool(self.GOOGLE_CLIENT_ID and self.GOOGLE_CLIENT_SECRET)


Config = Settings()
