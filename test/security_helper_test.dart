import 'package:flutter_test/flutter_test.dart';
import 'package:arena/core/utils/security_helper.dart';

void main() {
  group('SecurityHelper Tests', () {
    test('Password hashing generates 64-character SHA-256 hex string', () {
      final hash1 = SecurityHelper.hashPassword('123456');
      expect(hash1.length, 64);
      expect(SecurityHelper.isHashed(hash1), isTrue);
      expect(SecurityHelper.isHashed('123456'), isFalse);
    });

    test('Password verification works correctly for hashed and plain passwords', () {
      const password = 'mySecretPassword99';
      final hash = SecurityHelper.hashPassword(password);

      // Verify with hashed
      expect(SecurityHelper.verifyPassword(password, hash), isTrue);
      expect(SecurityHelper.verifyPassword('wrongPassword', hash), isFalse);

      // Verify backward compatibility with plain text
      expect(SecurityHelper.verifyPassword('plainPass', 'plainPass'), isTrue);
      expect(SecurityHelper.verifyPassword('wrong', 'plainPass'), isFalse);
    });
  });
}
