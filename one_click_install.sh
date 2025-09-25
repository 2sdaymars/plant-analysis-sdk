#!/bin/bash

# 🌱 식물 분석 SDK 원클릭 설치 스크립트
# CinePI처럼 간단하게 사용할 수 있도록 만들어진 스크립트

set -e

echo "🌱 식물 분석 SDK 원클릭 설치"
echo "================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 진행률 표시 함수
show_progress() {
    local current=$1
    local total=$2
    local desc=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    
    printf "\r${BLUE}["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=filled; i<50; i++)); do printf "░"; done
    printf "] %d%% - %s${NC}" "$percent" "$desc"
}

echo -e "${GREEN}이 스크립트는 다음을 자동으로 설치합니다:${NC}"
echo "✅ Python 3.x + 가상환경"
echo "✅ PlantCV (식물 분석 라이브러리)"
echo "✅ OpenCV + 컴퓨터 비전 도구들"
echo "✅ 자동 모니터링 시스템"
echo "✅ 웹 기반 Jupyter Notebook"
echo ""
echo -e "${YELLOW}예상 설치 시간: 15-25분${NC}"
echo -e "${YELLOW}인터넷 연결 필요, 약 500MB 다운로드${NC}"
echo ""

read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "설치를 취소했습니다."
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 설치를 시작합니다...${NC}"

# 로그 파일 설정
LOG_FILE="/home/pi/plant_sdk_install_$(date +%Y%m%d_%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

TOTAL_STEPS=10
CURRENT_STEP=0

# 1단계: 시스템 업데이트
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "시스템 업데이트 중..."
apt update -qq && apt upgrade -qq -y

# 2단계: 기본 도구 설치
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "기본 개발 도구 설치 중..."
apt install -qq -y python3 python3-pip python3-venv python3-dev build-essential cmake git wget curl

# 3단계: 카메라 라이브러리
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "카메라 라이브러리 설치 중..."
apt install -qq -y libcamera-apps libcamera-dev python3-picamera2

# 4단계: 이미지 처리 라이브러리
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "이미지 처리 라이브러리 설치 중..."
apt install -qq -y libopencv-dev python3-opencv libatlas-base-dev libjpeg-dev libtiff5-dev libpng-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev

# 5단계: Python 가상환경 생성
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "Python 가상환경 생성 중..."
cd /home/pi
if [ -d "plant_analysis_env" ]; then
    rm -rf plant_analysis_env
fi
python3 -m venv plant_analysis_env
source plant_analysis_env/bin/activate

# 6단계: Python 패키지 설치
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "Python 패키지 설치 중..."
pip install -q --upgrade pip
pip install -q numpy scipy matplotlib pandas opencv-python plantcv scikit-learn Pillow scikit-image seaborn plotly jupyter ipython schedule

# 7단계: 모니터링 시스템 생성
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "모니터링 시스템 생성 중..."
mkdir -p /home/pi/plant_monitoring
cd /home/pi/plant_monitoring

# 핵심 모니터링 시스템 파일 생성
cat > plant_monitoring_system.py << 'EOF'
#!/usr/bin/env python3
import cv2
import numpy as np
import json
from datetime import datetime
from pathlib import Path

class QuickPlantMonitor:
    def __init__(self):
        self.base_path = Path("/home/pi/plant_monitoring")
        self.setup_dirs()
        
    def setup_dirs(self):
        for d in ["raw_images", "analysis", "plants"]:
            (self.base_path / d).mkdir(exist_ok=True)
    
    def capture_and_analyze(self, plant_name=""):
        print("📸 촬영 중...")
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            print("❌ 카메라 연결 실패")
            return
        
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            print("❌ 촬영 실패") 
            return
            
        # 파일명 생성
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        if plant_name:
            filename = f"{plant_name}_{timestamp}.jpg"
            save_path = self.base_path / "plants" / plant_name
        else:
            filename = f"capture_{timestamp}.jpg"
            save_path = self.base_path / "raw_images"
        
        save_path.mkdir(exist_ok=True)
        image_path = save_path / filename
        
        # 고화질 저장
        cv2.imwrite(str(image_path), frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
        
        # 간단한 분석
        self.analyze_image(frame, str(image_path))
        
        print(f"✅ 저장 완료: {image_path}")
        return str(image_path)
    
    def analyze_image(self, frame, path):
        # 녹색 영역 분석
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        lower_green = np.array([35, 40, 40])
        upper_green = np.array([85, 255, 255])
        mask = cv2.inRange(hsv, lower_green, upper_green)
        
        green_ratio = (np.sum(mask > 0) / mask.size) * 100
        
        result = {
            "path": path,
            "timestamp": datetime.now().isoformat(),
            "green_coverage": green_ratio,
            "plant_detected": green_ratio > 5
        }
        
        # 결과 저장
        result_path = self.base_path / "analysis" / f"analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(result_path, 'w') as f:
            json.dump(result, f, indent=2)
        
        print(f"🔍 분석 완료: 녹색 비율 {green_ratio:.1f}% {'🌿 식물 감지!' if result['plant_detected'] else '🔍 식물 미감지'}")

def main():
    monitor = QuickPlantMonitor()
    
    print("🌱 빠른 식물 모니터링 시스템")
    print("=" * 40)
    print("1. 일반 촬영")
    print("2. 식물별 촬영")
    print("3. 자동 모니터링 (1분마다)")
    print("0. 종료")
    
    while True:
        choice = input("\n선택: ")
        
        if choice == "1":
            monitor.capture_and_analyze()
        elif choice == "2":
            plant_name = input("식물 이름: ").strip().replace(' ', '_')
            if plant_name:
                monitor.capture_and_analyze(plant_name)
        elif choice == "3":
            print("자동 모니터링 시작... (Ctrl+C로 중지)")
            try:
                import time
                while True:
                    monitor.capture_and_analyze("auto_monitoring")
                    time.sleep(60)  # 1분 대기
            except KeyboardInterrupt:
                print("\n자동 모니터링을 중지했습니다.")
        elif choice == "0":
            break
        else:
            print("잘못된 선택입니다.")

if __name__ == "__main__":
    main()
EOF

# 8단계: 시작 스크립트 생성
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "시작 스크립트 생성 중..."

cat > start_plant_sdk.sh << 'EOF'
#!/bin/bash

echo "🌱 식물 분석 SDK v1.0"
echo "====================="
echo ""

# 가상환경 활성화
source /home/pi/plant_analysis_env/bin/activate
cd /home/pi/plant_monitoring

echo "✅ 환경이 준비되었습니다!"
echo ""
echo "🚀 빠른 시작:"
echo "  python3 plant_monitoring_system.py  - 메인 프로그램"
echo ""
echo "🌐 고급 기능:"
echo "  jupyter notebook                    - 웹 기반 분석 (포트 8888)"
echo ""
echo "📁 저장된 파일들:"
echo "  raw_images/     - 원본 사진들"
echo "  plants/         - 식물별 분류" 
echo "  analysis/       - 분석 결과들"
echo ""

# 바로 실행할지 물어보기
read -p "지금 바로 시작하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    python3 plant_monitoring_system.py
fi
EOF

chmod +x *.py *.sh

# 9단계: 설정 및 권한
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "시스템 설정 중..."

# 권한 설정
chown -R pi:pi /home/pi/plant_analysis_env
chown -R pi:pi /home/pi/plant_monitoring

# Jupyter 설정
sudo -u pi jupyter notebook --generate-config 2>/dev/null || true
echo "c.NotebookApp.ip = '0.0.0.0'" >> /home/pi/.jupyter/jupyter_notebook_config.py 2>/dev/null || true
echo "c.NotebookApp.port = 8888" >> /home/pi/.jupyter/jupyter_notebook_config.py 2>/dev/null || true
echo "c.NotebookApp.open_browser = False" >> /home/pi/.jupyter/jupyter_notebook_config.py 2>/dev/null || true

# 카메라 활성화
if ! grep -q "camera_auto_detect=1" /boot/config.txt; then
    echo "camera_auto_detect=1" >> /boot/config.txt
fi

# 시작 시 안내 메시지
if ! grep -q "식물 분석 SDK" /home/pi/.bashrc; then
    cat >> /home/pi/.bashrc << 'BASHEOF'

# 식물 분석 SDK 안내
echo ""
echo "🌱 식물 분석 SDK가 설치되어 있습니다!"
echo "시작: cd /home/pi/plant_monitoring && source start_plant_sdk.sh"
echo ""
BASHEOF
fi

# 10단계: 정리
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS "설치 완료 및 정리 중..."

# 시스템 정리
apt autoremove -qq -y
apt autoclean -qq

# 완료 표시 파일
echo "PLANT_SDK_INSTALLED_$(date +%Y%m%d_%H%M%S)" > /home/pi/.plant_sdk_ready

echo ""
echo ""
echo -e "${GREEN}🎉 설치가 완료되었습니다!${NC}"
echo ""
echo -e "${BLUE}📋 설치된 내용:${NC}"
echo "  ✅ 식물 분석 환경"
echo "  ✅ 카메라 모니터링 시스템" 
echo "  ✅ 자동화 도구들"
echo "  ✅ 웹 기반 분석 환경"
echo ""
echo -e "${YELLOW}🚀 시작 방법:${NC}"
echo "  cd /home/pi/plant_monitoring"
echo "  source start_plant_sdk.sh"
echo ""
echo -e "${BLUE}💡 추가 정보:${NC}"
echo "  📁 로그 파일: $LOG_FILE"
echo "  🌐 웹 접속: http://$(hostname -I | awk '{print $1}'):8888"
echo "  📞 문제 발생시: GitHub Issues"
echo ""

# 재부팅 권장
echo -e "${YELLOW}⚠️ 카메라 사용을 위해 재부팅을 권장합니다.${NC}"
read -p "지금 재부팅하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "재부팅 중..."
    sleep 2
    reboot
fi