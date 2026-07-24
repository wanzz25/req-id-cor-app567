import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Replikasi .bg (.bg-grid + .orb + .pt) di website secara lengkap:
/// grid garis bergerak diagonal, 3 orb blur mengambang, 16 partikel naik.
/// Taruh sebagai layer paling belakang (Stack) di Scaffold body.
class AnimatedBgOrbs extends StatefulWidget {
  const AnimatedBgOrbs({super.key});

  @override
  State<AnimatedBgOrbs> createState() => _AnimatedBgOrbsState();
}

class _AnimatedBgOrbsState extends State<AnimatedBgOrbs> with TickerProviderStateMixin {
  late final AnimationController _orbC;
  late final AnimationController _gridC;
  late final List<_ParticleSpec> _particles;

  @override
  void initState() {
    super.initState();
    _orbC = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _gridC = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    final rnd = math.Random(7);
    _particles = List.generate(16, (_) => _ParticleSpec(
      leftPct: rnd.nextDouble(),
      durationS: 8 + rnd.nextDouble() * 12,
      delayS: rnd.nextDouble() * 15,
      controller: AnimationController(vsync: this, duration: Duration(milliseconds: ((8 + rnd.nextDouble() * 12) * 1000).toInt()))..repeat(),
    ));
  }

  @override
  void dispose() {
    _orbC.dispose();
    _gridC.dispose();
    for (final p in _particles) { p.controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: ClipRect(
        child: Stack(children: [
          // Grid garis bergerak (gridMove)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridC,
              builder: (_, __) => CustomPaint(painter: _GridPainter(progress: _gridC.value)),
            ),
          ),
          // Orb blur mengambang (orbFloat)
          AnimatedBuilder(
            animation: _orbC,
            builder: (_, __) {
              double floatY(double delay) {
                final t = ((_orbC.value * 10 + delay) % 10) / 10;
                return math.sin(t * 2 * math.pi) * 20;
              }
              return Stack(children: [
                Positioned(top: -200 + floatY(0), left: -200, child: _orb(600, AppColors.purple.withOpacity(0.15))),
                Positioned(bottom: -150 + floatY(-4), right: -150, child: _orb(500, AppColors.cyan.withOpacity(0.11))),
                Positioned(top: size.height * 0.4 + floatY(-7), left: size.width * 0.5 - 140, child: _orb(280, AppColors.green.withOpacity(0.09))),
              ]);
            },
          ),
          // Partikel naik (ptFloat) -- 16 titik ungu kecil
          ..._particles.map((p) => AnimatedBuilder(
                animation: p.controller,
                builder: (_, __) {
                  final t = p.controller.value; // 0..1 satu siklus
                  final y = size.height * 1.0 - (size.height * 1.1) * t; // 100vh -> -10vh
                  final x = p.leftPct * size.width + 60 * t; // drift +60px
                  double opacity;
                  if (t < 0.1) opacity = t / 0.1;
                  else if (t > 0.9) opacity = (1 - t) / 0.1;
                  else opacity = 1;
                  return Positioned(
                    left: x, top: y,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(width: 2, height: 2, decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.4), shape: BoxShape.circle)),
                    ),
                  );
                },
              )),
        ]),
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

class _ParticleSpec {
  final double leftPct;
  final double durationS;
  final double delayS;
  final AnimationController controller;
  _ParticleSpec({required this.leftPct, required this.durationS, required this.delayS, required this.controller});
}

/// Grid 50x50px, garis ungu tipis, geser diagonal looping mulus tiap 50px.
class _GridPainter extends CustomPainter {
  final double progress; // 0..1 -> geser 0..50px
  _GridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.purple.withOpacity(0.04)
      ..strokeWidth = 1;
    const cell = 50.0;
    final offset = progress * cell;
    for (double x = -cell + (offset % cell); x < size.width + cell; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -cell + (offset % cell); y < size.height + cell; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.progress != progress;
}
