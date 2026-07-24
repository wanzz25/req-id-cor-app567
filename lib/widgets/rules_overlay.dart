import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Konten & urutan ini disalin PERSIS dari #rulesOverlay di public/index.html.
/// Jangan diubah urutan/teksnya kecuali website-nya juga diubah.
class _RuleItem {
  final String icon;
  final Color color;
  final String title;
  final String desc;
  const _RuleItem(this.icon, this.color, this.title, this.desc);
}

const _rules = [
  _RuleItem('❌', AppColors.red, 'Lagu Berlisensi / Copyright',
      'Lagu yang memiliki hak cipta akan otomatis ditolak oleh Roblox. Cth: lagu dari artis besar, label besar (Universal, Sony, Warner).'),
  _RuleItem('❌', AppColors.red, 'Durasi Melebihi 7 Menit',
      'Roblox tidak menerima audio lebih dari 7 menit. Request akan langsung ditolak.'),
  _RuleItem('❌', AppColors.red, 'Ukuran File Terlalu Besar',
      'Maksimal ukuran file yang diterima adalah 20 MB. Lebih dari itu tidak bisa diupload.'),
  _RuleItem('⚠️', AppColors.amber, 'Format File yang Didukung',
      'Hanya format MP3, WAV, OGG, FLAC, M4A, AAC yang bisa diterima Roblox.'),
  _RuleItem('⚠️', AppColors.amber, 'Satu Request per Lagu',
      'Jangan kirim request yang sama berulang kali. Duplikat akan langsung ditolak.'),
  _RuleItem('ℹ️', AppColors.cyan, 'Lagu Bebas Copyright',
      'Pilih lagu dari platform free-use seperti NCS, Epidemic Sound (free tier), atau lagu buatan sendiri agar pasti diterima.'),
  _RuleItem('✅', AppColors.green, 'Cek Status Request',
      'Pantau status request kamu di tab Request Saya. Admin akan ACC atau tolak secepatnya.'),
];

const _kRulesAgreedKey = 'rules_agreed_v1';

Future<bool> hasAgreedToRules() async {
  final sp = await SharedPreferences.getInstance();
  return sp.getBool(_kRulesAgreedKey) ?? false;
}

Future<void> _setAgreed() async {
  final sp = await SharedPreferences.getInstance();
  await sp.setBool(_kRulesAgreedKey, true);
}

/// Tampilkan sekali di awal (kayak localStorage flag di website).
/// Blocking -- gak bisa di-dismiss selain tekan tombol setuju.
Future<void> showRulesOverlayIfNeeded(BuildContext context) async {
  if (await hasAgreedToRules()) return;
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _RulesDialog(),
  );
}

class _RulesDialog extends StatelessWidget {
  const _RulesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 640),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('📋', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panduan & Peraturan Request', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textMain)),
                      SizedBox(height: 2),
                      Text('Baca sebelum mengajukan request!', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _rules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = _rules[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: r.color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: r.color.withOpacity(0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26, height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: r.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text(r.icon, style: const TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textMain)),
                              const SizedBox(height: 3),
                              Text(r.desc, style: TextStyle(fontSize: 11.5, height: 1.4, color: Colors.white.withOpacity(0.6))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Dengan menekan Saya Mengerti, kamu menyetujui panduan di atas dan siap mengajukan request sesuai aturan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.4)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _setAgreed();
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white),
                child: const Text('✅ Saya Mengerti, Lanjutkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
