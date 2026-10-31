import 'package:flutter_test/flutter_test.dart';
import 'package:scholai_app/features/account/domain/platform_role.dart';

void main() {
  test('unknown roles stay students', () {
    expect(PlatformRole.fromWire(null), PlatformRole.student);
    expect(PlatformRole.fromWire('nope'), PlatformRole.student);
    expect(PlatformRole.superAdmin.canAssignRoles, isTrue);
    expect(PlatformRole.admin.canManagePlatform, isTrue);
    expect(PlatformRole.admin.canAssignRoles, isFalse);
    expect(PlatformRole.professional.canManagePlatform, isFalse);
  });

  test('only the bootstrap emails open super admin', () {
    expect(isBootstrapSuperAdmin('mbakaragoodness2003@gmail.com'), isTrue);
    expect(isBootstrapSuperAdmin('AmicableMbakara50@gmail.com'), isTrue);
    expect(isBootstrapSuperAdmin('someone@example.com'), isFalse);
    expect(isBootstrapSuperAdmin(null), isFalse);
  });
}
