import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import '../widgets/rules_overlay.dart';
import '../widgets/animated_bg.dart';
import 'login_page.dart';
import 'song_page.dart';
import 'banner_page.dart';
import 'history_page.dart';
import 'ticket_page.dart';

/// Struktur navigasi ini SAMA PERSIS kayak website (public/index.html):
/// - Header hero (logo, judul, subtitle, chip "by wanz")
/// - User bar (@username + Ganti akun)
/// - Promo channel WhatsApp
/// - 3 tab di atas (.tabs / .tab-btn): Song Request, Banner Request, Request Saya
/// - Tiket CS BUKAN tab keempat, tapi tombol melayang (.tk-fab) pojok kanan
///   bawah yang buka tiket sebagai overlay/modal.
/// - Rules overlay (Panduan & Peraturan) muncul sekali di awal, persis website.
/// Ini dikunci gak akan diubah strukturnya lagi kecuali diminta.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Timer? _statusTimer;

  final _pages = const [
    SongPage(),
    BannerPage(),
    HistoryPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => showRulesOverlayIfNeeded(context));
    // Cek status app (online/maintenance/offline) begitu masuk, terus tiap 30 detik --
    // persis website yang polling /api/status berkala buat nampilin overlay.
    ApiService.instance.refreshPingStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) => ApiService.instance.refreshPingStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _openTicket() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const TicketPage(),
      fullscreenDialog: true,
    ));
  }

  void _doLogout() async {
    await ApiService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBgOrbs()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeroHeader(),
                const AnnounceBar(),
                UserBar(onLogout: () => showLogoutConfirm(context, _doLogout)),
                const WaPromoBanner(),
                _TopTabs(current: _tab, onChanged: (i) => setState(() => _tab = i)),
                Expanded(child: IndexedStack(index: _tab, children: _pages)),
              ],
            ),
          ),
          const AppStatusOverlay(),
        ],
      ),
      floatingActionButton: _TicketFab(onTap: _openTicket),
    );
  }
}

/// Tab bar atas — samain persis .tabs/.tab-btn di website:
/// background rgba(255,255,255,.02), radius 16, padding 6, gap 8;
/// item aktif gradient ungu + ring rgba(124,58,237,.3).
class _TopTabs extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _TopTabs({required this.current, required this.onChanged});

  static const _items = [
    (icon: Icons.music_note_rounded, label: 'Song Request'),
    (icon: Icons.image_outlined, label: 'Banner Request'),
    (icon: Icons.person_outline, label: 'Request Saya'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = current == i;
          final item = _items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: active
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.purple.withOpacity(0.3), AppColors.purpleLight.withOpacity(0.2)],
                        )
                      : null,
                  border: active ? Border.all(color: AppColors.purple.withOpacity(0.3)) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 15, color: active ? AppColors.purpleLight : AppColors.muted),
                    const SizedBox(height: 3),
                    Text(item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: active ? AppColors.purpleLight : AppColors.muted)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Tombol melayang buat Tiket CS — persis .tk-fab: bulat 56px,
/// gradient linear-gradient(135deg,#7c3aed,#06b6d4), shadow ungu.
class _TicketFab extends StatelessWidget {
  final VoidCallback onTap;
  const _TicketFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purple, AppColors.cyan],
          ),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.5), blurRadius: 28, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
