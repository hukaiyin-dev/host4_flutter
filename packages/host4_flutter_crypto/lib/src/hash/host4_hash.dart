import 'dart:convert';

import 'package:crypto/crypto.dart';

String sha256OfString(String input, {Encoding encoding = utf8}) {
  return sha256OfBytes(encoding.encode(input));
}

String sha256OfBytes(List<int> bytes) {
  return sha256.convert(bytes).toString();
}
