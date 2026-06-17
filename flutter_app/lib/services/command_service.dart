import 'package:android_intent_plus/android_intent.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volume_controller/volume_controller.dart';

class CommandService {
  static Future<String?> handleCommand(String text) async {
    String cmd = text.toLowerCase().trim();

    cmd = cmd
        .replaceFirst("hey gamma", "")
        .replaceFirst("hey gama", "")
        .replaceFirst("gamma", "")
        .replaceFirst("gama", "")
        .trim();

    print("COMMAND RECEIVED: $cmd");

    if (cmd == "test") {
      return "Command service working";
    }

    if (cmd.contains("time")) {
      final now = DateTime.now();
      return "Current time is ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    }

    if (cmd.contains("date")) {
      final now = DateTime.now();
      return "Today is ${now.day}-${now.month}-${now.year}";
    }

    if (cmd.contains("battery")) {
      final battery = Battery();
      final level = await battery.batteryLevel;
      return "Battery is $level percent";
    }

    if (cmd.contains("volume up") || cmd.contains("increase volume")) {
      try {
        final volume = await VolumeController.instance.getVolume();
        final newVolume = (volume + 0.15).clamp(0.0, 1.0);
        await VolumeController.instance.setVolume(newVolume);
        return "Volume increased";
      } catch (e) {
        return "I couldn't change the volume";
      }
    }

    if (cmd.contains("volume down") || cmd.contains("decrease volume")) {
      try {
        final volume = await VolumeController.instance.getVolume();
        final newVolume = (volume - 0.15).clamp(0.0, 1.0);
        await VolumeController.instance.setVolume(newVolume);
        return "Volume decreased";
      } catch (e) {
        return "I couldn't change the volume";
      }
    }

    if (cmd.contains("mute volume") || cmd == "mute") {
      try {
        await VolumeController.instance.setVolume(0.0);
        return "Volume muted";
      } catch (e) {
        return "I couldn't mute the volume";
      }
    }

    if (cmd.contains("full volume") ||
        cmd.contains("max volume") ||
        cmd.contains("maximum volume")) {
      try {
        await VolumeController.instance.setVolume(1.0);
        return "Volume set to maximum";
      } catch (e) {
        return "I couldn't set full volume";
      }
    }

    if (cmd.contains("open jiosaavn") ||
        cmd.contains("open jio saavn") ||
        cmd.contains("play song in jiosaavn") ||
        cmd.contains("play song in jio saavn")) {
      await _openAppOrUrl("com.jio.media.jiobeats", "https://www.jiosaavn.com/");
      return "Opening JioSaavn";
    }

    if (cmd.contains("open spotify") || cmd.contains("play song in spotify")) {
      await _openAppOrUrl("com.spotify.music", "https://open.spotify.com/");
      return "Opening Spotify";
    }

    if (cmd.contains("open youtube music") ||
        cmd.contains("play song in youtube music")) {
      await _openAppOrUrl(
        "com.google.android.apps.youtube.music",
        "https://music.youtube.com/",
      );
      return "Opening YouTube Music";
    }

    if (cmd.contains("open youtube")) {
      await _openAppOrUrl("com.google.android.youtube", "https://youtube.com");
      return "Opening YouTube";
    }

    if (cmd.contains("open whatsapp")) {
      await _openAppOrUrl("com.whatsapp", "https://wa.me/");
      return "Opening WhatsApp";
    }

    if (cmd.contains("open instagram")) {
      await _openAppOrUrl("com.instagram.android", "https://instagram.com");
      return "Opening Instagram";
    }

    if (cmd.contains("open chrome") || cmd.contains("open google")) {
      await _openAppOrUrl("com.android.chrome", "https://google.com");
      return "Opening Chrome";
    }

    if (cmd.startsWith("call ") || cmd.contains(" call ")) {
      final target = cmd.replaceFirst("call", "").trim();

      if (target.isEmpty) {
        return "Please say a number or contact name";
      }

      final directNumber = target.replaceAll(RegExp(r'[^0-9+]'), '');

      if (directNumber.length >= 5) {
        await _directCall(directNumber);
        return "Calling $directNumber";
      }

      final number = await _findContactNumber(target);

      if (number == null) {
        return "I couldn't find $target in your contacts";
      }

      await _directCall(number);
      return "Calling $target";
    }

    if (cmd.startsWith("message ")) {
      final message = cmd.replaceFirst("message", "").trim();

      await launchUrl(
        Uri.parse("sms:?body=${Uri.encodeComponent(message)}"),
        mode: LaunchMode.externalApplication,
      );

      return "Opening SMS";
    }

    if (cmd.startsWith("whatsapp message ")) {
      final msg = cmd.replaceFirst("whatsapp message", "").trim();

      await launchUrl(
        Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msg)}"),
        mode: LaunchMode.externalApplication,
      );

      return "Opening WhatsApp message";
    }

    if (cmd.contains("screenshot") || cmd.contains("take screenshot")) {
      return "Press Power button and Volume Down together to take a screenshot";
    }

    if (cmd.startsWith("youtube search ")) {
      final query = cmd.replaceFirst("youtube search", "").trim();

      await launchUrl(
        Uri.parse(
          "https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}",
        ),
        mode: LaunchMode.externalApplication,
      );

      return "Searching YouTube";
    }

    if (cmd.startsWith("search ")) {
      final query = cmd.replaceFirst("search", "").trim();

      await launchUrl(
        Uri.parse("https://www.google.com/search?q=${Uri.encodeComponent(query)}"),
        mode: LaunchMode.externalApplication,
      );

      return "Searching Google";
    }

    return null;
  }

  static Future<String?> _findContactNumber(String name) async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);

    if (status != PermissionStatus.granted) {
      return null;
    }

    final contacts = await FlutterContacts.getAll(
      properties: {
        ContactProperty.name,
        ContactProperty.phone,
      },
    );

    final searchName = _cleanName(name);

    for (final contact in contacts) {
      final displayName = _cleanName(contact.displayName ?? "");

      if (displayName == searchName ||
          displayName.split(" ").contains(searchName) ||
          displayName.startsWith(searchName)) {
        if (contact.phones.isNotEmpty) {
          return contact.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '');
        }
      }
    }

    return null;
  }

  static String _cleanName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<void> _directCall(String number) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$number',
    );

    await intent.launch();
  }

  static Future<void> _openAppOrUrl(
    String packageName,
    String fallbackUrl,
  ) async {
    final isInstalled = await InstalledApps.isAppInstalled(packageName);

    if (isInstalled == true) {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: packageName,
      );
      await intent.launch();
    } else {
      await launchUrl(
        Uri.parse(fallbackUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}