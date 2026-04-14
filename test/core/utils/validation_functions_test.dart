import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_app/core/utils/validation_functions.dart';

void main() {
  group('isValidEmail', () {
    test('should return true for valid email', () {
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('user.name@domain.co.uk'), isTrue);
    });

    test('should return false for invalid email', () {
      expect(isValidEmail('invalid-email'), isFalse);
      expect(isValidEmail('test@'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
    });

    test('should return true for null or empty when not required', () {
      expect(isValidEmail(null, isRequired: false), isTrue);
      expect(isValidEmail('', isRequired: false), isTrue);
    });

    test('should return false for null or empty when required', () {
      expect(isValidEmail(null, isRequired: true), isFalse);
      expect(isValidEmail('', isRequired: true), isFalse);
    });
  });

  group('isValidPassword', () {
    test('should return true for valid password (min 8 chars, mixed case, digit, special)', () {
      expect(isValidPassword('Password123!'), isTrue);
    });

    test('should return false for password too short', () {
      expect(isValidPassword('Pass1!'), isFalse);
    });

    test('should return false for password missing uppercase', () {
      expect(isValidPassword('password123!'), isFalse);
    });

    test('should return false for password missing lowercase', () {
      expect(isValidPassword('PASSWORD123!'), isFalse);
    });

    test('should return false for password missing digit', () {
      expect(isValidPassword('Password!'), isFalse);
    });

    test('should return false for password missing special char', () {
      expect(isValidPassword('Password123'), isFalse);
    });

    test('should return false for password with whitespace', () {
      expect(isValidPassword('Pass word123!'), isFalse);
    });

    test('should return true for null or empty when not required', () {
      expect(isValidPassword(null, isRequired: false), isTrue);
      expect(isValidPassword('', isRequired: false), isTrue);
    });

    test('should return false for null or empty when required', () {
      expect(isValidPassword(null, isRequired: true), isFalse);
      expect(isValidPassword('', isRequired: true), isFalse);
    });
  });

  group('isText', () {
    test('should return true for string with only alphabets', () {
      expect(isText('Flutter'), isTrue);
      expect(isText('abc'), isTrue);
    });

    test('should return false for string with numbers or special chars', () {
      expect(isText('Flutter123'), isFalse);
      expect(isText('Flutter!'), isFalse);
      expect(isText('Hello World'), isFalse); // No whitespace allowed
    });

    test('should return true for null or empty when not required', () {
      expect(isText(null, isRequired: false), isTrue);
      expect(isText('', isRequired: false), isTrue);
    });

    test('should return false for null or empty when required', () {
      expect(isText(null, isRequired: true), isFalse);
      expect(isText('', isRequired: true), isFalse);
    });
  });

  group('isNumeric', () {
    test('should return true for string with only digits', () {
      expect(isNumeric('123456'), isTrue);
    });

    test('should return false for string with non-digits', () {
      expect(isNumeric('123a456'), isFalse);
      expect(isNumeric('123.456'), isFalse);
      expect(isNumeric(' 123'), isFalse);
    });

    test('should return true for null or empty when not required', () {
      expect(isNumeric(null, isRequired: false), isTrue);
      expect(isNumeric('', isRequired: false), isTrue);
    });

    test('should return false for null or empty when required', () {
      expect(isNumeric(null, isRequired: true), isFalse);
      expect(isNumeric('', isRequired: true), isFalse);
    });
  });

  group('isValidPhone', () {
    test('should return true for valid phone numbers', () {
      expect(isValidPhone('1234567890'), isTrue);
      expect(isValidPhone('+1234567890'), isTrue);
      expect(isValidPhone('(123) 456-7890'), isTrue);
    });

    test('should return false for too short or too long phone numbers', () {
      expect(isValidPhone('12345'), isFalse); // < 6
      expect(isValidPhone('12345678901234567'), isFalse); // > 16
    });

    test('should return false for invalid characters', () {
      expect(isValidPhone('123-ABC-7890'), isFalse);
    });

    test('should return true for null or empty when not required', () {
      expect(isValidPhone(null, isRequired: false), isTrue);
      expect(isValidPhone('', isRequired: false), isTrue);
    });

    test('should return false for null or empty when required', () {
      expect(isValidPhone(null, isRequired: true), isFalse);
      expect(isValidPhone('', isRequired: true), isFalse);
    });
  });
}
