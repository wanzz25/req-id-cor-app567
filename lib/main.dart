import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RobloxSongRequestApp());
}

class RobloxSongRequestApp extends StatelessWidget {
  const RobloxSongRequestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REQ ID COR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const SplashPage(),
    );
  }
}
