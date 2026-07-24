import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ApiService.instance.myRequests();
      items.sort((a, b) => (b['id'] ?? 0).toString().compareTo((a['id'] ?? 0).toString()));
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _rate(String id, int rating) async {
    try {
      final d = await ApiService.instance.rate(id, rating);
      if (d['success'] == true) _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purpleLight));
    }
    if (_error != null) {
      return _emptyState(Icons.wifi_off_rounded, 'Gagal memuat', _error!, retry: true);
    }
    if (_items.isEmpty) {
      return _emptyState(Icons.inbox_outlined, 'Belum ada request', 'Request lagu/banner kamu bakal muncul di sini.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.purpleLight,
      backgroundColor: const Color(0xFF0D1320),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _requestCard(_items[i]),
      ),
    );
  }

  Widget _requestCard(Map item) {
    final isSong  = item['type'] == 'song';
    final title   = isSong ? (item['title'] ?? item['link'] ?? '(tanpa judul)') : (item['quote'] ?? '(banner gambar)');
    final status  = (item['status'] ?? 'pending').toString();
    final rating  = item['rating'];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(isSong ? Icons.music_note_rounded : Icons.image_outlined, size: 18, color: AppColors.purpleLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title.toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain)),
              ),
              StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 13, color: Colors.white.withOpacity(0.35)),
              const SizedBox(width: 4),
              Text('#${item['id']}', style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.4))),
              const SizedBox(width: 14),
              Icon(Icons.schedule_rounded, size: 13, color: Colors.white.withOpacity(0.35)),
              const SizedBox(width: 4),
              Expanded(
                child: Text('${item['time'] ?? '-'}', style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.4)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (status == 'approved') ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 10),
            if (rating != null)
              Row(children: [
                ...List.generate(5, (i) => Icon(
                    i < (rating as int) ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 18, color: AppColors.amber)),
                const SizedBox(width: 8),
                const Text('Terima kasih ratingnya!', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ])
            else
              Row(children: [
                const Text('Kasih rating: ', style: TextStyle(fontSize: 12, color: AppColors.textMain)),
                ...List.generate(5, (i) => GestureDetector(
                      onTap: () => _rate(item['id'].toString(), i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(Icons.star_border_rounded, size: 20, color: AppColors.amber.withOpacity(0.8)),
                      ),
                    )),
              ]),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.white.withOpacity(0.25)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.45))),
            if (retry) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ],
        ),
      ),
    );
  }
}
