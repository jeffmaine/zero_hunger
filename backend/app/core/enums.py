from enum import Enum


class TokenType(str, Enum):
    ACCESS = "access"
    REFRESH = "refresh"


class OneTimeTokenType(str, Enum):
    GOOGLE_SESSION = "google_session"


class UserRole(str, Enum):
    DONOR = "donor"
    RECEIVER = "receiver"
    VOLUNTEER = "volunteer"
    ADMIN = "admin"


class AuthProvider(str, Enum):
    MANUAL = "manual"
    GOOGLE = "google"


class ListingCategory(str, Enum):
    COOKED_MEAL = "cooked_meal"
    GROCERIES = "groceries"
    BAKED_GOODS = "baked_goods"
    FRUITS = "fruits"
    BEVERAGES = "beverages"


class ListingStatus(str, Enum):
    AVAILABLE = "available"
    CLAIMED = "claimed"
    PAUSED = "paused"
    COMPLETED = "completed"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class ClaimStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    COLLECTED = "collected"


class NotificationType(str, Enum):
    CLAIM_RECEIVED = "claim_received"
    CLAIM_APPROVED = "claim_approved"
    CLAIM_REJECTED = "claim_rejected"
    LISTING_EXPIRING = "listing_expiring"


class DeliveryStatus(str, Enum):
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
