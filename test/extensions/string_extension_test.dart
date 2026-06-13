import 'package:flutter_test/flutter_test.dart';
import 'package:learn_flutter/core/extension/src/string_extension.dart';

void main() {
  group('StringExtension.isNullOrEmpty', () {
    test('null is null or empty', () => expect((null as String?).isNullOrEmpty, isTrue));
    test('empty string is null or empty', () => expect(''.isNullOrEmpty, isTrue));
    test('non-empty string is NOT null or empty', () => expect('hello'.isNullOrEmpty, isFalse));
  });

  group('StringExtension.isNotNullOrEmpty', () {
    test('null is not not-null-or-empty', () => expect((null as String?).isNotNullOrEmpty, isFalse));
    test('empty is not not-null-or-empty', () => expect(''.isNotNullOrEmpty, isFalse));
    test('non-empty is not-null-or-empty', () => expect('hi'.isNotNullOrEmpty, isTrue));
  });

  group('StringExtension.orEmpty', () {
    test('null returns empty string', () => expect((null as String?).orEmpty, ''));
    test('value returns itself', () => expect('hello'.orEmpty, 'hello'));
  });

  group('StringExtension.isValidEmail', () {
    test('valid email returns true', () => expect('user@example.com'.isValidEmail, isTrue));
    test('missing @ returns false', () => expect('userexample.com'.isValidEmail, isFalse));
    test('missing domain returns false', () => expect('user@'.isValidEmail, isFalse));
    test('null returns false', () => expect((null as String?).isValidEmail, isFalse));
    test('sub-domain email returns true', () => expect('a@b.co'.isValidEmail, isTrue));
    test('email with dots in local returns true',
        () => expect('first.last@example.org'.isValidEmail, isTrue));
  });

  group('StringExtension.convertToDateTime', () {
    test('parses ISO format', () {
      final dt = '2024-01-15T10:30:00'.convertToDateTime;
      expect(dt, isNotNull);
      expect(dt!.year, 2024);
      expect(dt.month, 1);
      expect(dt.day, 15);
    });

    test('parses date-only format', () {
      final dt = '2024-03-20'.convertToDateTime;
      expect(dt, isNotNull);
      expect(dt!.year, 2024);
    });

    test('returns null for invalid string', () {
      expect('not-a-date'.convertToDateTime, isNull);
    });

    test('returns null for null', () {
      expect((null as String?).convertToDateTime, isNull);
    });

    test('replaces slash separator', () {
      final dt = '2024/06/13'.convertToDateTime;
      expect(dt, isNotNull);
      expect(dt!.year, 2024);
    });
  });

  group('StringExtension.ext', () {
    test('extracts file extension', () => expect('photo.jpg'.ext, 'jpg'));
    test('returns lowercase extension', () => expect('file.PNG'.ext, 'png'));
    test('null returns empty string', () => expect((null as String?).ext, ''));
  });

  group('StringExtension.isHTML', () {
    test('HTML string returns true', () => expect('<p>Hello</p>'.isHTML(), isTrue));
    test('plain text returns false', () => expect('Hello world'.isHTML(), isFalse));
    test('null string returns false', () => expect((null as String?).isHTML(), isFalse));
  });

  group('StringExtension.searchTextList', () {
    test('splits words by space', () {
      expect('hello world'.searchTextList, ['hello', 'world']);
    });

    test('trims extra spaces', () {
      expect('  hello   world  '.searchTextList, ['hello', 'world']);
    });

    test('null returns empty list', () {
      expect((null as String?).searchTextList, []);
    });
  });

  group('StringExtension.fromHex', () {
    test('valid 6-char hex returns Color', () {
      final color = 'FF0000'.fromHex;
      expect(color, isNotNull);
      expect(color!.r, closeTo(1.0, 0.01));
    });

    test('hex with # prefix returns Color', () {
      expect('#00FF00'.fromHex, isNotNull);
    });

    test('null returns null', () {
      expect((null as String?).fromHex, isNull);
    });
  });
}
