# Gamma AI Phone Assistant

Gamma AI Phone Assistant is an intelligent Android voice assistant built using Flutter and Python. It combines speech recognition, text-to-speech, AI-powered conversations, and device control features to provide a smart hands-free assistant experience.

## Features

* Voice-to-Text (Speech Recognition)
* Text-to-Speech Responses
* AI-Powered Chat Assistant
* Open Applications Using Voice Commands
* Flashlight Control
* Smart Device Commands
* Reminder and Notification Support
* Clean Flutter-Based User Interface
* Python Flask Backend Integration
* Memory-Based Conversations
* Wake Word Support (Work in Progress)

## Tech Stack

### Frontend

* Flutter
* Dart

### Backend

* Python
* Flask

### AI & Voice Technologies

* Speech-to-Text
* Text-to-Speech
* OpenRouter API

### Tools

* Git
* GitHub
* Android Studio
* VS Code

## Project Structure

```bash
gamma-ai-phone-assistant/
│
├── flutter_app/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── ai-assistant-backend/
│   ├── app.py
│   ├── ai_engine.py
│   └── requirements.txt
│
└── README.md
```

## How It Works

1. User speaks a command.
2. Speech Recognition converts voice to text.
3. The command is processed locally or sent to the Flask backend.
4. AI generates a response.
5. Text-to-Speech reads the response aloud.
6. Gamma performs supported actions such as opening apps or controlling device utilities.

## Current Commands

* Open YouTube
* Open Google
* Open WhatsApp
* Flashlight On
* Flashlight Off
* Check Time
* Check Date
* Basic AI Chat

## Future Improvements

* Real Wake Word Detection ("Hey Gamma")
* Offline AI Support
* Phone Call Handling
* Music Controls
* Calendar Integration
* Advanced Device Automation
* Custom User Memory
* Multi-Language Support

## Screenshots

### Home Screen

![Home Screen](screenshots/home.png)

### Chat Interface

![Chat Interface](screenshots/chat.png)

## Installation

### Backend

```bash
cd ai-assistant-backend
pip install -r requirements.txt
python app.py
```

### Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

## Author

**Hosmani Akash**

* GitHub: https://github.com/HAkash-glitch
* LeetCode: https://leetcode.com/hosakash2005

## License

This project is developed for educational and portfolio purposes.
