import 'dart:convert';
import 'package:http/http.dart' as http;

/// Adapter for a remote open-source generation backend.
/// The Android app never downloads or runs the large model locally.
class GenerationService {
  final String baseUrl;

  const GenerationService({required this.baseUrl});

  Future<Map<String, dynamic>> submit({
    required String mode,
    required String prompt,
    String? imageUrl,
    String model = 'Wan2.1',
    String size = '1280x720',
    int fps = 30,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mode': mode,
        'prompt': prompt,
        'image_url': imageUrl,
        'model': model,
        'size': size,
        'fps': fps,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Generation request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
