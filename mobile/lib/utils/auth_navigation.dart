import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../models/user.dart';

const String kVolunteerPhase2Message =
    'Volunteer deliveries are coming in Phase 2. For now, choose Donor or Receiver to sign up.';

/// Blocks signup when [role] is volunteer (not supported in MVP yet).
bool blockVolunteerSignup(BuildContext context, UserRole role) {
  if (role != UserRole.volunteer) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(kVolunteerPhase2Message)),
  );
  return true;
}

void goAfterAuth(BuildContext context, UserModel user) {
  switch (user.role) {
    case UserRole.donor:
      context.go('/donor');
    case UserRole.receiver:
      context.go('/receiver');
    case UserRole.volunteer:
    case UserRole.admin:
      context.go('/receiver');
  }
}
