import 'dart:convert';

import 'package:crypto/crypto.dart';

String hmacSha256(
  String secret,
  String message, {
  Encoding secretEncoding = utf8,
  Encoding messageEncoding = utf8,
}) {
  final hmac = Hmac(sha256, secretEncoding.encode(secret));
  return hmac.convert(messageEncoding.encode(message)).toString();
}
