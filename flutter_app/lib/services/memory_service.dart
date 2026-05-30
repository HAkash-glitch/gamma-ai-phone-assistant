import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  static const String _memoryKey = 'gamma_memory';

  static Future<Map<String, dynamic>> loadMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_memoryKey);

    if (saved == null || saved.isEmpty) {
      return {};
    }

    return jsonDecode(saved);
  }

  static Future<void> saveMemory(Map<String, dynamic> memory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_memoryKey, jsonEncode(memory));
  }

  static Future<String?> handleMemoryCommand(String text) async {
    final msg = text.toLowerCase().trim();
    final memory = await loadMemory();

    if (msg.startsWith("remember my name is ")) {
      final name = text.substring("remember my name is ".length).trim();
      memory["name"] = name;
      await saveMemory(memory);
      return "Got it. I will remember your name is $name.";
    }

    if (msg.contains("what is my name")) {
      final name = memory["name"];
      if (name != null) return "Your name is $name.";
      return "I don't know your name yet.";
    }

    if (msg.startsWith("remember my favorite app is ")) {
      final app = text.substring("remember my favorite app is ".length).trim();
      memory["favorite_app"] = app;
      await saveMemory(memory);
      return "Got it. I will remember your favorite app is $app.";
    }

    if (msg.contains("what is my favorite app")) {
      final app = memory["favorite_app"];
      if (app != null) return "Your favorite app is $app.";
      return "I don't know your favorite app yet.";
    }

    if (msg.contains("forget my memory")) {
      await saveMemory({});
      return "I cleared your saved memory.";
    }

    return null;
  }
}