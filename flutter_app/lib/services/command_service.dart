import 'package:battery_plus/battery_plus.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';

class CommandService {
  static Future<String?> handleCommand(String message) async {
    final text = message.toLowerCase().trim();

    if (text.contains("time")) {
      final now = DateTime.now();
      return "Current time is ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    }

    if (text.contains("date")) {
      final now = DateTime.now();
      return "Today's date is ${now.day}-${now.month}-${now.year}";
    }

    if (text.contains("battery")) {
      final battery = Battery();
      final level = await battery.batteryLevel;
      return "Battery level is $level%";
    }

    if (text.contains("open settings")) {
      const intent = AndroidIntent(
        action: 'android.settings.SETTINGS',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return "Opening Settings";
    }

    if (text.contains("open camera")) {
      const intent = AndroidIntent(
        action: 'android.media.action.IMAGE_CAPTURE',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return "Opening Camera";
    }
    if (text.contains("open youtube")) {
  try {
    const intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: 'vnd.youtube:',
      package: 'com.google.android.youtube',
    );
    await intent.launch();
    return "Opening YouTube";
  } catch (e) {
    await _openUrl("https://www.youtube.com");
    return "Opening YouTube in browser";
  }
}

    if (text.startsWith("open ")) {
      final appName = text.replaceFirst("open ", "").trim();

      if (appName.isNotEmpty) {
        final opened = await _openInstalledApp(appName);

        if (opened) {
          return "Opening $appName";
        }

        return "I could not find $appName on this phone";
      }
    }

    if (text.startsWith("search for ")) {
      final query = text.replaceFirst("search for ", "").trim();

      if (query.isNotEmpty) {
        await _openUrl(
          "https://www.google.com/search?q=${Uri.encodeComponent(query)}",
        );
        return "Searching for $query";
      }
    }

    if (text.startsWith("play ")) {
      final query = text.replaceFirst("play ", "").trim();

      if (query.isNotEmpty) {
        await _openUrl(
          "https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}",
        );
        return "Playing $query";
      }
    }

    if (text.startsWith("navigate to ")) {
      final place = text.replaceFirst("navigate to ", "").trim();

      if (place.isNotEmpty) {
        await _openUrl(
          "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}",
        );
        return "Navigating to $place";
      }
    }

    if (text.startsWith("call ")) {
      final number = text.replaceFirst("call ", "").trim();

      if (number.isNotEmpty) {
        await _openUrl("tel:$number");
        return "Calling $number";
      }
    }

    if (text.contains("send sms")) {
      await _openUrl("sms:");
      return "Opening SMS app";
    }

    if (text.contains("what can you do")) {
      return "I can open installed apps, tell time, show date, check battery, open settings, open camera, search Google, play YouTube songs, navigate places, call numbers, and answer questions.";
    }

    return null;
  }

  static Future<bool> _openInstalledApp(String appName) async {
    final List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);

    for (final app in apps) {
      final name = app.name.toLowerCase();

      if (name == appName.toLowerCase() || name.contains(appName.toLowerCase())) {
        await InstalledApps.startApp(app.packageName);
        return true;
      }
    }

    return false;
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}