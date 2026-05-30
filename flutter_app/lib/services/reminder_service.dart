import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class ReminderService {
  static Future<String?> handleReminderCommand(String text) async {
    final original = text.trim();
    final cmd = original.toLowerCase();
    final prefs = await SharedPreferences.getInstance();

    if (cmd == "show reminders" ||
        cmd == "my reminders" ||
        cmd == "show my reminders") {
      final saved = prefs.getStringList("reminders") ?? [];

      if (saved.isEmpty) {
        return "You have no reminders.";
      }

      return "Your reminders are:\n${saved.asMap().entries.map((e) {
        return "${e.key + 1}. ${e.value}";
      }).join("\n")}";
    }

    if (cmd == "clear reminders" || cmd == "delete reminders") {
      await prefs.remove("reminders");
      await prefs.remove("last_reminder_task");
      return "All reminders cleared.";
    }

    if (!cmd.startsWith("remind me to ")) {
      return null;
    }

    String reminderText = original.substring("remind me to ".length).trim();

    if (reminderText.isEmpty) {
      return "Please tell me what to remind you about.";
    }

    String task = reminderText;
    DateTime? reminderTime;

    final atMatch = RegExp(
      r'\s+at\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(reminderText);

    if (atMatch != null) {
      final timeText = atMatch.group(1)!.trim();
      task = reminderText.substring(0, atMatch.start).trim();
      reminderTime = _parseTime(timeText);
    }

    if (task.isEmpty) {
      return "Please tell me what to remind you about.";
    }

    final saved = prefs.getStringList("reminders") ?? [];

    if (reminderTime == null) {
      saved.add(task);
      await prefs.setStringList("reminders", saved);
      await prefs.setString("last_reminder_task", task);
      return "Okay, I will remember: $task";
    }

    final formatted = _formatTime(reminderTime);
    final reminderLine = "$task at $formatted";

    saved.add(reminderLine);
    await prefs.setStringList("reminders", saved);
    await prefs.setString("last_reminder_task", task);

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await NotificationService.scheduleReminder(
        id: id,
        title: "Gamma Reminder",
        body: task,
        dateTime: reminderTime,
      );

      return "Okay, I will remind you to $task at $formatted.";
    } catch (e) {
      return "I saved the reminder, but notification scheduling failed. Check notification and exact alarm permissions.";
    }
  }

  static DateTime? _parseTime(String input) {
    final now = DateTime.now();

    String value = input
        .toLowerCase()
        .replaceAll(".", ":")
        .replaceAll("a.m", "am")
        .replaceAll("p.m", "pm")
        .replaceAll("a m", "am")
        .replaceAll("p m", "pm")
        .trim();

    final match = RegExp(
      r'^(\d{1,2})(?::(\d{1,2}))?\s*(am|pm)?$',
    ).firstMatch(value);

    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    int minute = int.tryParse(match.group(2) ?? "0") ?? 0;
    final period = match.group(3);

    if (minute < 0 || minute > 59) return null;

    if (period == "am") {
      if (hour == 12) hour = 0;
    } else if (period == "pm") {
      if (hour < 12) hour += 12;
    } else {
      if (hour < 0 || hour > 23) return null;
    }

    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static String _formatTime(DateTime time) {
    int hour = time.hour % 12;
    if (hour == 0) hour = 12;

    final minute = time.minute.toString().padLeft(2, "0");
    final period = time.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }
}