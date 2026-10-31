/// Who can do what on ScholAI.
///
/// Students use the app. Professionals are approved helpers.
/// Admins review applications and the support queue.
/// Super admins can change any role.
enum PlatformRole {
  student,
  professional,
  admin,
  superAdmin;

  String get wire => switch (this) {
        PlatformRole.student => 'student',
        PlatformRole.professional => 'professional',
        PlatformRole.admin => 'admin',
        PlatformRole.superAdmin => 'superAdmin',
      };

  String get label => switch (this) {
        PlatformRole.student => 'Student',
        PlatformRole.professional => 'Professional',
        PlatformRole.admin => 'Admin',
        PlatformRole.superAdmin => 'Super admin',
      };

  bool get canManagePlatform =>
      this == PlatformRole.admin || this == PlatformRole.superAdmin;

  bool get canAssignRoles => this == PlatformRole.superAdmin;

  static PlatformRole fromWire(String? value) => switch (value) {
        'professional' => PlatformRole.professional,
        'admin' => PlatformRole.admin,
        'superAdmin' => PlatformRole.superAdmin,
        _ => PlatformRole.student,
      };
}

/// Google accounts that become super admin on first sign-in.
/// Keep this list in sync with `isBootstrap()` in `firestore.rules`.
const kBootstrapSuperAdminEmails = {
  'mbakaragoodness2003@gmail.com',
  'amicablembakara50@gmail.com',
};

bool isBootstrapSuperAdmin(String? email) {
  if (email == null || email.trim().isEmpty) return false;
  return kBootstrapSuperAdminEmails.contains(email.trim().toLowerCase());
}
