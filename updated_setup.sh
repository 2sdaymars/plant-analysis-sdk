#!/bin/bash

# 개선된 라즈베리파이 식물 분석 SDK 설치 스크립트
# 원본 이미지 보존 중심의 모니터링 시스템

set -e

echo "=== 개선된 라즈베리파이 식물 분석 SDK 설치 시작 ==="
echo "설치 시간: $(date)"

# 로그 파일 생성
LOG_FILE="/home/pi/plant_analysis_install.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "1단계: 시스템 업데이트..."
apt update && apt upgrade -y

echo "2단계: 기본 개발 도구 설치..."
apt install -y python3 python3-pip python3-venv python3-dev build-essential cmake git wget curl

echo "3단계: 카메라 및 이미지 처리 라이브러리 설치..."
apt install -y libcamera-apps libcamera-dev python3-picamera2
apt install -y libopencv-dev python3-opencv libatlas-base-dev libjpeg-dev libtiff5-dev libpng-dev
apt install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev

echo "4단계: Python 가상환경 설정..."
cd /home/pi
python3 -m venv plant_analysis_env
source plant_analysis_env/bin/activate

echo "5단계: Python 패키지 설치..."
pip install --upgrade pip

# 핵심 과학 계산 패키지
pip install numpy scipy matplotlib pandas

# 컴퓨터 비전 패키지
pip install opencv-python

# 식물 분석 전용 라이브러리
pip install plantcv

# 머신러닝 라이브러리
pip install scikit-learn

# 이미지 처리 도구
pip install Pillow scikit-image

# 데이터 시각화
pip install seaborn plotly

# 웹 개발 환경
pip install jupyter ipython

# 스케줄링 라이브러리 추가
pip install schedule

echo "6단계: 모니터링 시스템 디렉토리 생성..."
mkdir -p /home/pi/plant_monitoring
cd /home/pi/plant_monitoring

echo "7단계: 시스템 파일 생성..."

# 메인 모니터링 시스템 파일 생성
cat > plant_monitoring_system.py << 'EOF'
#!/usr/bin/env python3
"""
라즈베리파이 식물 모니터링 시스템
- 원본 이미지 중심 저장
- 식물별/시간별 체계적 분류
- 분석 데이터와 원본 이미지 분리
"""

import cv2
import numpy as np
import os
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

class PlantMonitoringSystem:
    def __init__(self, base_path: str = "/home/pi/plant_monitoring"):
        self.base_path = Path(base_path)
        self.setup_directory_structure()
        self.config_file = self.base_path / "config.json"
        self.load_config()
    
    def setup_directory_structure(self):
        """디렉토리 구조 생성"""
        directories = [
            "raw_images/plants",  # 식물별 원본 이미지
            "analysis/processed", # 처리된 이미지  
            "analysis/data",      # 분석 데이터
            "metadata",          # 메타데이터
            "logs",             # 로그
            "temp"              # 임시 파일
        ]
        
        for directory in directories:
            (self.base_path / directory).mkdir(parents=True, exist_ok=True)
    
    def load_config(self):
        """설정 로드"""
        default_config = {
            "plants": {},
            "camera_settings": {"width": 1920, "height": 1080, "quality": 95},
            "monitoring": {"interval_minutes": 60, "auto_analysis": True}
        }
        
        if self.config_file.exists():
            with open(self.config_file, 'r') as f:
                self.config = json.load(f)
        else:
            self.config = default_config
            self.save_config()
    
    def save_config(self):
        """설정 저장"""
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def register_plant(self, plant_name: str) -> str:
        """식물 등록"""
        plant_id = plant_name.lower().replace(' ', '_')
        
        # 식물별 디렉토리 생성
        plant_dir = self.base_path / "raw_images" / "plants" / plant_id
        plant_dir.mkdir(parents=True, exist_ok=True)
        
        # 식물 정보 저장
        self.config["plants"][plant_id] = {
            "name": plant_name,
            "id": plant_id,
            "registered_date": datetime.now().isoformat(),
            "image_count": 0
        }
        self.save_config()
        
        print(f"🌱 식물 등록: {plant_name} (ID: {plant_id})")
        return plant_id
    
    def capture_image(self, plant_id: str = None, notes: str = "") -> Optional[Dict]:
        """이미지 촬영 및 저장"""
        print("📸 이미지 촬영 중...")
        
        # 카메라 초기화
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            print("❌ 카메라 연결 실패")
            return None
        
        # 카메라 설정
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.config["camera_settings"]["width"])
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.config["camera_settings"]["height"])
        
        # 촬영
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            print("❌ 촬영 실패")
            return None
        
        # 저장 경로 및 파일명 생성
        timestamp = datetime.now()
        time_str = timestamp.strftime("%Y%m%d_%H%M%S")
        
        if plant_id and plant_id in self.config["plants"]:
            save_dir = self.base_path / "raw_images" / "plants" / plant_id / timestamp.strftime("%Y") / timestamp.strftime("%m")
            filename = f"{plant_id}_{time_str}.jpg"
        else:
            save_dir = self.base_path / "raw_images" / timestamp.strftime("%Y") / timestamp.strftime("%m")
            filename = f"capture_{time_str}.jpg"
        
        save_dir.mkdir(parents=True, exist_ok=True)
        image_path = save_dir / filename
        
        # 고품질 저장
        cv2.imwrite(str(image_path), frame, [cv2.IMWRITE_JPEG_QUALITY, self.config["camera_settings"]["quality"]])
        
        # 메타데이터 생성
        metadata = {
            "filename": filename,
            "path": str(image_path.relative_to(self.base_path)),
            "plant_id": plant_id,
            "capture_time": timestamp.isoformat(),
            "notes": notes,
            "image_properties": {
                "width": frame.shape[1],
                "height": frame.shape[0],
                "size_bytes": image_path.stat().st_size
            }
        }
        
        # 메타데이터 저장
        metadata_path = self.base_path / "metadata" / f"{time_str}_metadata.json"
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        # 설정 업데이트
        if plant_id and plant_id in self.config["plants"]:
            self.config["plants"][plant_id]["image_count"] += 1
            self.save_config()
        
        print(f"✅ 저장 완료: {image_path}")
        
        # 자동 분석
        if self.config["monitoring"]["auto_analysis"]:
            self.analyze_image(str(image_path), metadata)
        
        return metadata
    
    def analyze_image(self, image_path: str, metadata: Dict = None):
        """이미지 분석 (원본 보존)"""
        print(f"🔍 분석 중: {Path(image_path).name}")
        
        img = cv2.imread(image_path)
        if img is None:
            return None
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        analysis_dir = self.base_path / "analysis" / "data"
        analysis_dir.mkdir(parents=True, exist_ok=True)
        
        # 기본 분석
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 녹색 영역 분석
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        lower_green = np.array([35, 40, 40])
        upper_green = np.array([85, 255, 255])
        green_mask = cv2.inRange(hsv, lower_green, upper_green)
        
        green_pixels = np.sum(green_mask > 0)
        total_pixels = img.shape[0] * img.shape[1]
        
        analysis_result = {
            "original_image": image_path,
            "analysis_time": datetime.now().isoformat(),
            "metadata": metadata,
            "analysis": {
                "brightness": {"mean": float(np.mean(gray)), "std": float(np.std(gray))},
                "green_coverage": float(green_pixels / total_pixels * 100),
                "plant_detected": green_pixels / total_pixels > 0.05
            }
        }
        
        # 분석 결과 저장
        analysis_file = analysis_dir / f"analysis_{timestamp}.json"
        with open(analysis_file, 'w') as f:
            json.dump(analysis_result, f, indent=2)
        
        print(f"✅ 분석 완료: 식물 {'감지됨' if analysis_result['analysis']['plant_detected'] else '미감지'}")
        return analysis_result

# 간단한 사용 예시
if __name__ == "__main__":
    monitor = PlantMonitoringSystem()
    
    print("🌱 식물 모니터링 시스템 테스트")
    plant_id = monitor.register_plant("테스트 식물")
    result = monitor.capture_image(plant_id, "테스트 촬영")
    
    if result:
        print("✅ 테스트 완료!")
EOF

# 자동화 모니터링 스크립트
cat > automated_monitoring.py << 'EOF'
#!/usr/bin/env python3
"""자동화 식물 모니터링"""

import schedule
import time
import threading
from datetime import datetime
from plant_monitoring_system import PlantMonitoringSystem
import logging

class AutomatedPlantMonitor:
    def __init__(self):
        self.monitoring_system = PlantMonitoringSystem()
        self.is_running = False
        self.setup_logging()
    
    def setup_logging(self):
        log_dir = self.monitoring_system.base_path / "logs"
        log_file = log_dir / f"monitoring_{datetime.now().strftime('%Y%m%d')}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def scheduled_capture(self):
        """스케줄된 촬영"""
        self.logger.info("🚀 자동 촬영 시작")
        
        plants = list(self.monitoring_system.config["plants"].keys())
        if not plants:
            self.logger.info("일반 촬영 실행")
            self.monitoring_system.capture_image(None, "자동 촬영")
            return
        
        for plant_id in plants:
            result = self.monitoring_system.capture_image(plant_id, "자동 촬영")
            if result:
                self.logger.info(f"촬영 성공: {plant_id}")
            time.sleep(2)
    
    def start_monitoring(self, interval_minutes=60):
        """모니터링 시작"""
        if self.is_running:
            return
        
        self.is_running = True
        schedule.every(interval_minutes).minutes.do(self.scheduled_capture)
        
        def run_scheduler():
            while self.is_running:
                schedule.run_pending()
                time.sleep(60)
        
        self.scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
        self.scheduler_thread.start()
        
        self.logger.info(f"🚀 자동 모니터링 시작 - {interval_minutes}분 간격")
    
    def stop_monitoring(self):
        """모니터링 중지"""
        self.is_running = False
        schedule.clear()
        self.logger.info("🛑 모니터링 중지")

if __name__ == "__main__":
    monitor = AutomatedPlantMonitor()
    
    try:
        monitor.start_monitoring(60)  # 60분 간격
        print("자동 모니터링이 시작되었습니다. Ctrl+C로 중지하세요.")
        
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        monitor.stop_monitoring()
        print("\n모니터링을 중지했습니다.")
EOF

# 시작 스크립트
cat > start_monitoring.sh << 'EOF'
#!/bin/bash
echo "🌱 식물 모니터링 시스템 시작"

# 가상환경 활성화
source /home/pi/plant_analysis_env/bin/activate

# 모니터링 디렉토리로 이동
cd /home/pi/plant_monitoring

echo "사용 가능한 명령어:"
echo "1. python3 plant_monitoring_system.py  - 수동 모니터링"
echo "2. python3 automated_monitoring.py     - 자동 모니터링" 
echo ""
echo "✅ 환경이 준비되었습니다!"
EOF

# README 파일
cat > README.txt << 'EOF'
🌱 개선된 식물 모니터링 시스템

이 시스템의 주요 개선사항:

✅ 원본 이미지 중심 저장
- raw_images/ : 절대 건드리지 않는 원본 이미지
- 식물별, 년/월별 체계적 분류

✅ 분석 데이터 분리
- analysis/data/ : JSON 형태 분석 결과
- analysis/processed/ : 처리된 이미지 (선택적)

✅ 확장 가능한 구조
- metadata/ : 모든 촬영 메타데이터
- logs/ : 시스템 로그
- 나중에 다른 분석 방법 적용 가능

🚀 사용법:
1. source start_monitoring.sh
2. 식물 등록 및 촬영
3. 자동 모니터링 시작

📁 디렉토리 구조:
/home/pi/plant_monitoring/
├── raw_images/          # 원본 이미지 (보존)
│   └── plants/         # 식물별 분류
│       └── plant_id/   # YYYY/MM 구조
├── analysis/           # 분석 결과
│   ├── data/          # JSON 데이터
│   └── processed/     # 처리 이미지
├── metadata/          # 메타데이터
└── logs/             # 로그 파일
EOF

echo "8단계: 실행 권한 부여..."
chmod +x plant_monitoring_system.py
chmod +x automated_monitoring.py  
chmod +x start_monitoring.sh

echo "9단계: 권한 설정..."
chown -R pi:pi /home/pi/plant_monitoring
chown -R pi:pi /home/pi/plant_analysis_env

echo "10단계: Jupyter 설정..."
sudo -u pi jupyter notebook --generate-config
echo "c.NotebookApp.ip = '0.0.0.0'" >> /home/pi/.jupyter/jupyter_notebook_config.py
echo "c.NotebookApp.port = 8888" >> /home/pi/.jupyter/jupyter_notebook_config.py
echo "c.NotebookApp.open_browser = False" >> /home/pi/.jupyter/jupyter_notebook_config.py

echo ""
echo "=== 설치 완료! ==="
echo ""
echo "🎉 개선된 식물 모니터링 시스템이 설치되었습니다!"
echo ""
echo "주요 개선사항:"
echo "✅ 원본 이미지 보존 중심 설계"  
echo "✅ 식물별/시간별 체계적 분류"
echo "✅ 분석 데이터와 원본 분리"
echo "✅ 확장 가능한 모니터링 시스템"
echo ""
echo "시작 방법:"
echo "1. sudo reboot (재부팅)"
echo "2. cd /home/pi/plant_monitoring"
echo "3. source start_monitoring.sh"
echo ""