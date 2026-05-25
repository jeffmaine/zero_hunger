import cloudinary
import cloudinary.uploader

from app.core.config import Config
from app.exceptions.custom import BadRequestException


def upload_image(file_bytes: bytes, folder: str = "zero_hunger/listings") -> str:
    if not (
        Config.CLOUDINARY_CLOUD_NAME
        and Config.CLOUDINARY_API_KEY
        and Config.CLOUDINARY_API_SECRET
    ):
        raise BadRequestException(
            "Image upload not configured. Set Cloudinary env vars or pass image_url.",
            code="CLOUDINARY_NOT_CONFIGURED",
        )
    cloudinary.config(
        cloud_name=Config.CLOUDINARY_CLOUD_NAME,
        api_key=Config.CLOUDINARY_API_KEY,
        api_secret=Config.CLOUDINARY_API_SECRET,
        secure=True,
    )
    result = cloudinary.uploader.upload(file_bytes, folder=folder, resource_type="image")
    return result.get("secure_url") or result.get("url", "")
