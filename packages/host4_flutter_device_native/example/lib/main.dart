import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(const Host4FlutterDeviceNativeExampleApp());
}

class Host4FlutterDeviceNativeExampleApp extends StatelessWidget {
  const Host4FlutterDeviceNativeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Host4 Flutter Device Native Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
