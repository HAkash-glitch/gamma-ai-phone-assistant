import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  static const String _memoryKey = 'gamma_memory';

  static Future<Map<String, dynamic>> loadMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_memoryKey);

    if (saved == null || saved.isEmpty) return {};

    try {
      return Map<String, dynamic>.from(jsonDecode(saved));
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveMemory(Map<String, dynamic> memory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_memoryKey, jsonEncode(memory));
  }

  static Future<String?> handleMemoryCommand(String text) async {
    final original = text.trim();
    final msg = original.toLowerCase();

    final memory = await loadMemory();

    // ===== NAME MEMORY =====

    if (msg.startsWith("remember my name is")) {
      final name = original.substring("remember my name is".length).trim();

      if (name.isNotEmpty) {
        memory["name"] = name;
        await saveMemory(memory);

        return "Got it. I will remember your name is $name.";
      }
    }

    if (msg.startsWith("my name is")) {
      final name = original.substring("my name is".length).trim();

      if (name.isNotEmpty) {
        memory["name"] = name;
        await saveMemory(memory);

        return "Nice to meet you, $name. I will remember your name.";
      }
    }

    if (msg.contains("what is my name") ||
        msg.contains("do you know my name")) {
      final name = memory["name"];

      return name != null
          ? "Your name is $name."
          : "I don't know your name yet.";
    }

    // ===== FAVORITE LANGUAGE MEMORY =====

   // ===== FAVORITE LANGUAGE MEMORY =====

if (msg.contains("favorite language") ||
    msg.contains("favourite language")) {

  if (msg.contains("remember")) {
    String value = "";

    if (msg.contains("favorite language is")) {
      value = original.substring(
        original.toLowerCase().indexOf("favorite language is") +
            "favorite language is".length,
      ).trim();
    } else if (msg.contains("favourite language is")) {
      value = original.substring(
        original.toLowerCase().indexOf("favourite language is") +
            "favourite language is".length,
      ).trim();
    }

    if (value.isNotEmpty) {
      memory["favorite_language"] = value;
      await saveMemory(memory);

      return "Okay, I will remember that your favourite language is $value.";
    }
  }

  if (msg.contains("what is my favorite language") ||
      msg.contains("what is my favourite language")) {

    final lang = memory["favorite_language"];

    return lang != null
        ? "Your favourite language is $lang."
        : "I don't know your favourite language yet.";
  }
}

    // ===== GENERAL NOTES =====

    if (msg.startsWith("remember that ")) {
      final note = original.substring("remember that ".length).trim();

      if (note.isNotEmpty) {
        final notes = List<String>.from(memory["notes"] ?? []);

        notes.add(note);

        memory["notes"] = notes;

        await saveMemory(memory);

        return "Okay, I will remember that.";
      }
    }

    // ===== SHOW MEMORY =====

    if (msg.contains("what do you remember") ||
        msg.contains("show memory")) {
      if (memory.isEmpty) {
        return "I don't remember anything yet.";
      }

      return "I remember:\n${memory.entries.map((e) => "${e.key}: ${e.value}").join("\n")}";
    }

    // ===== CLEAR MEMORY =====

    if (msg.contains("forget my memory") ||
        msg.contains("clear memory") ||
        msg.contains("forget everything")) {
      await saveMemory({});

      return "I cleared your saved memory.";
    }

    return null;
  }
}