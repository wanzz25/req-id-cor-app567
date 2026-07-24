import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_bg.dart';
import 'login_page.dart';
import 'home_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await ApiService.instance.loadSession();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final loggedIn = ApiService.instance.isLoggedIn;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => loggedIn ? const HomeShell() : const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: AnimatedBgOrbs()),
        Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 40, spreadRadius: 4),
                  ],
                ),
                child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 22),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1F5F9), AppColors.purpleLight, AppColors.cyan],
              ).createShader(bounds),
              child: Text('REQ ID COR',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.white)),
            ),
            const SizedBox(height: 4),
            Text('CLARITY OVER RESONANCE',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: AppColors.purpleLight.withOpacity(0.75))),
            const SizedBox(height: 8),
            Text('by wanz', style: TextStyle(fontSize: 11, color: AppColors.purpleLight.withOpacity(0.8))),
            const SizedBox(height: 32),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.purpleLight),
            ),
          ],
        ),
        ),
      ]),
    );
  }
}
