import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/animated_bg.dart';
import 'home_shell.dart';
import 'public_ticket_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey  = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final d = await ApiService.instance.login(_userCtrl.text.trim());
      if (!mounted) return;

      if (d['valid'] != true) {
        _toast(d['message'] ?? 'Username tidak ditemukan.', isError: true);
      } else if (d['expired'] == true) {
        _toast(d['message'] ?? 'Akun kamu sudah expired. Hubungi owner.', isError: true);
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    } catch (e) {
      _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.red : AppColors.green, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
    ));
  }

  void _openTicket() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PublicTicketPage(), fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: AnimatedBgOrbs()),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header (persis <header> di login.html) ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 30, spreadRadius: 2)],
                      ),
                      child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFF1F5F9), AppColors.purpleLight, AppColors.cyan])
                        .createShader(b),
                    child: Text('Roblox Request Id Cor',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 4),
                  Text('Clarity Over Resonance', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('by wanz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // ── Card login (persis .card di login.html) ──
                  CardInAnimation(
                    child: GlassCard(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Masuk ke Panel Request',
                                style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                            const SizedBox(height: 6),
                            Text('Masukkan username kamu untuk melacak status request (ACC/Ditolak). Tidak perlu password.',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), height: 1.5)),
                            const SizedBox(height: 20),
                            const Text('USERNAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.7)),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _userCtrl,
                              style: const TextStyle(color: AppColors.textMain),
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                hintText: 'Username kamu...',
                                prefixIcon: Icon(Icons.person_outline, color: AppColors.muted, size: 19),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Username tidak boleh kosong.' : null,
                              onFieldSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 20),
                            GradientButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Text('Masuk'),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                                    ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Dibuat oleh  '),
                      TextSpan(text: 'wanz', style: TextStyle(color: AppColors.purple.withOpacity(0.9), fontWeight: FontWeight.w700)),
                      const TextSpan(text: '  — © 2026'),
                    ]),
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25), letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
      // Tiket CS selalu aktif walau belum login -- persis .tk-fab di login.html
      floatingActionButton: FloatingActionButton(
        onPressed: _openTicket,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.purple, AppColors.cyan]),
          ),
          child: const Icon(Icons.support_agent_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
