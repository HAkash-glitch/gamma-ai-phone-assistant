import json
import os

from flask import Flask, request, jsonify
from flask_cors import CORS
from ai_engine import get_ai_reply

app = Flask(__name__)
CORS(app)

MEMORY_FILE = "gamma_memory.json"


def load_memory():
    if not os.path.exists(MEMORY_FILE):
        return {}

    try:
        with open(MEMORY_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {}


def save_memory(memory):
    with open(MEMORY_FILE, "w") as f:
        json.dump(memory, f, indent=2)


@app.route("/", methods=["GET"])
def home():
    return jsonify({"status": "Gamma backend is running"})


@app.route("/chat", methods=["POST"])
def chat():
    data = request.get_json(silent=True) or {}
    message = data.get("message", "").strip()

    if not message:
        return jsonify({"error": "No message provided"}), 400

    reply = get_ai_reply(message)

    return jsonify({"reply": reply})


@app.route("/memory", methods=["POST"])
def memory():
    data = request.get_json(silent=True) or {}
    command = data.get("message", "").strip()
    msg = command.lower()

    memory_data = load_memory()

    if "what do you remember" in msg or "show memory" in msg or "show my memory" in msg:
        if not memory_data:
            return jsonify({"reply": "I don't remember anything yet."})

        lines = []

        if "name" in memory_data:
            lines.append(f"Your name is {memory_data['name']}.")

        notes = memory_data.get("notes", [])
        if notes:
            lines.append("Notes:")
            for i, note in enumerate(notes, start=1):
                lines.append(f"{i}. {note}")

        return jsonify({"reply": "\n".join(lines)})

    if "clear memory" in msg or "forget everything" in msg or "forget my memory" in msg:
        save_memory({})
        return jsonify({"reply": "Cloud memory cleared."})

    if msg.startswith("remember my name is "):
        name = command[len("remember my name is "):].strip()
        if not name:
            return jsonify({"reply": "Tell me your name first."})

        memory_data["name"] = name
        save_memory(memory_data)
        return jsonify({"reply": f"Got it. I will remember your name is {name}."})

    if msg.startswith("my name is "):
        name = command[len("my name is "):].strip()
        if not name:
            return jsonify({"reply": "Tell me your name first."})

        memory_data["name"] = name
        save_memory(memory_data)
        return jsonify({"reply": f"Nice to meet you, {name}. I will remember your name."})

    if "remember" in msg:
        note = command

        cleanup_phrases = [
            "remember that",
            "remember this",
            "remember it",
            "please remember",
            "can you remember",
            "remember",
        ]

        for phrase in cleanup_phrases:
            note = note.replace(phrase, "", 1).strip()
            note = note.replace(phrase.capitalize(), "", 1).strip()

        if not note:
            return jsonify({"reply": "Tell me what to remember."})

        memory_data.setdefault("notes", []).append(note)
        save_memory(memory_data)
        return jsonify({"reply": "Okay, I will remember that."})

    return jsonify({"reply": None})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)