import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ⚠️ GANTI ini sesuai domain/IP API kamu (api/config.js -> DOMAIN).
/// Contoh lokal testing (emulator Android) : http://10.0.2.2:2000
/// Contoh domain production               : https://api.pteronet.my.id
const String kApiBaseUrl = 'https://kicaw.adit.web.id/mobile-api';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Wrapper tipis di atas api/index.js — 1 fungsi = 1 endpoint API.
/// Session key disimpan di SharedPreferences, otomatis dipasang di header
/// x-session-key setiap request yang butuh login.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const _kSessionKey = 'session_key';
  static const _kUsername   = 'username';
  static const _kRole       = 'role';
  static const _kTicketId   = 'active_ticket_id';

  String? _sessionKey;
  String? _username;
  String? _role;

  String? get username => _username;
  String? get role => _role;
  bool get isLoggedIn => _sessionKey != null && _sessionKey!.isNotEmpty;

  // Status server (appMode/songOpen/bannerOpen) — dipoll berkala dari HomeShell,
  // dipakai bareng buat overlay maintenance/offline & indikator sesi lagu/banner.
  final ValueNotifier<Map<String, dynamic>?> pingStatus = ValueNotifier(null);

  Future<void> refreshPingStatus() async {
    try {
      final d = await ping();
      if (d['success'] == true) pingStatus.value = d;
    } catch (_) {/* biarin nilai lama kalau gagal, jangan bikin overlay muncul gara2 network blip */}
  }

  Future<void> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    _sessionKey = sp.getString(_kSessionKey);
    _username   = sp.getString(_kUsername);
    _role       = sp.getString(_kRole);
  }

  Future<void> _saveSession(String key, String user, String role) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSessionKey, key);
    await sp.setString(_kUsername, user);
    await sp.setString(_kRole, role);
    _sessionKey = key;
    _username   = user;
    _role       = role;
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    _sessionKey = null;
    _username   = null;
    _role       = null;
  }

  Future<String?> getActiveTicketId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kTicketId);
  }

  Future<void> setActiveTicketId(String? id) async {
    final sp = await SharedPreferences.getInstance();
    if (id == null) {
      await sp.remove(_kTicketId);
    } else {
      await sp.setString(_kTicketId, id);
    }
  }

  // ── Tiket sebelum login (dari layar Login, persis .tk-fab di login.html) ──
  static const _kPreLoginTicketId = 'pre_login_ticket_id';

  Future<String?> getPreLoginTicketId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kPreLoginTicketId);
  }

  Future<void> setPreLoginTicketId(String? id) async {
    final sp = await SharedPreferences.getInstance();
    if (id == null) {
      await sp.remove(_kPreLoginTicketId);
    } else {
      await sp.setString(_kPreLoginTicketId, id);
    }
  }

  Future<Map<String, dynamic>> publicTicketCreate({required String name, String? username, required String message}) async {
    final r = await http
        .post(_u('/public/ticket'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'username': username, 'message': message}))
        .timeout(const Duration(seconds: 15));
    return _decode(r);
  }

  Future<Map<String, dynamic>> publicTicketGet(String id) async {
    final r = await http.get(_u('/public/ticket/$id')).timeout(const Duration(seconds: 12));
    return _decode(r);
  }

  Future<Map<String, dynamic>> publicTicketMessage(String id, String message) async {
    final r = await http
        .post(_u('/public/ticket/$id/message'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}))
        .timeout(const Duration(seconds: 15));
    return _decode(r);
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_sessionKey != null) 'x-session-key': _sessionKey!,
      };

  Uri _u(String path) => Uri.parse('$kApiBaseUrl$path');

  Map<String, dynamic> _decode(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) return body;
      return {'success': false, 'message': 'Respon server tidak valid.'};
    } catch (_) {
      return {'success': false, 'message': 'Respon server tidak valid (bukan JSON).'};
    }
  }

  // ── LOGIN (cuma username, gak pakai password) ──────────────────────────────
  Future<Map<String, dynamic>> login(String username) async {
    try {
      final r = await http
          .post(_u('/validate'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'username': username}))
          .timeout(const Duration(seconds: 15));
      final d = _decode(r);
      if (d['valid'] == true && d['expired'] != true) {
        await _saveSession(d['sessionKey'], username, d['role'] ?? 'member');
      }
      return d;
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Cek koneksi internet kamu.');
    } catch (e) {
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // ── STATUS / PING ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> ping() async {
    final r = await http.get(_u('/ping'), headers: _authHeaders).timeout(const Duration(seconds: 12));
    return _decode(r);
  }

  // Pengumuman admin (publik, gak butuh login) — persis /api/announce di web.
  Future<String?> getAnnouncement() async {
    try {
      final r = await http.get(_u('/announce')).timeout(const Duration(seconds: 10));
      final d = _decode(r);
      if (d['success'] == true && d['announce'] != null) {
        return (d['announce']['message'] ?? '').toString();
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> limits() async {
    final r = await http.get(_u('/limits'), headers: _authHeaders).timeout(const Duration(seconds: 12));
    return _decode(r);
  }

  // ── HISTORY ──────────────────────────────────────────────────────────────
  Future<List<dynamic>> myRequests() async {
    final r = await http.get(_u('/myrequests'), headers: _authHeaders).timeout(const Duration(seconds: 12));
    final d = _decode(r);
    if (d['success'] != true) throw ApiException(d['message'] ?? 'Gagal ambil history.');
    return (d['requests'] as List?) ?? [];
  }

  // ── CARI LAGU DI YOUTUBE ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchYoutube(String query) async {
    final r = await http.get(_u('/yt/search?q=${Uri.encodeComponent(query)}'), headers: _authHeaders)
        .timeout(const Duration(seconds: 20));
    final d = _decode(r);

    // Nanzz ytmusic (baru): d['result'] berupa LIST hasil pencarian.
    if (d['result'] is List) {
      final list = d['result'] as List;
      return list.map((raw) {
        final it = Map<String, dynamic>.from(raw as Map);
        return {
          'title': it['title'] ?? it['name'] ?? it['judul'] ?? '',
          'url': it['url'] ?? it['link'] ?? it['downloadUrl'] ?? it['videoUrl'] ?? '',
          'channel': it['author'] ?? it['channel'] ?? it['artist'] ?? '🔍 Auto-Search',
          'duration': it['duration'] ?? it['length'] ?? '',
          'thumbnail': it['thumbnail'] ?? it['image'] ?? it['thumb'] ?? it['cover'] ?? '',
        };
      }).where((e) => (e['url'] as String).isNotEmpty).toList();
    }

    // Danzy (fallback lain): d['result'] berupa OBJECT tunggal { url, filename }.
    if (d['result'] != null && d['result']['url'] != null) {
      final raw = (d['result']['filename'] ?? d['original_query'] ?? query).toString();
      final title = raw.replaceAll(RegExp(r'\[.*?\]'), '').replaceAll(RegExp(r'\(.*?\)'), '').trim();
      return [
        {
          'title': title.isEmpty ? raw : title,
          'url': d['result']['url'],
          'channel': '🔍 Auto-Search',
          'duration': d['result']['duration'] ?? d['result']['length'] ?? '',
          'thumbnail': d['result']['thumbnail'] ?? d['result']['image'] ?? d['result']['thumb'] ?? '',
        }
      ];
    }
    final list = (d['results'] ?? d['data'] ?? d['items'] ?? d['videos'] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── REQUEST LAGU (link only — upload file audio belum didukung endpoint APK) ──
  Future<Map<String, dynamic>> requestSong({String? title, String? link, File? audioFile}) async {
    if (audioFile == null) {
      final r = await http
          .post(_u('/request'),
              headers: _authHeaders,
              body: jsonEncode({'song_title': title, 'song_link': link}))
          .timeout(const Duration(seconds: 25));
      return _decode(r);
    }
    // Ada file audio -> kirim multipart, persis jalur upload file di web.
    final req = http.MultipartRequest('POST', _u('/request'));
    req.headers.addAll({if (_sessionKey != null) 'x-session-key': _sessionKey!});
    if (title != null && title.isNotEmpty) req.fields['song_title'] = title;
    if (link != null && link.isNotEmpty) req.fields['song_link'] = link;
    req.files.add(await http.MultipartFile.fromPath('song_file', audioFile.path));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final r = await http.Response.fromStream(streamed);
    return _decode(r);
  }

  // ── REQUEST BANNER (upload gambar ATAU quote text) ─────────────────────────
  Future<Map<String, dynamic>> requestBanner({File? image, Uint8List? imageBytes}) async {
    final uri = _u('/banner');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll({if (_sessionKey != null) 'x-session-key': _sessionKey!});
    if (imageBytes != null) {
      req.files.add(http.MultipartFile.fromBytes('banner_image', imageBytes, filename: 'quote-banner.png'));
    } else if (image != null) {
      req.files.add(await http.MultipartFile.fromPath('banner_image', image.path));
    }
    final streamed = await req.send().timeout(const Duration(seconds: 40));
    final r = await http.Response.fromStream(streamed);
    return _decode(r);
  }

  // ── TIKET CS ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> ticketGet(String id) async {
    final r = await http.get(_u('/ticket/$id'), headers: _authHeaders).timeout(const Duration(seconds: 12));
    return _decode(r);
  }

  Future<Map<String, dynamic>> ticketCreate(String message) async {
    final r = await http
        .post(_u('/ticket'), headers: _authHeaders, body: jsonEncode({'message': message}))
        .timeout(const Duration(seconds: 15));
    return _decode(r);
  }

  Future<Map<String, dynamic>> ticketReply(String id, String message) async {
    final r = await http
        .post(_u('/ticket/$id/message'), headers: _authHeaders, body: jsonEncode({'message': message}))
        .timeout(const Duration(seconds: 15));
    return _decode(r);
  }

  Future<Map<String, dynamic>> ticketClose(String id) async {
    final r = await http.post(_u('/ticket/$id/close'), headers: _authHeaders).timeout(const Duration(seconds: 12));
    return _decode(r);
  }

  // ── TRACK / RATING ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> track(String id) async {
    final r = await http.get(_u('/track/$id'), headers: _authHeaders).timeout(const Duration(seconds: 12));
    return _decode(r);
  }

  Future<Map<String, dynamic>> rate(String id, int rating) async {
    final r = await http
        .post(_u('/req/$id/rating'), headers: _authHeaders, body: jsonEncode({'rating': rating}))
        .timeout(const Duration(seconds: 12));
    return _decode(r);
  }
}
