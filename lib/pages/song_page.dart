import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SongPage extends StatefulWidget {
  const SongPage({super.key});

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  final _searchCtrl = TextEditingController();
  final _titleCtrl  = TextEditingController();
  final _linkCtrl   = TextEditingController();
  bool _loading = false;
  bool _searching = false;
  Map<String, dynamic>? _limitInfo;
  List<Map<String, dynamic>> _results = [];
  File? _audioFile;
  String? _audioFileName;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadLimit();
  }

  Future<void> _loadLimit() async {
    try {
      final d = await ApiService.instance.limits();
      if (mounted && d['success'] != false) setState(() => _limitInfo = d);
    } catch (_) {/* diem-diem aja kalau gagal, gak fatal */}
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _searching = true; _searched = true; _results = []; });
    try {
      final res = await ApiService.instance.searchYoutube(q);
      if (!mounted) return;
      setState(() => _results = res.take(7).toList());
    } catch (e) {
      if (mounted) _toast('Gagal mencari: $e', isError: true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pickResult(Map<String, dynamic> item) {
    setState(() {
      _titleCtrl.text = (item['title'] ?? '').toString();
      _linkCtrl.text = (item['url'] ?? '').toString();
      _results = [];
      _searchCtrl.clear();
    });
    _toast('Lagu dipilih, cek judul & link di bawah lalu Kirim Request.');
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final sizeBytes = result.files.single.size;
    if (sizeBytes > 20 * 1024 * 1024) {
      _toast('Ukuran file melebihi 20 MB.', isError: true);
      return;
    }
    setState(() {
      _audioFile = File(path);
      _audioFileName = result.files.single.name;
      _linkCtrl.clear(); // file & link saling gantiin, bukan digabung
    });
  }

  Future<void> _submit() async {
    if (_audioFile == null && _linkCtrl.text.trim().isEmpty && _titleCtrl.text.trim().isEmpty) {
      _toast('Upload file lagu, isi judul, atau link-nya ya.', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final d = await ApiService.instance.requestSong(
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        link : _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
        audioFile: _audioFile,
      );
      if (!mounted) return;
      if (d['success'] == true) {
        _toast(d['message'] ?? 'Request berhasil dikirim!');
        _titleCtrl.clear();
        _linkCtrl.clear();
        setState(() { _audioFile = null; _audioFileName = null; });
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
    final song = _limitInfo?['song'];
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
                            const Icon(Icons.music_note_rounded, color: AppColors.purpleLight, size: 18),
                            const SizedBox(width: 8),
                            const Text('Request Lagu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.textMain)),
                            const Spacer(),
                            if (song != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${song['remaining'] ?? '-'}/${song['limit'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.amber)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SessionStatusChip(type: 'song'),
                        const SizedBox(height: 8),

                        // ── CARI LAGU DI YOUTUBE ── (persis .yt-search-wrap website)
                        Row(children: const [
                          Icon(Icons.smart_display_rounded, size: 15, color: AppColors.red),
                          SizedBox(width: 6),
                          Text('CARI LAGU DI YOUTUBE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red, letterSpacing: 0.6)),
                        ]),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(color: AppColors.textMain, fontSize: 13.5),
                                onSubmitted: (_) => _search(),
                                decoration: const InputDecoration(hintText: 'Nama lagu / artis...'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: _searching ? null : _search,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: _searching
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.search_rounded, size: 17, color: Colors.white),
                                label: const Text('Cari', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                        if (_results.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ..._results.map((item) => _YtResultTile(item: item, onTap: () => _pickResult(item))),
                        ] else if (_searched && !_searching) ...[
                          const SizedBox(height: 10),
                          Text('Tidak ada hasil ditemukan.', style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.4))),
                        ],

                        const SizedBox(height: 16),
                        _dividerLabel('ATAU ISI MANUAL'),
                        const SizedBox(height: 14),

                        const Text('Judul Lagu', style: TextStyle(fontSize: 12.5, color: AppColors.purpleLight, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleCtrl,
                          style: const TextStyle(color: AppColors.textMain),
                          decoration: const InputDecoration(hintText: 'Nama lagu yang direquest...'),
                        ),
                        const SizedBox(height: 14),

                        Row(children: [
                          const Text('File Lagu', style: TextStyle(fontSize: 12.5, color: AppColors.purpleLight, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('OPSIONAL', style: TextStyle(fontSize: 9.5, color: Colors.white.withOpacity(0.3), letterSpacing: 0.5)),
                        ]),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickAudioFile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _audioFile != null ? AppColors.green.withOpacity(0.4) : Colors.white.withOpacity(0.1)),
                            ),
                            child: _audioFile == null
                                ? Column(children: [
                                    Icon(Icons.upload_rounded, color: AppColors.purpleLight.withOpacity(0.8), size: 22),
                                    const SizedBox(height: 6),
                                    Text.rich(TextSpan(children: [
                                      const TextSpan(text: 'Klik untuk unggah ', style: TextStyle(color: AppColors.purpleLight, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                      TextSpan(text: 'atau pilih file dari HP', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5)),
                                    ])),
                                    const SizedBox(height: 4),
                                    Text('MP3, WAV, OGG, FLAC, M4A, AAC — maks. 20 MB',
                                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3))),
                                  ])
                                : Row(children: [
                                    const Icon(Icons.audiotrack_rounded, color: AppColors.green, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(_audioFileName ?? 'File terpilih', maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppColors.textMain, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() { _audioFile = null; _audioFileName = null; }),
                                      child: const Icon(Icons.close_rounded, color: AppColors.muted, size: 18),
                                    ),
                                  ]),
                          ),
                        ),

                        const SizedBox(height: 16),
                        _dividerLabel('ATAU'),
                        const SizedBox(height: 14),

                        const Text('Link Lagu', style: TextStyle(fontSize: 12.5, color: AppColors.purpleLight, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _linkCtrl,
                          enabled: _audioFile == null,
                          style: const TextStyle(color: AppColors.textMain),
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(hintText: 'https://youtube.com/watch?v=...'),
                        ),
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
                            Text('Kirim Request'),
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

  Widget _dividerLabel(String label) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35), letterSpacing: 0.5)),
      ),
      Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
    ]);
  }
}

class _YtResultTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _YtResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumb = (item['thumbnail'] ?? '').toString();
    final title = (item['title'] ?? '-').toString();
    final channel = (item['channel'] ?? '').toString();
    final duration = (item['duration'] ?? '').toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: thumb.isNotEmpty
                  ? Image.network(thumb, width: 56, height: 40, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 56, height: 40, color: Colors.white.withOpacity(0.05)))
                  : Container(width: 56, height: 40, color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.music_note_rounded, size: 18, color: AppColors.muted)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                  const SizedBox(height: 2),
                  Row(children: [
                    if (channel.isNotEmpty)
                      Flexible(child: Text(channel, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.4)))),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(duration, style: const TextStyle(fontSize: 10.5, color: AppColors.cyan)),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
