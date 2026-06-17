import json
import os

HISTORY_FILE = "chat_history.json"

def load_history():
    if not os.path.exists(HISTORY_FILE):
        return []

    with open(HISTORY_FILE, "r") as f:
        return json.load(f)

def save_history(history):
    with open(HISTORY_FILE, "w") as f:
        json.dump(history, f, indent=2)

def add_message(role, content):
    history = load_history()

    history.append({
        "role": role,
        "content": content
    })

    history = history[-20:]

    save_history(history)