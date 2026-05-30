from flask import Flask, request, jsonify
from flask_cors import CORS   # ✅ ADD THIS
from ai_engine import get_ai_reply

app = Flask(__name__)
CORS(app)   # ✅ ADD THIS

@app.route("/chat", methods=["POST"])
def chat():
    data = request.json
    message = data.get("message", "")

    if not message:
        return jsonify({"error": "No message provided"}), 400

    reply = get_ai_reply(message)

    return jsonify({
        "reply": reply
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)