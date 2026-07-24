import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  bool _loading = true;
  bool _sending = false;
  String? _ticketId;
  Map<String, dynamic>? _ticket;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final id = await ApiService.instance.getActiveTicketId();
    if (id == null) {
      setState(() { _loading = false; _ticketId = null; _ticket = null; });
      return;
    }
    await _loadTicket(id);
  }

  Future<void> _loadTicket(String id) async {
    try {
      final d = await ApiService.instance.ticketGet(id);
      if (!mounted) return;
      if (d['success'] == true && d['ticket'] != null) {
        setState(() { _ticketId = id; _ticket = Map<String, dynamic>.from(d['ticket']); _loading = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        // Tiket gak ketemu (mungkin udah lama/dihapus) -> reset, biar user bisa buka baru
        await ApiService.instance.setActiveTicketId(null);
        setState(() { _ticketId = null; _ticket = null; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      _toast('$e', isError: true);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      if (_ticketId == null) {
        final d = await ApiService.instance.ticketCreate(text);
        if (d['success'] == true) {
          await ApiService.instance.setActiveTicketId(d['id'].toString());
          _msgCtrl.clear();
          await _loadTicket(d['id'].toString());
        } else {
          _toast(d['message'] ?? 'Gagal buat tiket.', isError: true);
        }
      } else {
        final d = await ApiService.instance.ticketReply(_ticketId!, text);
        if (d['success'] == true) {
          _msgCtrl.clear();
          await _loadTicket(_ticketId!);
        } else {
          _toast(d['message'] ?? 'Gagal kirim pesan.', isError: true);
        }
      }
    } catch (e) {
      _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _closeTicket() async {
    if (_ticketId == null) return;
    try {
      final d = await ApiService.instance.ticketClose(_ticketId!);
      if (d['success'] == true) {
        await ApiService.instance.setActiveTicketId(null);
        setState(() { _ticketId = null; _ticket = null; });
        _toast('Tiket ditutup.');
      } else {
        _toast(d['message'] ?? 'Gagal menutup tiket.', isError: true);
      }
    } catch (e) {
      _toast('$e', isError: true);
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
    final isClosed = _ticket?['status'] == 'closed';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬 Tiket CS'),
            if (_ticket != null)
              Text(
                'Tiket #$_ticketId • ${isClosed ? 'Ditutup' : 'Terbuka'}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white.withOpacity(0.45)),
              ),
          ],
        ),
        actions: [
          if (_ticket != null) ...[
            IconButton(
              onPressed: () => _loadTicket(_ticketId!),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
            if (!isClosed)
              IconButton(
                onPressed: _closeTicket,
                icon: const Icon(Icons.close_rounded, color: AppColors.red),
                tooltip: 'Tutup Tiket',
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.purpleLight))
                : _buildBody(),
          ),
          if (_ticket == null || !isClosed) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_ticket == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.support_agent_rounded, size: 44, color: Colors.white.withOpacity(0.25)),
              const SizedBox(height: 14),
              const Text('Belum ada tiket', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain)),
              const SizedBox(height: 6),
              Text('Ada kendala atau pertanyaan? Tulis pesan di bawah buat mulai chat sama admin.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.45))),
            ],
          ),
        ),
      );
    }

    final messages = (_ticket!['messages'] as List?) ?? [];
    if (messages.isEmpty) {
      return Center(child: Text('Belum ada pesan.', style: TextStyle(color: Colors.white.withOpacity(0.4))));
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i] as Map;
        final fromUser = m['from'] == 'user';
        return Align(
          alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: fromUser ? AppColors.purple.withOpacity(0.22) : const Color(0xFF0D1320),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(fromUser ? 14 : 2),
                bottomRight: Radius.circular(fromUser ? 2 : 14),
              ),
              border: Border.all(color: fromUser ? AppColors.purple.withOpacity(0.4) : AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!fromUser)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text('Admin', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.cyan)),
                  ),
                Text('${m['text'] ?? ''}', style: const TextStyle(fontSize: 13.5, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text('${m['time'] ?? ''}', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 10, MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E1A),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textMain, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: _ticketId == null ? 'Tulis pesan buat buka tiket baru...' : 'Ketik balasan...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _sending
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleLight)),
                )
              : IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.purple,
                  style: IconButton.styleFrom(backgroundColor: AppColors.purple.withOpacity(0.15)),
                ),
        ],
      ),
    );
  }
}
