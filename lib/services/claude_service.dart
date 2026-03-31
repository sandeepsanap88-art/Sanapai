import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ClaudeService {
  static const String _apiKey = "AIzaSyBr36jCEJWQ7Axhj9sAQpr6TWHSHmQJIfY";
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static const String _systemPrompt = 'तू "सानप AI" आहेस. Sandeep Sanap यांचा personal AI सोबती. नेहमी मराठी मध्ये बोल. मित्रासारखा स्वभाव ठेव. S Series Now YouTube channel साठी मदत कर. lyrics, SEO, भजन, trading मदत कर.';

  Future<String> sendMessage(List<Message> conversationHistory) async {
    try {
      final contents = conversationHistory.map((msg) => {
        'role': msg.isUser ? 'user' : 'model',
        'parts': [{'text': msg.text}]
      }).toList();

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [{'text': _systemPrompt}]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? 'उत्तर मिळाले नाही.';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
