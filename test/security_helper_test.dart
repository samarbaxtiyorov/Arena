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

      // Verify backward compatibility with unsalted SHA-256 from legacy Neon cloud database
      // 0679 hashes to 43e073fe6521716bbfb581165292c9547d58797dec03598ac023d4b886319bed
      const legacyHash = '43e073fe6521716bbfb581165292c9547d58797dec03598ac023d4b886319bed';
      expect(SecurityHelper.verifyPassword('0679', legacyHash), isTrue);
      expect(SecurityHelper.verifyPassword('1111', legacyHash), isFalse);
    });
  });
}
