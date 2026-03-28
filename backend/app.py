from flask import Flask, jsonify
from flask_cors import CORS
from db import users_col, tasks_col, transactions_col # db.py에서 연결된 컬렉션 가져오기

app = Flask(__name__)
CORS(app) # 프론트엔드 접속 허용

# 서버가 잘 돌아가는지 확인하는 기본 라우트
@app.route('/', methods=['GET'])
def home():
    return jsonify({"message": "Tassel Backend is running! 🚀"})

# 다음 스텝에서 여기에 프론트엔드용 API들을 추가할 겁니다!

if __name__ == '__main__':
    # port 5000번에서 서버 실행
    app.run(debug=True, port=5000)