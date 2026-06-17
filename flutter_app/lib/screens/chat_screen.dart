import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torch_light/torch_light.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/command_service.dart';
import '../services/memory_service.dart';
import '../services/reminder_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isLoading = false;
  bool _isListening = false;

  final List<MessageModel> _messages = [];

  @override
@override
void initState() {
  super.initState();
  _setupTts();
  _loadMessages();
}

Future<void> _setupTts() async {
  await _tts.setLanguage("en-US");
  await _tts.setSpeechRate(0.52);
  await _tts.setPitch(1.0);
  await _tts.awaitSpeakCompletion(true);
}

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('chat_history');

    if (saved != null) {
      final List data = jsonDecode(saved);
      setState(() {
        _messages.addAll(
          data.map((e) => MessageModel(text: e['text'], isUser: e['isUser'])),
        );
      });
    } else {
      setState(() {
        _messages.add(
          MessageModel(
            text: "Hello Akash! I am Gamma Assistant 🚀",
            isUser: false,
          ),
        );
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _messages.map((m) {
      return {'text': m.text, 'isUser': m.isUser};
    }).toList();

    await prefs.setString('chat_history', jsonEncode(data));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBotMessage(String text) {
    _messages.add(MessageModel(text: text, isUser: false));
  }

 Future<void> _startListening() async {
  if (_isListening || _isLoading) return;

  await _tts.stop();

  final available = await _speech.initialize(
    onStatus: (status) async {
      if (status == "done" || status == "notListening") {
        if (mounted) setState(() => _isListening = false);
      }
    },
    onError: (error) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _addBotMessage("Voice error. Please try again.");
        });
      }
    },
  );

  if (!available) {
    setState(() {
      _addBotMessage("Microphone permission not available");
    });
    await _saveMessages();
    return;
  }

  setState(() => _isListening = true);

  await _speech.listen(
    listenFor: const Duration(seconds: 30),
    pauseFor: const Duration(seconds: 4),
    partialResults: true,
    listenMode: stt.ListenMode.dictation,
    onResult: (result) async {
      String spoken = result.recognizedWords.trim();
      if (spoken.isEmpty) return;

      final lower = spoken.toLowerCase();

      if (lower.contains("hey gamma")) {
        await _speech.stop();

        String command = lower.split("hey gamma").last.trim();

        if (mounted) setState(() => _isListening = false);

        if (command.isEmpty) {
          await _tts.speak("Yes Akash, how can I help?");
          await Future.delayed(const Duration(seconds: 2));
          await _startListening();
          return;
        }

        await _runText(command);
      }
    },
  );
}

  Future<void> _stopListening() async {
    await _speech.stop();
    await _speech.cancel();

    if (mounted) {
      setState(() {
        _isListening = false;
        _addBotMessage("Voice stopped");
      });
    }

    await _saveMessages();
    await _tts.speak("Voice stopped");
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!success) {
      setState(() {
        _addBotMessage("Could not open $url");
      });
    }
  }

  Future<bool> _handleCommand(String text) async {
  final cmd = text.toLowerCase().trim();

  // ✅ Clear chat must be FIRST
  if (cmd == "clear chat" ||
      cmd == "clear chart" ||
      cmd == "delete chat" ||
      cmd == "delete conversation" ||
      cmd == "delete our conversation" ||
      cmd == "clear messages" ||
      cmd == "clear all messages" ||
      cmd == "clear all messages on screen") {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');

    setState(() {
      _messages.clear();
      _messages.add(
        MessageModel(
          text: "Chat cleared. I am Gamma Assistant 🚀",
          isUser: false,
        ),
      );
      _isLoading = false;
    });

    await _saveMessages();
    _scrollToBottom();
    await _tts.speak("Chat cleared");
    return true;
  }

  final reminderReply = await ReminderService.handleReminderCommand(text);

  if (reminderReply != null) {
    setState(() => _addBotMessage(reminderReply));
    await _tts.speak(reminderReply);
    return true;
  }

 final memoryReply = await MemoryService.handleMemoryCommand(text);

if (memoryReply != null) {
  setState(() => _addBotMessage(memoryReply));
  await _tts.speak(memoryReply);
  return true;
}

final cloudMemoryReply = await ApiService.sendMemoryCommand(text);

if (cloudMemoryReply != null &&
    cloudMemoryReply != "null" &&
    cloudMemoryReply.isNotEmpty) {
  setState(() => _addBotMessage(cloudMemoryReply));
  await _tts.speak(cloudMemoryReply);
  return true;
}

  final localReply = await CommandService.handleCommand(text);

  if (localReply != null) {
    setState(() => _addBotMessage(localReply));
    await _tts.speak(localReply);
    return true;
  }

  if (cmd.contains("flashlight on") || cmd.contains("torch on")) {
    try {
      await TorchLight.enableTorch();
      setState(() => _addBotMessage("Flashlight turned ON"));
      await _tts.speak("Flashlight on");
    } catch (e) {
      setState(() => _addBotMessage("Flashlight not available"));
      await _tts.speak("Flashlight not available");
    }
    return true;
  }

  if (cmd.contains("flashlight off") || cmd.contains("torch off")) {
    try {
      await TorchLight.disableTorch();
      setState(() => _addBotMessage("Flashlight turned OFF"));
      await _tts.speak("Flashlight off");
    } catch (e) {
      setState(() => _addBotMessage("Could not turn off flashlight"));
      await _tts.speak("Could not turn off flashlight");
    }
    return true;
  }

  return false;
}

  Future<void> _runText(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(MessageModel(text: text, isUser: true));
      _isLoading = true;
    });

    _controller.clear();
    await _saveMessages();
    _scrollToBottom();

    final handled = await _handleCommand(text);

    if (handled) {
      setState(() => _isLoading = false);
      await _saveMessages();
      _scrollToBottom();
      return;
    }

    try {
      final reply = await ApiService.sendMessage(text);

     final cleanReply = reply.contains("SocketException") ||
        reply.contains("ClientException")
    ? "Unable to reach Gamma cloud server."
    : reply;

      setState(() {
        _addBotMessage(cleanReply);
        _isLoading = false;
      });

      await _saveMessages();
      _scrollToBottom();
      await _tts.speak(cleanReply);
    } catch (e) {
  setState(() {
    _addBotMessage('Error: $e');
    _isLoading = false;
  });

  await _saveMessages();
  _scrollToBottom();
  await _tts.speak("An error occurred");
}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    await _runText(text);
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 48, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xdd020617),
            Color(0xdd071326),
            Color(0xdd111827),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Gamma",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isListening
                      ? Colors.greenAccent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isListening
                        ? Colors.greenAccent.withOpacity(0.5)
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  _isListening ? "ONLINE" : "READY",
                  style: GoogleFonts.poppins(
                    color: _isListening ? Colors.greenAccent : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AvatarGlow(
            animate: _isListening,
            glowColor: Colors.cyanAccent,
            duration: const Duration(milliseconds: 1800),
            repeat: true,
            child: GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                height: 118,
                width: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xff67e8f9),
                      Color(0xff2563eb),
                      Color(0xff312e81),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.25),
                      blurRadius: 70,
                      spreadRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.graphic_eq : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isListening
                ? "Listening for your command..."
                : _isLoading
                    ? "Processing request..."
                    : "Your AI phone assistant is ready",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _isListening ? Colors.cyanAccent : Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(MessageModel m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          gradient: m.isUser
              ? const LinearGradient(
                  colors: [Color(0xff2563eb), Color(0xff4f46e5)],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.10),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(m.isUser ? 20 : 5),
            bottomRight: Radius.circular(m.isUser ? 5 : 20),
          ),
          border: Border.all(
            color: m.isUser
                ? Colors.blueAccent.withOpacity(0.5)
                : Colors.cyanAccent.withOpacity(0.18),
          ),
        ),
        child: m.isUser
            ? Text(
                m.text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              )
            : Text(
                m.text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xff020617),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.redAccent.withOpacity(0.18)
                      : Colors.cyanAccent.withOpacity(0.12),
                  border: Border.all(
                    color: _isListening ? Colors.redAccent : Colors.cyanAccent,
                  ),
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isListening ? Colors.redAccent : Colors.cyanAccent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ask Gamma anything...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xff22d3ee), Color(0xff2563eb)],
                  ),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _particleBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: GammaParticlePainter(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff020617),
      body: Stack(
        children: [
          _particleBackground(),
          Column(
            children: [
              _header(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xcc020617),
                        Color(0xcc08111f),
                        Color(0xcc0f172a),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    children: [
                      ..._messages.map(_bubble),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            "Gamma is thinking...",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _inputBar(),
            ],
          ),
        ],
      ),
    );
  }
}

class GammaParticlePainter extends CustomPainter {
  final math.Random random = math.Random(7);

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.28)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.10)
      ..strokeWidth = 0.6;

    final points = List.generate(70, (index) {
      return Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    });

    for (final point in points) {
      canvas.drawCircle(point, random.nextDouble() * 2.5 + 1, dotPaint);
    }

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;
        if (distance < 85) {
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}