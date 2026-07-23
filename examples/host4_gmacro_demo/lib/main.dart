import 'package:flutter/material.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Host4GmacroDemoApp());
}

class Host4GmacroDemoApp extends StatelessWidget {
  const Host4GmacroDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Host4 GMacro Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      home: const GmacroEntryPage(),
    );
  }
}
