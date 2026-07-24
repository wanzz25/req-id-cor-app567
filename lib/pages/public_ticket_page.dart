import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Persis widget .tk-fab/.tk-overlay di login.html: chat CS yang bisa
/// dipakai SEBELUM login sama sekali (gak butuh username/session dulu).
class PublicTicketPage extends StatefulWidget {
  const PublicTicketPage({super.key});

  @override
  State<PublicTicketPage> createState() => _PublicTicketPageState();
}

class _PublicTicketPageState extends State<PublicTicketPage> {
  bool _loading = true;
  bool _sending = false;
  String? _ticketId;
  Map<String, dynamic>? _ticket;

  final _nameCtrl = TextEditingController();
  final _firstMsgCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final id = await ApiService.instance.getPreLoginTicketId();
    if (id == null) {
      setState(() { _loading = false; _ticketId = null; _ticket = null; });
      return;
    }
    await _loadTicket(id);
  }

  Future<void> _loadTicket(String id) async {
    try {
      final d = await ApiService.instance.publicTicketGet(id);
      if (!mounted) return;
      if (d['success'] == true && d['ticket'] != null) {
        setState(() { _ticketId = id; _ticket = Map<String, dynamic>.from(d['ticket']); _loading = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        await ApiService.instance.setPreLoginTicketId(null);
        setState(() { _ticketId = null; _ticket = null; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('$e', isError: true);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _createTicket() async {
    final name = _nameCtrl.text.trim();
    final message = _firstMsgCtrl.text.trim();
    if (name.isEmpty) { _toast('Nama wajib diisi.', isError: true); return; }
    if (message.isEmpty) { _toast('Tulis pesan dulu ya.', isError: true); return; }
    setState(() => _sending = true);
    try {
      final d = await ApiService.instance.publicTicketCreate(name: name, message: message);
      if (d['success'] == true) {
        await ApiService.instance.setPreLoginTicketId(d['id'].toString());
        _firstMsgCtrl.clear();
        await _loadTicket(d['id'].toString());
      } else {
        _toast(d['message'] ?? 'Gagal membuat tiket.', isError: true);
      }
    } catch (e) {
      _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _ticketId == null) return;
    setState(() => _sending = true);
    try {
      final d = await ApiService.instance.publicTicketMessage(_ticketId!, text);
      if (d['success'] == true) {
        _msgCtrl.clear();
        await _loadTicket(_ticketId!);
      } else {
        _toast(d['message'] ?? 'Gagal kirim pesan.', isError: true);
      }
    } catch (e) {
      _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Chat CS / Admin'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.purpleLight))
                  : _buildBody(),
            ),
            if (_ticket == null || _ticket!['status'] != 'closed') _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_ticket == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Selalu bisa dihubungi, kapan saja — walau kamu belum login.',
                style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 18),
            const Text('Nama kamu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 7),
            TextField(controller: _nameCtrl, style: const TextStyle(color: AppColors.textMain), decoration: const InputDecoration(hintText: 'Nama...')),
            const SizedBox(height: 14),
            const Text('Pesan / Pertanyaan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6)),
            const SizedBox(height: 7),
            TextField(controller: _firstMsgCtrl, maxLines: 4, style: const TextStyle(color: AppColors.textMain),
                decoration: const InputDecoration(hintText: 'Tulis pertanyaan atau kendala kamu di sini...')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _createTicket,
                child: _sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('🎫 Buat Tiket & Kirim'),
              ),
            ),
            const SizedBox(height: 12),
            Text('Tiket kamu akan langsung diteruskan ke admin via Telegram.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35))),
          ],
        ),
      );
    }

    final messages = (_ticket!['messages'] as List?) ?? [];
    if (messages.isEmpty) {
      return Center(child: Text('Belum ada pesan.', style: TextStyle(color: Colors.white.withOpacity(0.4))));
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i] as Map;
        final fromUser = m['from'] != 'admin';
        return Align(
          alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: fromUser ? AppColors.purple.withOpacity(0.22) : const Color(0xFF0D1320),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: fromUser ? AppColors.purple.withOpacity(0.4) : AppColors.cardBorder),
            ),
            child: Text('${m['text'] ?? ''}', style: const TextStyle(fontSize: 13.5, color: AppColors.textMain)),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    if (_ticket == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 10, MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 16),
      decoration: const BoxDecoration(color: Color(0xFF0A0E1A), border: Border(top: BorderSide(color: AppColors.cardBorder))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            minLines: 1, maxLines: 4,
            style: const TextStyle(color: AppColors.textMain, fontSize: 13.5),
            decoration: const InputDecoration(hintText: 'Tulis pesan...'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _sending ? null : _send,
          icon: const Icon(Icons.send_rounded),
          color: AppColors.purple,
          style: IconButton.styleFrom(backgroundColor: AppColors.purple.withOpacity(0.15)),
        ),
      ]),
    );
  }
}
