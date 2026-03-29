from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal, ROUND_UP
from uuid import uuid4

from flask import Flask, jsonify, request

app = Flask(__name__)

# In-memory temporary stores keyed by user-id.
transactions_by_user: dict[str, list[dict]] = {}
tasks_by_user: dict[str, list[dict]] = {}
sponsorships_by_user: dict[str, list[dict]] = {}
status_by_user: dict[str, list[dict]] = {}


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def get_user_id() -> str | None:
    return request.headers.get("user-id")


def require_user_id():
    user_id = get_user_id()
    if not user_id:
        return None, (jsonify({"error": "Missing required header: user-id"}), 400)
    return user_id, None


def next_transaction_id(user_id: str) -> int:
    existing = transactions_by_user.get(user_id, [])
    if not existing:
        return 1
    return max(t["transaction_id"] for t in existing) + 1


def get_or_seed_status(user_id: str) -> list[dict]:
    if user_id not in status_by_user:
        status_by_user[user_id] = [
            {
                "id": "status_1",
                "payment_type": "daily_roundup",
                "amount_per_payment": 3.5,
                "date_time": now_iso(),
            },
            {
                "id": "status_2",
                "payment_type": "task",
                "amount_per_payment": 12.0,
                "date_time": now_iso(),
            },
        ]
    return status_by_user[user_id]


def append_status(user_id: str, payment_type: str, amount_per_payment: float) -> dict:
    status_items = get_or_seed_status(user_id)
    status_entry = {
        "id": f"status_{len(status_items) + 1}",
        "payment_type": payment_type,
        "amount_per_payment": float(amount_per_payment),
        "date_time": now_iso(),
    }
    status_items.append(status_entry)
    status_by_user[user_id] = status_items
    return status_entry


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

    transaction = {
        "transaction_id": transaction_id,
        "total_amount": float(fake_total),
        "rounded_amount": rounded_amount,
        "paid": False,
    }
    transactions_by_user.setdefault(user_id, []).append(transaction)

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
    print(transaction_id, request_amount)

    if transaction_id is None or request_amount is None:
        return jsonify({"error": "transaction_id and request_amount are required"}), 400

    try:
        transaction_id = int(transaction_id)
        request_amount = float(request_amount)
    except (TypeError, ValueError):
        return jsonify({"error": "transaction_id must be int and request_amount must be number"}), 400

    tx_list = transactions_by_user.get(user_id, [])
    tx = next((t for t in tx_list if t["transaction_id"] == transaction_id), None)
    if tx is None:
        return jsonify({"error": "transaction_id not found"}), 400

    if request_amount > float(tx["rounded_amount"]):
        return jsonify({"error": "request_amount exceeds rounded_amount"}), 400

    tx["paid"] = True
    append_status(user_id, "request_paid", request_amount)
    return jsonify({"success": True, "message": "Request accepted"}), 200


@app.get("/transaction_history")
def transaction_history():
    user_id, error = require_user_id()
    if error:
        return error
    print(transactions_by_user.get(user_id, []))
    return jsonify(transactions_by_user.get(user_id, []))


@app.get("/history_task")
def history_task():
    user_id, error = require_user_id()
    if error:
        return error

    return jsonify(tasks_by_user.get(user_id, []))


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

    task = {
        "id": str(uuid4()),
        "title": str(title),
        "description": str(description),
        "type": task_type,
        "deposit_amount": float(deposit_amount),
        "tracked_app_name": payload.get("tracked_app_name") if payload.get("track_screen_time") else None,
        "status": "open",
        "created_at": now_iso(),
        "closed_at": None,
        "result": None,
    }
    tasks_by_user.setdefault(user_id, []).append(task)

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

    tasks = tasks_by_user.get(user_id, [])
    task = next((t for t in tasks if t["id"] == task_id), None)
    if task is None:
        return jsonify({"success": False, "message": "Task not found"}), 404

    task["status"] = "closed"
    task["result"] = result
    task["closed_at"] = now_iso()

    if result == "failure":
        append_status(user_id, "task_failed", float(task.get("deposit_amount", 0.0)))

    return jsonify({"success": True, "message": f"Task '{task.get('title', payload.get('title', ''))}' closed"}), 200


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
    sponsorship = {
        "id": sponsorship_id,
        "title": str(title),
        "task_id": str(task_id),
        "task_title": str(title),
        "status": "pending",
        "details": "Waiting for sponsor acceptance",
        "share_link": share_link,
        "created_at": now_iso(),
        "notes": "Temporary fake sponsorship record",
    }
    sponsorships_by_user.setdefault(user_id, []).append(sponsorship)

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

    return jsonify(sponsorships_by_user.get(user_id, []))


@app.get("/loan")
def loan():
    user_id, error = require_user_id()
    if error:
        return error

    # Fake loan string amount endpoint.
    transaction_total = sum(t["rounded_amount"] for t in transactions_by_user.get(user_id, []))
    return f"{transaction_total:.2f}"


@app.get("/status")
def status():
    user_id, error = require_user_id()
    if error:
        return error
    print(get_or_seed_status(user_id))
    return jsonify(get_or_seed_status(user_id))


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=3000)
