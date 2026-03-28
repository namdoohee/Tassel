import math
import uuid
from flask import Flask, jsonify, request
from flask_cors import CORS
# db.py가 같은 폴더에 있어야 해!
from db import users_col, tasks_col, transactions_col 
from google import genai
from PIL import Image
import os
import io
import json
from dotenv import load_dotenv

app = Flask(__name__)
load_dotenv()
CORS(app)

# 1. 최신 방식의 Client 설정
client = genai.Client(api_key=os.getenv("GEMINI_KEY"))

@app.route('/', methods=['GET'])
def home():
    return "<h1>Tassel Server is Online! 🚀</h1>"

# ... (기존 api/status, api/transactions, api/tasks 코드는 동일하므로 생략) ...

@app.route('/upload_transactions', methods=['POST'])
def upload_transactions():
    print(request.headers)
    user_id = request.headers.get('user_id')
    
    # 1. 파일 및 유저 ID 체크
    
    print(request.files)
    if not user_id or 'image' not in request.files:
        return jsonify({"error": "Missing user_id or image"}), 400
        
    file = request.files['image']
    # 이미지를 Gemini가 읽을 수 있는 객체로 변환
    image = Image.open(io.BytesIO(file.read()))

    # 2. 새로운 프롬프트 (정확한 JSON 출력을 유도)
    prompt = """
    Analyze this bank statement. 
    1. Identify all negative amounts (money spent/used by the user).
    2. For each spent amount, calculate the rounded-up value to the nearest $5. 
       (e.g., 16.85 -> 20.00, 1.10 -> 5.00, 15.00 -> 15.00)
    3. Return ONLY a JSON object with this structure:
    {
      "individual_rounded_values": [list of numbers],
      "sum_of_rounded_values": number
    }
    Do not include any text or markdown blocks.
    """

    try:
        # 3. 최신 SDK 호출 방식 (client.models.generate_content)
        response = client.models.generate_content(
            model="gemini-1.5-flash",
            contents=[image, prompt]
        )
        
        # 4. 결과 텍스트 클리닝 및 파싱
        clean_text = response.text.strip().replace('```json', '').replace('```', '').strip()
        data = json.loads(clean_text)
        
        rounded_total = data.get("sum_of_rounded_values", 0.0)
        transaction_id = str(uuid.uuid4())[:8]

        # 5. MongoDB 저장 (실제 서비스라면 여기서 기록을 남겨야 함)
        # transactions_col.insert_one({"user_id": user_id, "id": transaction_id, "amount": rounded_total})

        return jsonify({
            "transaction_id": transaction_id,
            "total_value": round(rounded_total, 2),
            "rounded_value": round(rounded_total, 2)
        }), 200

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"error": "AI processing failed", "details": str(e)}), 500
    
if __name__ == '__main__':
    # 해커톤 배포 환경에 맞춰 실행
    app.run(host='0.0.0.0', debug=True, port=80)