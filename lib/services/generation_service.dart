import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class GenerationService {
  const GenerationService({this.timeout = const Duration(minutes: 8)});

  final Duration timeout;

  static const _t2i = 'https://mrfakename-z-image-turbo.hf.space';
  static const _t2v = 'https://multimodalart-wan2-1-fast.hf.space';
  static const _i2v = 'https://multimodalart-wan2-1-fast-2.hf.space';

  Future<String> generate({
    required String mode,
    required String prompt,
    Uint8List? imageBytes,
    String imageName = 'source.png',
  }) async {
    switch (mode) {
      case 'text_to_image':
        return _call(_t2i, 'generate_image', [prompt, 1024, 1024, 9, 42, true]);
      case 'text_to_video':
        return _call(_t2v, 'generate_video', [prompt, '', 480, 832, 25, 5.0, 4, 30]);
      case 'image_to_video':
        if (imageBytes == null || imageBytes.isEmpty) {
          throw Exception('اختر صورة المصدر أولًا.');
        }
        final uploadedPath = await _uploadImage(imageBytes, imageName);
        return _call(_i2v, 'generate_video', [
          {'path': uploadedPath, 'meta': {'_type': 'gradio.FileData'}},
          prompt,
          480,
          832,
          '',
          2,
          1.0,
          4,
          42,
          true,
        ]);
      default:
        throw Exception('وضع التوليد غير مدعوم.');
    }
  }

  Future<String> _uploadImage(Uint8List bytes, String filename) async {
    final client = await _clientFor(_i2v);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_i2v/gradio_api/upload'),
      );
      request.files.add(http.MultipartFile.fromBytes('files', bytes, filename: filename));

      final response = await client.send(request).timeout(timeout);
      final body = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('تعذر رفع الصورة (${response.statusCode}).');
      }

      final decoded = jsonDecode(body);
      if (decoded is List && decoded.isNotEmpty && decoded.first is String) {
        return decoded.first as String;
      }
      throw Exception('لم يصل مسار الصورة المرفوعة.');
    } finally {
      client.close();
    }
  }

  Future<http.Client> _clientFor(String base) async {
    final uri = Uri.parse(base);
    if (!uri.host.endsWith('.hf.space')) return http.Client();

    final ips = await _resolveWithDoh(uri.host);
    if (ips.isEmpty) {
      throw Exception('تعذر الوصول إلى خوادم Hugging Face من الشبكة الحالية.');
    }

    final httpClient = HttpClient();
    httpClient.findProxy = (_) => 'DIRECT';
    httpClient.connectionTimeout = const Duration(seconds: 15);
    httpClient.connectionFactory = (requestUri, proxyHost, proxyPort) {
      final ip = ips.first;
      return Socket.startConnect(InternetAddress(ip), requestUri.port);
    };
    return IOClient(httpClient);
  }

  Future<List<String>> _resolveWithDoh(String host) async {
    final endpoints = <Uri>[
      Uri.https('dns.google', '/resolve', {'name': host, 'type': 'A'}),
      Uri.https('cloudflare-dns.com', '/dns-query', {'name': host, 'type': 'A'}),
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http.get(endpoint, headers: {'accept': 'application/dns-json'}).timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final answers = json['Answer'];
        if (answers is List) {
          final ips = answers
              .whereType<Map<String, dynamic>>()
              .where((a) => a['type'] == 1 && a['data'] is String)
              .map((a) => a['data'] as String)
              .toList();
          if (ips.isNotEmpty) return ips;
        }
      } catch (_) {}
    }
    return const [];
  }

  Future<String> _call(String base, String endpoint, List<dynamic> data) async {
    final client = await _clientFor(base);
    try {
      final start = await client.post(
        Uri.parse('$base/gradio_api/call/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': data}),
      ).timeout(timeout);

      if (start.statusCode < 200 || start.statusCode >= 300) {
        throw Exception('تعذر بدء التوليد (${start.statusCode}).');
      }

      final eventId = (jsonDecode(start.body) as Map<String, dynamic>)['event_id']?.toString();
      if (eventId == null || eventId.isEmpty) throw Exception('لم يصل معرّف مهمة التوليد.');

      final result = await client.get(
        Uri.parse('$base/gradio_api/call/$endpoint/$eventId'),
        headers: {'Accept': 'text/event-stream'},
      ).timeout(timeout);

      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw Exception('تعذر استلام نتيجة التوليد (${result.statusCode}).');
      }

      final lines = result.body.split('\n');
      String? lastData;
      String? error;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('event:') && lines[i].contains('error') && i + 1 < lines.length) {
          error = lines[i + 1].replaceFirst('data:', '').trim();
        }
        if (lines[i].startsWith('event:') && lines[i].contains('complete') && i + 1 < lines.length) {
          lastData = lines[i + 1].replaceFirst('data:', '').trim();
        }
      }

      if (error != null && error.isNotEmpty) throw Exception('خطأ من محرك الذكاء الاصطناعي: $error');
      if (lastData == null || lastData.isEmpty) throw Exception('لم تصل نتيجة من محرك الذكاء الاصطناعي.');

      final url = _findUrl(jsonDecode(lastData));
      if (url == null) throw Exception('وصلت النتيجة لكن لم أجد رابط الملف.');
      return url;
    } finally {
      client.close();
    }
  }

  String? _findUrl(dynamic value) {
    if (value is String) {
      if (value.startsWith('http://') || value.startsWith('https://')) return value;
      return null;
    }
    if (value is List) {
      for (final item in value) {
        final found = _findUrl(item);
        if (found != null) return found;
      }
    }
    if (value is Map) {
      for (final key in ['url', 'path']) {
        final found = _findUrl(value[key]);
        if (found != null) return found;
      }
      for (final item in value.values) {
        final found = _findUrl(item);
        if (found != null) return found;
      }
    }
    return null;
  }
}
