import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

/// Bar pengumuman admin — persis .announce-bar + animasi announceScroll
/// (teks geser terus-menerus ke kiri, infinite loop). Hilang kalau admin
/// gak lagi set pengumuman (persis logic display:none di web).
class AnnounceBar extends StatefulWidget {
  const AnnounceBar({super.key});

  @override
  State<AnnounceBar> createState() => _AnnounceBarState();
}

class _AnnounceBarState extends State<AnnounceBar> {
  String? _message;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final msg = await ApiService.instance.getAnnouncement();
    if (mounted) setState(() { _message = (msg != null && msg.trim().isNotEmpty) ? msg.trim() : null; _checked = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.purple.withOpacity(0.18), AppColors.cyan.withOpacity(0.12)]),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.purple.withOpacity(0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [
        const Text('📢', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(child: SizedBox(height: 18, child: _MarqueeText(text: _message!))),
      ]),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  const _MarqueeText({required this.text});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // Kecepatan proporsional panjang teks, kayak `duration = textLen * 0.09s` di web
    final seconds = (widget.text.length * 0.12).clamp(6.0, 30.0);
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: (seconds * 1000).toInt()))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _gap = '                                                            ';

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(fontSize: 12.5, color: Color(0xFFE9D5FF), fontWeight: FontWeight.w600);
    final full = '${widget.text}$_gap';
    final tp = TextPainter(text: TextSpan(text: full, style: style), textDirection: TextDirection.ltr)..layout();
    final segWidth = tp.width;

    return ClipRect(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final dx = -(_c.value * segWidth);
          return Stack(children: [
            Positioned(left: dx, top: 0, child: Text(full, style: style, maxLines: 1, softWrap: false)),
            Positioned(left: dx + segWidth, top: 0, child: Text(full, style: style, maxLines: 1, softWrap: false)),
          ]);
        },
      ),
    );
  }
}

/// Header hero — persis <header> di website: logo kotak gradient + glow
/// berdenyut + border berputar, h1 "Roblox Request Id Cor", subtitle,
/// chip "by wanz" dengan dot berkedip.
class AppHeroHeader extends StatelessWidget {
  const AppHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          const _PulsingLogo(),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFF1F5F9), AppColors.purpleLight, AppColors.cyan])
                .createShader(b),
            child: const Text('Roblox Request Id Cor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text('Ajukan request lagu Id Cor Clarity Over Resonance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.45))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const _BlinkingDot(),
              const SizedBox(width: 6),
              Text('by wanz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Persis @keyframes logoPulse (glow membesar-mengecil 3s) + borderSpin
/// (cincin gradient berputar 4s, blur) di belakang logo.
class _PulsingLogo extends StatefulWidget {
  const _PulsingLogo();

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _spin]),
      builder: (_, __) {
        // logoPulse: 0%/100% shadow kecil -- 50% shadow gede (ring rgba(124,58,237,.4)->0)
        final t = (math.sin(_pulse.value * 2 * math.pi) + 1) / 2; // 0..1..0
        final glowBlur = 32.0 + t * 16.0;
        final glowSpread = t * 14.0;
        return SizedBox(
          width: 84,
          height: 84,
          child: Stack(alignment: Alignment.center, children: [
            // Cincin gradient berputar (borderSpin), diblur -> ganti pakai opacity halus karena blur berat di Flutter mahal
            Transform.rotate(
              angle: _spin.value * 2 * math.pi,
              child: Container(
                width: 82, height: 82,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [AppColors.purple, AppColors.cyan, AppColors.green, AppColors.purple]),
                ),
              ),
            ),
            // Logo kotak (logo-outer + logo-inner), glow berdenyut
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.purple, AppColors.purpleLight, AppColors.cyan],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.35 + t * 0.25), blurRadius: glowBlur, spreadRadius: glowSpread)],
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(18)),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    padding: const EdgeInsets.all(18),
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(4, (_) => Container(
                      decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(2)),
                    )),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// Persis @keyframes dotBlink (opacity 1 <-> .3, 1.5s)
class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.3).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
    );
  }
}

/// User bar — persis .user-bar: "@username" + role, tombol "Ganti akun".
/// Khusus WanzzGantengBanget: persis getDisplayName()/renderUserBar() di
/// website -> tampil "@wanzz" + badge "👑 dev" (bukan username asli/role db).
class UserBar extends StatelessWidget {
  final VoidCallback onLogout;
  const UserBar({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final rawUsername = ApiService.instance.username ?? '-';
    final isSpecial = rawUsername.toLowerCase() == 'wanzzgantengbanget';
    final displayName = isSpecial ? 'wanzz' : rawUsername;
    final role = ApiService.instance.role ?? 'member';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$displayName', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.purpleLight)),
                if (isSpecial)
                  const Text('👑 dev', style: TextStyle(fontSize: 10.5, color: AppColors.amber, fontWeight: FontWeight.w600))
                else if (role != 'member')
                  Text(_roleLabel(role), style: const TextStyle(fontSize: 10.5, color: AppColors.amber, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLogout,
            child: Text('Ganti akun',
                style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.4), decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner': return '👑 owner';
      case 'dev': return '🧑‍💻 dev';
      case 'admin': return '🛡️ admin';
      case 'vvip': return '🌟 vvip';
      default: return role;
    }
  }
}

/// Banner promo channel WhatsApp — persis .wa-promo (hijau, ikon WA, panah).
class WaPromoBanner extends StatelessWidget {
  const WaPromoBanner({super.key});

  static const _url = 'https://whatsapp.com/channel/0029Vb7wbOF65yDB0M9V5d3l';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => launchUrl(Uri.parse(_url), mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📢 CHANNEL RESMI', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.green, letterSpacing: 0.4)),
                    SizedBox(height: 2),
                    Text('Ikuti untuk info & update request terbaru!', style: TextStyle(fontSize: 11.5, color: AppColors.textMain)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: AppColors.green.withOpacity(0.8), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol utama — samain PERSIS sama .btn-submit di website:
/// linear-gradient(135deg, #7c3aed, #a78bfa), radius 12px,
/// shadow 0 4px 20px rgba(124,58,237,.45), + shimmer sweep tiap 2.5s.
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const GradientButton({super.key, required this.onPressed, required this.child});

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purple, AppColors.purpleLight],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: disabled
              ? []
              : [BoxShadow(color: AppColors.purple.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Stack(children: [
          if (!disabled)
            AnimatedBuilder(
              animation: _shimmer,
              builder: (context, _) {
                return Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment(-3 + _shimmer.value * 6, 0),
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(0.14),
                          Colors.white.withOpacity(0),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Persis @keyframes cardIn: fade + translateY(30->0) + scale(.96->1),
/// durasi .7s cubic-bezier(.34,1.56,.64,1) (ada sedikit overshoot).
class CardInAnimation extends StatefulWidget {
  final Widget child;
  const CardInAnimation({super.key, required this.child});

  @override
  State<CardInAnimation> createState() => _CardInAnimationState();
}

class _CardInAnimationState extends State<CardInAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: const Cubic(0.34, 1.56, 0.64, 1));
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final v = curved.value.clamp(0.0, 1.2);
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 24),
            child: Transform.scale(scale: 0.96 + 0.04 * v, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(20), // antara .card(24) & elemen kecil lain, biar konsisten
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

/// Chip status buat history request (pending / diterima / ditolak)
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        AppTheme.statusLabel(status),
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Header umum tiap tab: judul + subtitle + tombol logout kecil di kanan atas
class TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onLogout;
  final VoidCallback? onBack;
  const TabHeader({super.key, required this.title, required this.subtitle, required this.onLogout, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.purpleLight, size: 22),
              padding: EdgeInsets.zero,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textMain)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.muted, size: 22),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}

/// Overlay maintenance/offline — persis #maintenanceOverlay/#offlineOverlay
/// di website. Muncul otomatis kalau appMode dari /ping bukan 'online'.
/// Tiket CS (FAB) TETAP bisa dipakai walau overlay ini nongol -- persis
/// behavior website ("Fitur ini tetap aktif walau maintenance/offline").
class AppStatusOverlay extends StatelessWidget {
  const AppStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.instance.pingStatus,
      builder: (context, status, _) {
        final mode = status?['appMode'] as String? ?? 'online';
        if (mode == 'online') return const SizedBox.shrink();

        final isMaintenance = mode == 'maintenance';
        final message = status?['appMessage'] as String? ??
            (isMaintenance ? 'Kami sedang melakukan pembaruan. Mohon tunggu sebentar.' : 'App sementara dimatikan oleh admin.');

        return Positioned.fill(
          child: Container(
            color: AppColors.bg.withOpacity(0.96),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: GlassCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isMaintenance ? '🛠️' : '🔴', style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 14),
                      Text(isMaintenance ? 'Sedang Maintenance' : 'App Sedang Offline',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textMain)),
                      const SizedBox(height: 8),
                      Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.55), height: 1.5)),
                      const SizedBox(height: 16),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: isMaintenance ? AppColors.amber : AppColors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('App tidak tersedia saat ini', style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.4))),
                      ]),
                      const SizedBox(height: 6),
                      Text('Tombol chat 💬 di kanan bawah tetap bisa dipakai.',
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chip status sesi lagu/banner — persis pesan gerbang sesi di website
/// ("Belum ada sesi kuota ... yang aktif"). Dipasang di header card
/// Request Lagu / Request Banner.
class SessionStatusChip extends StatelessWidget {
  final String type; // 'song' | 'banner'
  const SessionStatusChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.instance.pingStatus,
      builder: (context, status, _) {
        if (status == null) return const SizedBox.shrink();
        final open = (type == 'song' ? status['songOpen'] : status['bannerOpen']) as bool? ?? true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (open ? AppColors.green : AppColors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (open ? AppColors.green : AppColors.red).withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: open ? AppColors.green : AppColors.red, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text(
              open ? 'Sesi ${type == 'song' ? 'lagu' : 'banner'} sedang dibuka' : 'Sesi ${type == 'song' ? 'lagu' : 'banner'} sedang ditutup',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: open ? AppColors.green : AppColors.red),
            ),
          ]),
        );
      },
    );
  }
}

Future<void> showLogoutConfirm(BuildContext context, VoidCallback onConfirm) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0D1320),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.cardBorder)),
      title: const Text('Logout?'),
      content: const Text('Kamu perlu login lagi buat lanjut request.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        TextButton(
          onPressed: () { Navigator.pop(ctx); onConfirm(); },
          child: const Text('Logout', style: TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
}
