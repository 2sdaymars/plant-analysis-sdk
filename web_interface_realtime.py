#!/usr/bin/env python3
"""
Plant Analysis SDK - 실시간 웹 인터페이스
실시간 카메라 스트리밍 및 식물 모니터링 대시보드
"""

from flask import Flask, render_template_string, Response, jsonify, request
import cv2
import json
import threading
import time
from datetime import datetime
import os
import base64
from pathlib import Path

app = Flask(__name__)

# 글로벌 카메라 객체
camera = None
camera_lock = threading.Lock()

class PlantCamera:
    """라즈베리파이 카메라 스트리밍 클래스"""
    
    def __init__(self):
        self.camera = None
        self.init_camera()
        
    def init_camera(self):
        """카메라 초기화"""
        try:
            # 라즈베리파이 카메라 시도
            self.camera = cv2.VideoCapture(0)
            if not self.camera.isOpened():
                print("❌ 카메라 초기화 실패")
                return False
                
            # 카메라 설정
            self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
            self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
            self.camera.set(cv2.CAP_PROP_FPS, 15)
            
            print("✅ 카메라 초기화 성공")
            return True
        except Exception as e:
            print(f"❌ 카메라 오류: {e}")
            return False
    
    def get_frame(self):
        """프레임 가져오기"""
        if not self.camera or not self.camera.isOpened():
            return None
            
        ret, frame = self.camera.read()
        if ret:
            return frame
        return None
    
    def generate_stream(self):
        """MJPEG 스트림 생성"""
        while True:
            frame = self.get_frame()
            if frame is not None:
                # JPEG 인코딩
                _, buffer = cv2.imencode('.jpg', frame)
                frame_bytes = buffer.tobytes()
                
                # MJPEG 형식으로 전송
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
            else:
                time.sleep(0.1)
    
    def capture_image(self, filename=None):
        """이미지 촬영"""
        frame = self.get_frame()
        if frame is not None:
            if filename is None:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"capture_{timestamp}.jpg"
            
            # 저장 경로
            save_path = Path.home() / "plant_monitoring" / "data" / filename
            save_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 이미지 저장
            cv2.imwrite(str(save_path), frame)
            return str(save_path)
        return None

# 글로벌 카메라 인스턴스
plant_camera = PlantCamera()

# HTML 템플릿 (실시간 스트리밍 포함)
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🌱 Plant Analysis SDK - 실시간 모니터링</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #2E8B57, #3CB371);
            min-height: 100vh;
            color: white;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header {
            text-align: center;
            margin-bottom: 30px;
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .dashboard {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        .camera-section {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .controls-section {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .camera-stream {
            width: 100%;
            max-width: 640px;
            border-radius: 10px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        .btn {
            background: #FF6B6B;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            margin: 5px;
            font-size: 16px;
            transition: all 0.3s ease;
        }
        .btn:hover { background: #FF5252; transform: translateY(-2px); }
        .btn-success { background: #4CAF50; }
        .btn-success:hover { background: #45a049; }
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        .status-card {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .status-online { border-left: 5px solid #4CAF50; }
        .status-info { border-left: 5px solid #2196F3; }
        h1 { font-size: 2.5em; margin-bottom: 10px; }
        h2 { color: #FFE082; margin-bottom: 15px; }
        h3 { color: #FFECB3; margin-bottom: 10px; }
        .timestamp { 
            opacity: 0.8; 
            font-size: 0.9em;
            background: rgba(0,0,0,0.2);
            padding: 5px 10px;
            border-radius: 20px;
            display: inline-block;
        }
        #captureResult {
            margin-top: 10px;
            padding: 10px;
            border-radius: 5px;
            display: none;
        }
        .success { background: rgba(76, 175, 80, 0.3); }
        .error { background: rgba(244, 67, 54, 0.3); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌱 Plant Analysis SDK</h1>
            <p>실시간 식물 모니터링 시스템</p>
            <div class="timestamp">
                마지막 업데이트: <span id="currentTime">{{ timestamp }}</span>
            </div>
        </div>

        <div class="dashboard">
            <div class="camera-section">
                <h2>📷 실시간 카메라</h2>
                <img src="/video_feed" class="camera-stream" alt="실시간 카메라 스트림">
                <div style="margin-top: 15px;">
                    <button class="btn btn-success" onclick="captureImage()">📸 이미지 촬영</button>
                    <button class="btn" onclick="toggleFullscreen()">🔍 전체화면</button>
                </div>
                <div id="captureResult"></div>
            </div>

            <div class="controls-section">
                <h2>🎛️ 제어판</h2>
                
                <div style="margin-bottom: 20px;">
                    <button class="btn btn-success" onclick="startMonitoring()">▶️ 모니터링 시작</button>
                    <button class="btn" onclick="stopMonitoring()">⏹️ 정지</button>
                </div>
                
                <h3>⚙️ 설정</h3>
                <div style="margin-bottom: 10px;">
                    <label>촬영 간격 (분): </label>
                    <select id="intervalSelect">
                        <option value="1">1분</option>
                        <option value="5">5분</option>
                        <option value="15" selected>15분</option>
                        <option value="30">30분</option>
                        <option value="60">1시간</option>
                    </select>
                </div>
                
                <div style="margin-bottom: 20px;">
                    <input type="text" id="plantName" placeholder="식물 이름" style="padding: 8px; width: 100%; border: none; border-radius: 5px;">
                </div>
                
                <h3>📊 최근 활동</h3>
                <div id="recentActivity" style="font-size: 0.9em;">
                    <p>✅ 시스템 정상 작동 중</p>
                    <p>📷 마지막 촬영: 방금 전</p>
                </div>
            </div>
        </div>

        <div class="status-grid">
            <div class="status-card status-online">
                <h3>✅ 시스템 상태</h3>
                <p><strong>상태:</strong> <span style="color: #4CAF50;">온라인</span></p>
                <p><strong>가동시간:</strong> <span id="uptime">계산 중...</span></p>
            </div>
            
            <div class="status-card status-info">
                <h3>📊 통계</h3>
                <p><strong>총 촬영:</strong> <span id="totalCaptures">0</span>장</p>
                <p><strong>저장 공간:</strong> <span id="storage">확인 중...</span></p>
            </div>
            
            <div class="status-card status-info">
                <h3>🔧 시스템 정보</h3>
                <p><strong>Python:</strong> {{ python_version[:6] }}</p>
                <p><strong>카메라:</strong> <span id="cameraStatus">활성화</span></p>
            </div>
        </div>
    </div>

    <script>
        // 실시간 시간 업데이트
        function updateTime() {
            const now = new Date();
            document.getElementById('currentTime').textContent = 
                now.toLocaleString('ko-KR');
        }
        setInterval(updateTime, 1000);

        // 이미지 촬영
        function captureImage() {
            const plantName = document.getElementById('plantName').value || 'unnamed';
            
            fetch('/api/capture', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({plant_name: plantName})
            })
            .then(response => response.json())
            .then(data => {
                const resultDiv = document.getElementById('captureResult');
                if (data.success) {
                    resultDiv.className = 'success';
                    resultDiv.textContent = `✅ 촬영 완료: ${data.filename}`;
                } else {
                    resultDiv.className = 'error';
                    resultDiv.textContent = `❌ 촬영 실패: ${data.error}`;
                }
                resultDiv.style.display = 'block';
                setTimeout(() => resultDiv.style.display = 'none', 3000);
            });
        }

        // 전체화면 토글
        function toggleFullscreen() {
            const img = document.querySelector('.camera-stream');
            if (img.requestFullscreen) {
                img.requestFullscreen();
            }
        }

        // 모니터링 제어
        function startMonitoring() {
            alert('자동 모니터링이 시작되었습니다!');
        }

        function stopMonitoring() {
            alert('모니터링이 정지되었습니다.');
        }

        // 초기 로드
        updateTime();
    </script>
</body>
</html>
"""

@app.route('/')
def home():
    """메인 페이지"""
    import sys
    return render_template_string(HTML_TEMPLATE,
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        python_version=sys.version
    )

@app.route('/video_feed')
def video_feed():
    """실시간 비디오 스트림"""
    return Response(plant_camera.generate_stream(),
                   mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/api/capture', methods=['POST'])
def api_capture():
    """이미지 촬영 API"""
    try:
        data = request.get_json() or {}
        plant_name = data.get('plant_name', 'unnamed')
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{plant_name}_{timestamp}.jpg"
        
        saved_path = plant_camera.capture_image(filename)
        
        if saved_path:
            return jsonify({
                'success': True,
                'filename': filename,
                'path': saved_path,
                'timestamp': timestamp
            })
        else:
            return jsonify({
                'success': False,
                'error': '카메라에서 이미지를 가져올 수 없습니다'
            })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })

@app.route('/api/status')
def api_status():
    """시스템 상태 API"""
    return jsonify({
        'status': 'online',
        'timestamp': datetime.now().isoformat(),
        'camera_active': plant_camera.camera is not None,
        'uptime': 'Active'
    })

if __name__ == '__main__':
    print("🌱 Plant Analysis SDK 실시간 웹 인터페이스 시작")
    print("📱 브라우저에서 접속하세요:")
    print("   로컬: http://localhost:5000")
    print("   네트워크: http://[라즈베리파이IP]:5000")
    print("📷 실시간 카메라 스트리밍 지원!")
    
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)