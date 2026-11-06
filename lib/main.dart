
import 'package:flutter/cupertino.dart';
import 'app_shell.dart';

void main() {
  runApp(const TempAlertApp());
}

class TempAlertApp extends StatelessWidget {
  const TempAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Pipe Guard',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF007AFF),
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
        barBackgroundColor: Color(0xEEFFFFFF),
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontSize: 16,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ),
      home: AppShell(),
    );
  }
}
