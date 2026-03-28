import math
import uuid
from flask import Flask, jsonify, request
from flask_cors import CORS
from db import users_col, tasks_col, transactions_col

app = Flask(__name__)
CORS(app)

@app.route('/', methods=['GET'])
def home():
    return "<h1>Tassel Server is Online! 🚀</h1><p>If you see this, the server is working perfectly.</p>"

@app.route('/api/status/<user_id>', methods=['GET'])
def get_status(user_id):
    user = users_col.find_one({"user_id": user_id}, {"_id": 0})
    if not user:
        user = {"user_id": user_id, "total_saved": 0.0, "loan_balance": 25000.0}
        users_col.insert_one(user)
        del user['_id']
        
    tasks = list(tasks_col.find({"user_id": user_id, "status": "pending"}, {"_id": 0}))
    user["active_tasks"] = tasks
    return jsonify(user)

@app.route('/api/transactions', methods=['POST'])
def add_transaction():
    data = request.json
    user_id = data.get('user_id')
    amount = data.get('amount')
    
    round_up = round(math.ceil(amount) - amount, 2)
    if round_up == 0: round_up = 1.00
        
    transactions_col.insert_one({"user_id": user_id, "amount": amount, "round_up": round_up})
    users_col.update_one({"user_id": user_id}, {"$inc": {"total_saved": round_up}})
    
    return jsonify({"message": "Transaction processed!", "round_up_added": round_up})

@app.route('/api/tasks', methods=['POST'])
def create_task():
    data = request.json
    new_task = {
        "task_id": str(uuid.uuid4()),
        "user_id": data.get('user_id'),
        "title": data.get('title'),
        "sponsor": data.get('sponsor', 'Mom'),
        "reward": data.get('reward', 0.0),
        "status": "pending"
    }
    tasks_col.insert_one(new_task)
    del new_task['_id']
    return jsonify({"message": "Task created!", "task": new_task})

@app.route('/api/tasks/<task_id>/complete', methods=['POST'])
def complete_task(task_id):
    task = tasks_col.find_one_and_update(
        {"task_id": task_id},
        {"$set": {"status": "completed"}}
    )
    if not task:
        return jsonify({"error": "Task not found"}), 404
        
    users_col.update_one({"user_id": task.get('user_id')}, {"$inc": {"total_saved": task.get('reward', 0.0)}})
    return jsonify({"message": f"Task completed!"})

if __name__ == '__main__':
    # Vultr 배포를 위해 0.0.0.0 유지!
    app.run(host='0.0.0.0', debug=True, port=80)