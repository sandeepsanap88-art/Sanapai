import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ClaudeService {
  static const String _apiKey = 'YOUR_CLAUDE_API_KEY_HERE';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';

  static const String _systemPrompt = '''
तू "सानप AI" आहेस — Sandeep Sanap यांचा personal AI सोबती.
नेहमी मराठी मध्ये बोल. मित्रासारखा स्वभाव ठेव.
Sandeep चा YouTube channel "S Series Now" आहे.
S Series साठी lyrics, YouTube SEO, भजन, trading मदत कर.
Sandeep ला "दादा" म्हण.
''';

  Future<String> sendMessage(List<Message> conversationHistory) async {
    try {
      final messages = conversationHistory.map((msg) => msg.toJson()).toList();
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': _systemPrompt,
          'messages': messages,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] ?? 'उत्तर मिळाले नाही.';
      } else {
        return 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
