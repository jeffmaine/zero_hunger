enum UserRole { donor, receiver, volunteer, admin }

UserRole? userRoleFromString(String? value) {
  if (value == null) return null;
  try {
    return UserRole.values.byName(value);
  } catch (_) {
    return null;
  }
}

extension UserRoleX on UserRole {
  String get apiValue => name;
}

enum ListingStatus { available, claimed, paused, completed, expired, cancelled }

enum ClaimStatus { pending, approved, rejected, collected }

ListingStatus? listingStatusFromString(String? v) {
  if (v == null) return null;
  try {
    return ListingStatus.values.byName(v);
  } catch (_) {
    return null;
  }
}

ClaimStatus? claimStatusFromString(String? v) {
  if (v == null) return null;
  try {
    return ClaimStatus.values.byName(v);
  } catch (_) {
    return null;
  }
}
