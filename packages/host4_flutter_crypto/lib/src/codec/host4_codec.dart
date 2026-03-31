import 'dart:convert';

String base64EncodeUtf8(String input) {
  return base64.encode(utf8.encode(input));
}

String base64DecodeUtf8(String encoded) {
  return utf8.decode(base64.decode(encoded));
}
