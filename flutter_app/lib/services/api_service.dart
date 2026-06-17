import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl =
      'https://ai-assistant-backend-073m.onrender.com/chat';

  static const String memoryUrl =
      'https://ai-assistant-backend-073m.onrender.com/memory';

  static String cleanResponse(String text) {
    return text
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll('*', '')
        .replaceAll('`', '')
        .replaceAll('_', '')
        .replaceAll('>', '')
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1')
        .replaceAll(RegExp(r'\n+'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String reply = data['reply'] ?? 'No reply from AI';

        return cleanResponse(reply);
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<String?> sendMemoryCommand(String message) async {
    try {
      final response = await http.post(
        Uri.parse(memoryUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['reply'] != null) {
          return cleanResponse(data['reply'].toString());
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}