import 'package:flutter/material.dart';

import 'download_playground_page.dart';

void main() {
  runApp(const DownloadPlaygroundApp());
}

class DownloadPlaygroundApp extends StatelessWidget {
  const DownloadPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Download Playground',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1d6f5f)),
        useMaterial3: true,
      ),
      routes: {'/download-playground': (_) => const DownloadPlaygroundPage()},
      home: const DownloadPlaygroundPage(),
    );
  }
}
