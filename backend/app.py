from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal, ROUND_UP
from uuid import uuid4

from flask import Flask, jsonify, request

import db

app = Flask(__name__)

# Initialize database on startup
db.init_db()


def get_user_id() -> str | None:
    return request.headers.get("user-id")


def require_user_id():
    user_id = get_user_id()
    if not user_id:
        return None, (jsonify({"error": "Missing required header: user-id"}), 400)
    return user_id, None


def next_transaction_id(user_id: str) -> int:
    return db.get_next_transaction_id(user_id)


def get_or_seed_status(user_id: str) -> list[dict]:
    statuses = db.get_all_status(user_id)
    # If no statuses exist, seed them
    if not statuses:
        db.create_status(user_id, "status_1", "daily_roundup", 3.5)
        db.create_status(user_id, "status_2", "weekly_transfer", 12.0)
        statuses = db.get_all_status(user_id)
    return statuses


def append_status(user_id: str, payment_type: str, amount_per_payment: float) -> dict:
    status_id = str(uuid4())
    return db.create_status(user_id, status_id, payment_type, amount_per_payment)


@app.post("/upload_transactions")
def upload_transactions():
    user_id, error = require_user_id()
    if error:
        return error

    image = request.files.get("image")
    if image is None:
        return jsonify({"error": "Missing file field: image"}), 400

    transaction_id = next_transaction_id(user_id)
    fake_total = Decimal("13.42") + Decimal(transaction_id % 4)
    rounded = fake_total.quantize(Decimal("1"), rounding=ROUND_UP)
    rounded_amount = float((rounded - fake_total).quantize(Decimal("0.01")))

    transaction = db.create_transaction(user_id, transaction_id, float(fake_total), rounded_amount)

    return jsonify(
        {
            "transaction_id": transaction["transaction_id"],
            "total_amount": transaction["total_amount"],
            "rounded_amount": transaction["rounded_amount"],
        }
    )


@app.post("/request")
def request_funds():
    user_id, error = require_user_id()
    if error:
        return error

    payload = request.get_json(silent=True) or {}
    transaction_id = payload.get("transaction_id")
    request_amount = payload.get("rounded_amount")

    if transaction_id is None or request_amount is None:
        return jsonify({"error": "transaction_id and request_amount are required"}), 400

    try:
        transaction_id = int(transaction_id)
        request_amount = float(request_amount)
    except (TypeError, ValueError):
        return jsonify({"error": "transaction_id must be int and request_amount must be number"}), 400

    tx = db.get_transaction(user_id, transaction_id)
    if tx is None:
        return jsonify({"error": "transaction_id not found"}), 400

    if request_amount > float(tx["rounded_amount"]):
        return jsonify({"error": "request_amount exceeds rounded_amount"}), 400

    db.update_transaction_paid(user_id, transaction_id)
    append_status(user_id, "request_paid", request_amount)
    return jsonify({"success": True, "message": "Request accepted"}), 200


@app.get("/transaction_history")
def transaction_history():
    user_id, error = require_user_id()
    if error:
        return error
    transactions = db.get_all_transactions(user_id)
    return jsonify(transactions)


@app.get("/history_task")
def history_task():
    user_id, error = require_user_id()
    if error:
        return error

    tasks = db.get_all_tasks(user_id)
    return jsonify(tasks)


@app.post("/create_task")
def create_task():
    user_id, error = require_user_id()
    if error:
        return error

    if request.content_type is None or "application/json" not in request.content_type:
        return jsonify({"error": "Content-Type must be application/json"}), 400

    payload = request.get_json(silent=True) or {}
    task_type = payload.get("type")
    title = payload.get("title")
    description = payload.get("description")
    deposit_amount = payload.get("deposit_amount")

    if task_type not in {"productivity", "achievement"}:
        return jsonify({"error": "type must be productivity or achievement"}), 400

    if not title or not description or deposit_amount is None:
        return jsonify({"error": "Missing required fields"}), 400

    task_id = str(uuid4())
    tracked_app_name = payload.get("tracked_app_name") if payload.get("track_screen_time") else None
    
    task = db.create_task(user_id, task_id, title, description, task_type, deposit_amount, tracked_app_name)

    return jsonify(task), 201


@app.post("/close_task")
def close_task():
    user_id, error = require_user_id()
    if error:
        return error

    if request.content_type is None or "application/json" not in request.content_type:
        return jsonify({"success": False, "message": "Content-Type must be application/json"}), 400

    payload = request.get_json(silent=True) or {}
    task_id = payload.get("task_id")
    result = payload.get("result")

    if not task_id or result not in {"success", "failure"}:
        return jsonify({"success": False, "message": "task_id and valid result are required"}), 400

    task = db.get_task(user_id, task_id)
    if task is None:
        return jsonify({"success": False, "message": "Task not found"}), 404

    db.close_task(user_id, task_id, result)

    if result == "failure":
        append_status(user_id, "task_failed", float(task.get("deposit_amount", 0.0)))

    return jsonify({"success": True, "message": f"Task '{task.get('title', '')}' closed"}), 200


@app.post("/request_sponsorship")
def request_sponsorship():
    user_id, error = require_user_id()
    if error:
        return error

    if request.content_type is None or "application/json" not in request.content_type:
        return jsonify({"error": "Content-Type must be application/json"}), 400

    payload = request.get_json(silent=True) or {}
    task_id = payload.get("task_id")
    title = payload.get("title")

    if not task_id or not title:
        return jsonify({"error": "task_id and title are required"}), 400

    sponsorship_id = str(uuid4())
    share_link = f"https://fake-sponsor.tassel.app/s/{sponsorship_id}"
    
    sponsorship = db.create_sponsorship(user_id, sponsorship_id, task_id, title, title, share_link)

    return jsonify(
        {
            "link": share_link,
            "share_link": share_link,
            "url": share_link,
            "sponsorship_link": share_link,
            "message": "Sponsorship link created",
        }
    )


@app.get("/current_sponsorship")
def current_sponsorship():
    user_id, error = require_user_id()
    if error:
        return error

    sponsorships = db.get_all_sponsorships(user_id)
    return jsonify(sponsorships)


@app.get("/loan")
def loan():
    user_id, error = require_user_id()
    if error:
        return error

    # Calculate total from database
    transactions = db.get_all_transactions(user_id)
    transaction_total = sum(t["rounded_amount"] for t in transactions)
    return f"{transaction_total:.2f}"


@app.get("/status")
def status():
    user_id, error = require_user_id()
    if error:
        return error

    statuses = get_or_seed_status(user_id)
    return jsonify(statuses)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=3002)
