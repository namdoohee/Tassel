# test.py (맥북에서 실행)
import requests

url = "http://127.0.0.1//upload_transactions"
headers = {"user-id": "1"}

# 맥북에 있는 테스트용 이미지 경로를 적으세요
files = {"image": open("Bankstatement_example2.png", "rb")}

print("AI 분석 중... 잠시만 기다려주세요 🤖")
response = requests.post(url, headers=headers, files=files)
print(response.request.headers)

print("상태 코드:", response.status_code)
print("결과:", response.json())