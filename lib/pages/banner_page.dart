import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/quote_banner_gen.dart';

class BannerPage extends StatefulWidget {
  const BannerPage({super.key});

  @override
  State<BannerPage> createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> {
  final _quoteCtrl = TextEditingController();
  final _linkCtrl  = TextEditingController();
  File? _image;
  Uint8List? _generatedPng;
  bool _generating = false;
  bool _loading = false;
  Map<String, dynamic>? _limitInfo;

  @override
  void initState() {
    super.initState();
    _loadLimit();
  }

  Future<void> _loadLimit() async {
    try {
      final d = await ApiService.instance.limits();
      if (mounted && d['success'] != false) setState(() => _limitInfo = d);
    } catch (_) {}
  }

  // Persis tombol "⚡ Generate Banner" di website: render quote jadi gambar
  // PNG (canvas 1280x720, teks auto-shrink, watermark "Wanz"), lalu itu yang
  // di-upload sebagai banner_image -- BUKAN kirim teks mentah ke server.
  Future<void> _generate() async {
    final text = _quoteCtrl.text.trim();
    if (text.isEmpty) {
      _toast('Tulis kata-kata dulu ya.', isError: true);
      return;
    }
    setState(() => _generating = true);
    try {
      final png = await generateQuoteBannerPng(text);
      setState(() {
        _generatedPng = png;
        _image = null; // generate & upload manual saling gantiin, bukan digabung
      });
      _toast('Banner berhasil dibuat! Tinggal Kirim Request Banner 🎉');
    } catch (e) {
      _toast('Gagal membuat banner: $e', isError: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _generatedPng = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_generatedPng == null && _image == null && _linkCtrl.text.trim().isEmpty) {
      _toast('Generate banner dari kata-kata, upload foto, atau isi link gambar.', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final d = await ApiService.instance.requestBanner(image: _image, imageBytes: _generatedPng);
      if (!mounted) return;
      if (d['success'] == true) {
        _toast(d['message'] ?? 'Request banner berhasil dikirim!');
        setState(() { _image = null; _generatedPng = null; _quoteCtrl.clear(); _linkCtrl.clear(); });
        _loadLimit();
      } else {
        _toast(d['message'] ?? 'Request gagal.', isError: true);
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

  @override
  Widget build(BuildContext context) {
    final banner = _limitInfo?['banner'];
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CardInAnimation(child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.image_outlined, color: AppColors.cyan, size: 18),
                            const SizedBox(width: 8),
                            const Text('Request Banner ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.textMain)),
                            const Spacer(),
                            if (banner != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                                child: Text('${banner['remaining'] ?? '-'}/${banner['limit'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.amber)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SessionStatusChip(type: 'banner'),
                        const SizedBox(height: 8),

                        // ── Generate dari kata-kata (persis .quote-gen-box website) ──
                        Row(children: const [
                          Text('✍️ Buat Banner dari Kata-kata', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                          SizedBox(width: 6),
                          Text('Otomatis', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                        ]),
                        const SizedBox(height: 9),
                        TextField(
                          controller: _quoteCtrl,
                          maxLines: 3,
                          maxLength: 220,
                          style: const TextStyle(color: AppColors.textMain, fontSize: 13.5),
                          decoration: const InputDecoration(hintText: 'Tulis kata-kata / quote kamu di sini...'),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _generating ? null : _generate,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.purple),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _generating
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleLight))
                                : const Text('⚡ Generate Banner', style: TextStyle(color: AppColors.purpleLight, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Watermark "Wanz" otomatis ditambahkan & tidak bisa diubah.',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.35))),
                        if (_generatedPng != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(_generatedPng!, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 6),
                          Text('Banner otomatis terisi di bawah — klik Kirim Request Banner untuk mengirim.',
                              style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.4))),
                        ],

                        const SizedBox(height: 18),
                        const Text('Upload Foto / Logo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                        const SizedBox(height: 9),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _image != null
                                ? Stack(fit: StackFit.expand, children: [
                                    Image.file(_image!, fit: BoxFit.cover),
                                    Positioned(
                                      top: 8, right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _image = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                  ])
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 30, color: Colors.white.withOpacity(0.35)),
                                      const SizedBox(height: 8),
                                      Text('Klik untuk upload foto atau logo', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('JPG, PNG, GIF, WEBP, SVG — maks. 10 MB • atau gunakan generator kata-kata di atas',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.35))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  GradientButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const Row(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 10),
                            Text('Mengirim...'),
                          ])
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.send_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Kirim Request Banner'),
                          ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
