from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal, ROUND_UP
from uuid import uuid4

import dotenv
from google import genai
import PIL.Image
import os

from flask import Flask, jsonify, render_template, request

import db

app = Flask(__name__)

# Initialize database on startup
db.init_db()
dotenv.load_dotenv()
API_KEY = os.getenv("GEMINI_KEY")


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
        db.create_status(user_id, "starting_funds", "starting_funds", 10.0)
        statuses = db.get_all_status(user_id)
    return statuses


def append_status(user_id: str, payment_type: str, amount_per_payment: float) -> dict:
    status_id = str(uuid4())
    return db.create_status(user_id, status_id, payment_type, amount_per_payment)


@app.get("/")
def home():
    return render_template("index.html")


@app.post("/upload_transactions")
def upload_transactions():
    user_id, error = require_user_id()
    if error:
        return error

    image_file = request.files.get("image")

    if image_file is None:
        return jsonify({"error": "Missing file field: image"}), 400
    
    if not API_KEY:
        return jsonify({"error": "GEMINI_KEY environment variable not set"}), 500
    
    client = genai.Client(api_key=API_KEY)

    try:
        img = PIL.Image.open(image_file.stream)
        prompt = (
            "You are to get a bank statement that has transaction history. " \
            "For every transaction, round up and only up to the $5 mark (remain the same if already a multiple of 5) calculate the rounded amount per transaction. " \
            "and return the total_amount and the sum of the rounded amounts. " \
            "Return ONLY the numeric values separated by a colon (e.g., -14.52:-15.00). " \
            "Do not include dollar signs, currency symbols, or any other text."
        )
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents = [img, prompt]
        )  
        raw_text = response.text.strip().replace('$', '').replace(',', '')
        
        # Parse both values separated by colon (e.g., "-14.52:-15.00")
        values = raw_text.split(':')
        if len(values) != 2:
            raise ValueError(f"Expected two values separated by colon, got: {raw_text}")
        
        real_total = abs(Decimal(values[0].strip()))
        rounded_total = abs(Decimal(values[1].strip()))

    except PIL.UnidentifiedImageError:
        return jsonify({"error": "Invalid image file provided."}), 400
    except ValueError:
        return jsonify({"error": "Could not confidently extract a total from the image. Please try a clearer picture."}), 422
    except Exception as e:
        return jsonify({"error": f"OCR processing failed: {str(e)}"}), 500

    transaction_id = next_transaction_id(user_id)
    # Calculate the difference between rounded total and actual total
    rounded_amount = float((rounded_total - real_total).quantize(Decimal("0.01")))
        
    # fake_total = Decimal("13.42") + Decimal(transaction_id % 4)
    #rounded = fake_total.quantize(Decimal("1"), rounding=ROUND_UP)
    # rounded_amount = float((rounded - fake_total).quantize(Decimal("0.01")))


    transaction = db.create_transaction(user_id, transaction_id, float(real_total), rounded_amount)

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

    existing = db.get_sponsorship_by_user_task(user_id, task_id)
    if existing is not None:
        share_link = existing["share_link"]
        print(share_link)
        return jsonify(
            {
                "id": existing["id"],
                "link": share_link,
                "share_link": share_link,
                "url": share_link,
                "sponsorship_link": share_link,
                "sponsorship": existing,
                "message": "Sponsorship already exists for this task",
            }
        )

    sponsorship_id = str(uuid4())
    share_link = f"http://tassel-gh.duckdns.org/s/{sponsorship_id}"
    print(share_link)
    sponsorship = db.create_sponsorship(user_id, sponsorship_id, task_id, title, title, share_link)

    return jsonify(
        {
            "link": share_link,
            "share_link": share_link,
            "url": share_link,
            "sponsorship_link": share_link,
            "id": sponsorship["id"],
            "sponsorship": sponsorship,
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


@app.get("/s/<sponsorship_id>")
def sponsorship_page(sponsorship_id: str):
    sponsorship = db.get_sponsorship_by_id(sponsorship_id)
    if sponsorship is None:
        return jsonify({"error": "Sponsorship not found"}), 404

    task = db.get_task_by_id(sponsorship["task_id"])
    if task is None:
        return jsonify({"error": "Task not found for sponsorship"}), 404

    return render_template(
        "sponsorship.html",
        sponsorship_id=sponsorship_id,
        user_id=sponsorship["user_id"],
        task_name=task["title"],
        task_description=task["description"],
        sponsorship_status=sponsorship["status"],
    )


@app.post("/sponsor")
def sponsor_task():
    sponsorship_id = (request.form.get("sponsorship_id") or "").strip()
    sponsor_name = (request.form.get("sponsor_name") or "").strip()

    if not sponsorship_id or not sponsor_name:
        return jsonify({"error": "sponsorship_id and sponsor_name are required"}), 400

    result = db.apply_sponsorship(sponsorship_id, sponsor_name)
    if result is None:
        return jsonify({"error": "Sponsorship or task not found"}), 404

    sponsorship = result["sponsorship"]
    task = result["task"]
    if float(result["new_deposit_amount"]) > float(result["old_deposit_amount"]):
        append_status(sponsorship["user_id"], "task_sponsored", float(result["new_deposit_amount"]))

    return render_template(
        "sponsor_success.html",
        sponsor_name=sponsor_name,
        task_name=task["title"],
        old_deposit_amount=result["old_deposit_amount"],
        new_deposit_amount=result["new_deposit_amount"],
        sponsored_by=task["sponsored_by"],
        sponsorship_status=sponsorship["status"],
    )


@app.get("/loan")
def loan():
    user_id, error = require_user_id()
    if error:
        return error
    # Calculate total from database
    return 39075


@app.get("/status")
def status():
    user_id, error = require_user_id()
    if error:
        return error

    statuses = get_or_seed_status(user_id)
    return jsonify(statuses)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=3000)
