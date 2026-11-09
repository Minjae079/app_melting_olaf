import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pimrwslkvqumueidurir.supabase.co',
    publishableKey: 'sb_publishable_lW0v5zIRxP0tLxsEyLIR0g_ZS3P-0nd',
  );

  runApp(const TempAlertApp());
}

class TempAlertApp extends StatelessWidget {
  const TempAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '배관 동파 모니터링',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const AppShell(),
    );
  }
}
