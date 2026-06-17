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

    if (cmd == "clear reminders" ||
        cmd == "delete reminders" ||
        cmd == "clear all reminders") {
      await prefs.remove("reminders");
      await prefs.remove("last_reminder_task");
      return "All reminders cleared.";
    }

    if (!cmd.startsWith("remind me")) {
      return null;
    }

    String reminderText = original
        .replaceFirst(RegExp(r'^remind me to\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^remind me\s+', caseSensitive: false), '')
        .trim();

    if (reminderText.isEmpty) {
      return "Please tell me what to remind you about.";
    }

    String task = reminderText;
    DateTime? reminderTime;
    Duration? delayDuration;

    final afterMatch = RegExp(
      r'\b(?:after|in)\s+(\d+)\s+(second|seconds|sec|secs|minute|minutes|min|mins|hour|hours|hr|hrs)\b',
      caseSensitive: false,
    ).firstMatch(reminderText);

    if (afterMatch != null) {
      final amount = int.parse(afterMatch.group(1)!);
      final unit = afterMatch.group(2)!.toLowerCase();

      if (unit.startsWith("hour") || unit.startsWith("hr")) {
        delayDuration = Duration(hours: amount);
      } else if (unit.startsWith("second") || unit.startsWith("sec")) {
        delayDuration = Duration(seconds: amount);
      } else {
        delayDuration = Duration(minutes: amount);
      }

      reminderTime = DateTime.now().add(delayDuration);

      task = reminderText
          .replaceRange(afterMatch.start, afterMatch.end, "")
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (task.isEmpty) task = "your reminder";
    }

    final tomorrowAtMatch = RegExp(
      r'\btomorrow\s+at\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(reminderText);

    if (reminderTime == null && tomorrowAtMatch != null) {
      final timeText = tomorrowAtMatch.group(1)!.trim();
      final parsedTime = _parseTime(timeText, forceTomorrow: true);

      if (parsedTime != null) {
        reminderTime = parsedTime;
        task = reminderText
            .replaceRange(tomorrowAtMatch.start, tomorrowAtMatch.end, "")
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (task.isEmpty) task = "your reminder";
      }
    }

    final atMatch = RegExp(
      r'\s+at\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(reminderText);

    if (reminderTime == null && atMatch != null) {
      final timeText = atMatch.group(1)!.trim();
      final parsedTime = _parseTime(timeText);

      if (parsedTime != null) {
        reminderTime = parsedTime;
        task = reminderText.substring(0, atMatch.start).trim();
      }
    }

    if (task.isEmpty) {
      task = "your reminder";
    }

    final saved = prefs.getStringList("reminders") ?? [];

    if (reminderTime == null) {
      saved.add(task);
      await prefs.setStringList("reminders", saved);
      await prefs.setString("last_reminder_task", task);
      return "Okay, I saved this reminder: $task";
    }

    final formatted = _formatDateTime(reminderTime);
    final reminderLine = "$task at $formatted";

    saved.add(reminderLine);
    await prefs.setStringList("reminders", saved);
    await prefs.setString("last_reminder_task", task);

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      if (delayDuration != null) {
        await NotificationService.scheduleDelayedReminder(
          id: id,
          title: "Gamma Reminder",
          body: task,
          delay: delayDuration,
        );
      } else {
        await NotificationService.scheduleReminder(
          id: id,
          title: "Gamma Reminder",
          body: task,
          dateTime: reminderTime,
        );
      }

      return "Okay, I will remind you to $task at $formatted.";
    } catch (e) {
      return "I saved the reminder, but notification scheduling failed: $e";
    }
  }

  static DateTime? _parseTime(String input, {bool forceTomorrow = false}) {
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

    if (forceTomorrow) {
      scheduled = scheduled.add(const Duration(days: 1));
    } else if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static String _formatDateTime(DateTime time) {
    final now = DateTime.now();

    int hour = time.hour % 12;
    if (hour == 0) hour = 12;

    final minute = time.minute.toString().padLeft(2, "0");
    final period = time.hour >= 12 ? "PM" : "AM";

    final isToday = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;

    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = time.year == tomorrow.year &&
        time.month == tomorrow.month &&
        time.day == tomorrow.day;

    if (isToday) return "$hour:$minute $period";
    if (isTomorrow) return "tomorrow at $hour:$minute $period";

    return "${time.day}-${time.month}-${time.year} at $hour:$minute $period";
  }
}