import 'package:flutter_test/flutter_test.dart';

import 'package:host4_flutter_crypto/host4_flutter_crypto.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });
}
