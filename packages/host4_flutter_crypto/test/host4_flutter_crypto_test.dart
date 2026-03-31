import 'package:host4_flutter_crypto/host4_flutter_crypto.dart';
import 'package:test/test.dart';

void main() {
  group('sha256', () {
    test('hashes utf8 string input', () {
      expect(
        sha256OfString('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('hashes raw bytes input', () {
      expect(
        sha256OfBytes([97, 98, 99]),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });
  });

  group('hmacSha256', () {
    test('computes expected signature', () {
      expect(
        hmacSha256('key', 'The quick brown fox jumps over the lazy dog'),
        'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8',
      );
    });
  });

  group('base64 utf8 codec', () {
    test('encodes utf8 text to base64', () {
      expect(base64EncodeUtf8('hello'), 'aGVsbG8=');
    });

    test('decodes base64 to utf8 text', () {
      expect(base64DecodeUtf8('5L2g5aW9'), '你好');
    });
  });
}
