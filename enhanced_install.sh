#!/bin/bash

# 🌱 Plant Analysis SDK 개선된 설치 스크립트
# 라즈베리파이용 완전 자동 설치

# 기본 설정
IMAGE_MODE=false
NON_INTERACTIVE=false

# 명령행 인자 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --image-mode)
            IMAGE_MODE=true
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            echo "사용법: $0 [옵션]"
            echo "옵션:"
            echo "  --image-mode       이미지 빌드 모드 (chroot 환경)"
            echo "  --non-interactive  대화형 입력 없이 자동 설치"
            echo "  -h, --help        도움말 표시"
            exit 0
            ;;
        *)
            echo "알 수 없는 옵션: $1"
            exit 1
            ;;
    esac
done

echo "🌱 Plant Analysis SDK 설치를 시작합니다..."
echo "=========================================="
if [ "$IMAGE_MODE" = true ]; then
    echo "📦 이미지 빌드 모드로 실행 중..."
fi
if [ "$NON_INTERACTIVE" = true ]; then
    echo "🤖 비대화형 모드로 실행 중..."
fi

# 에러 발생시 스크립트 중단
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수들
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 시스템 정보 확인
log_info "시스템 정보 확인 중..."
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Python: $(python3 --version)"
echo "Architecture: $(uname -m)"

# 라즈베리파이 확인
if [[ $(uname -m) == "aarch64" || $(uname -m) == "armv7l" ]]; then
    log_success "라즈베리파이 환경 감지됨"
else
    log_warning "라즈베리파이가 아닌 환경에서 실행 중입니다"
fi

# 패키지 목록 업데이트
log_info "패키지 목록 업데이트 중..."
sudo apt update

# 필수 시스템 패키지 설치
log_info "필수 시스템 패키지 설치 중..."
sudo apt install -y python3 python3-pip python3-venv python3-dev \
                   build-essential cmake git wget curl \
                   libopencv-dev python3-opencv \
                   libatlas-base-dev libjpeg-dev libpng-dev \
                   libfreetype6-dev pkg-config \
                   htop nano vim

# 라즈베리파이 관련 패키지 (라즈베리파이에서만)
if command -v raspi-config &> /dev/null && [ "$IMAGE_MODE" = false ]; then
    log_info "라즈베리파이 전용 패키지 설치 중..."
    sudo apt install -y libcamera-apps libcamera-dev python3-picamera2 \
                       raspi-config rpi-update
    
    # 카메라 활성화
    log_info "카메라 모듈 활성화 중..."
    sudo raspi-config nonint do_camera 0
    
    # I2C 활성화 (센서용)
    log_info "I2C 활성화 중..."
    sudo raspi-config nonint do_i2c 0
    
    # SPI 활성화
    log_info "SPI 활성화 중..."
    sudo raspi-config nonint do_spi 0
elif [ "$IMAGE_MODE" = true ]; then
    log_info "이미지 모드: 라즈베리파이 설정을 config.txt에 추가..."
    # 이미지 빌드시에는 /boot/config.txt에 직접 설정 추가
    if [ -f "/boot/config.txt" ]; then
        echo "camera_auto_detect=1" >> /boot/config.txt
        echo "dtparam=i2c_arm=on" >> /boot/config.txt
        echo "dtparam=spi=on" >> /boot/config.txt
    fi
fi

# Python 가상환경 생성
log_info "Python 가상환경 생성 중..."
cd $HOME
if [ -d "plant_analysis_env" ]; then
    log_warning "기존 가상환경 발견. 제거 후 재생성..."
    rm -rf plant_analysis_env
fi

python3 -m venv plant_analysis_env
source plant_analysis_env/bin/activate

# pip 업그레이드
log_info "pip 업그레이드 중..."
pip install --upgrade pip setuptools wheel

# 필수 Python 패키지 설치
log_info "Python 패키지 설치 중..."
pip install numpy==1.24.3
pip install scipy matplotlib pandas
pip install opencv-python
pip install scikit-learn
pip install jupyter notebook ipython
pip install schedule
pip install Flask
pip install requests

# Plant-CV 설치 (선택사항)
log_info "PlantCV 설치 시도 중..."
pip install plantcv || log_warning "PlantCV 설치 실패 (선택사항이므로 계속 진행)"

# 프로젝트 디렉토리 생성
log_info "프로젝트 디렉토리 설정 중..."
mkdir -p $HOME/plant_monitoring/{data,logs,config,models}

# 설정 파일 복사 (현재 디렉토리에 있다면)
if [ -f "plant_monitoring_system.py" ]; then
    cp plant_monitoring_system.py $HOME/plant_monitoring/
    log_success "plant_monitoring_system.py 복사 완료"
fi

if [ -f "automated_monitoring.py" ]; then
    cp automated_monitoring.py $HOME/plant_monitoring/
    log_success "automated_monitoring.py 복사 완료"
fi

# 시작 스크립트 생성
log_info "시작 스크립트 생성 중..."
cat > $HOME/plant_monitoring/start_plant_sdk.sh << 'EOF'
#!/bin/bash

# 🌱 Plant Analysis SDK 시작 스크립트
echo "🌱 Plant Analysis SDK v1.0"
echo "========================="

# 가상환경 활성화
source $HOME/plant_analysis_env/bin/activate

# 프로젝트 디렉토리로 이동
cd $HOME/plant_monitoring

# 환경 확인
echo "✅ Python 환경: $(python3 --version)"
echo "✅ 작업 디렉토리: $(pwd)"

# 카메라 확인 (라즈베리파이에서만)
if command -v vcgencmd &> /dev/null; then
    echo "✅ 카메라 상태: $(vcgencmd get_camera)"
fi

echo ""
echo "🚀 사용 가능한 명령어:"
echo "  python3 plant_monitoring_system.py  - 메인 모니터링 시스템 실행"
echo "  python3 automated_monitoring.py     - 자동화 모니터링 실행" 
echo "  jupyter notebook                     - Jupyter 노트북 실행"
echo ""
echo "📂 디렉토리 구조:"
echo "  data/    - 수집된 데이터"
echo "  logs/    - 로그 파일"
echo "  config/  - 설정 파일"
echo "  models/  - 학습된 모델"
echo ""

# 대화형 쉘 시작
exec bash
EOF

chmod +x $HOME/plant_monitoring/start_plant_sdk.sh

# 웹 인터페이스 생성 (간단한 Flask 앱)
log_info "웹 인터페이스 생성 중..."
cat > $HOME/plant_monitoring/web_interface.py << 'EOF'
#!/usr/bin/env python3
"""
🌱 Plant Analysis SDK Web Interface
간단한 웹 인터페이스로 모니터링 시스템 제어
"""

from flask import Flask, render_template_string, jsonify
import os
import json
from datetime import datetime

app = Flask(__name__)

# HTML 템플릿
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>🌱 Plant Analysis SDK</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2d5a27; text-align: center; }
        .status { padding: 15px; margin: 20px 0; border-radius: 5px; }
        .status.online { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .status.offline { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .button { background: #28a745; color: white; padding: 12px 24px; border: none; border-radius: 5px; cursor: pointer; margin: 10px 5px; }
        .button:hover { background: #218838; }
        .info { background: #e9ecef; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌱 Plant Analysis SDK</h1>
        
        <div class="status online">
            <h3>✅ 시스템 상태: 온라인</h3>
            <p>마지막 업데이트: {{ timestamp }}</p>
        </div>
        
        <div class="info">
            <h3>📊 시스템 정보</h3>
            <p><strong>Python 버전:</strong> {{ python_version }}</p>
            <p><strong>작업 디렉토리:</strong> {{ working_dir }}</p>
            <p><strong>가상환경:</strong> {{ venv_active }}</p>
        </div>
        
        <div class="info">
            <h3>🚀 빠른 시작</h3>
            <p>터미널에서 다음 명령어를 사용하세요:</p>
            <ul>
                <li><code>cd ~/plant_monitoring && ./start_plant_sdk.sh</code> - SDK 환경 시작</li>
                <li><code>python3 plant_monitoring_system.py</code> - 메인 시스템 실행</li>
                <li><code>jupyter notebook</code> - 노트북 환경 실행</li>
            </ul>
        </div>
        
        <div class="info">
            <h3>📂 프로젝트 구조</h3>
            <ul>
                <li><strong>data/</strong> - 수집된 식물 데이터</li>
                <li><strong>logs/</strong> - 시스템 로그 파일</li>
                <li><strong>config/</strong> - 설정 파일</li>
                <li><strong>models/</strong> - 학습된 AI 모델</li>
            </ul>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def home():
    import sys
    return render_template_string(HTML_TEMPLATE,
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        python_version=sys.version,
        working_dir=os.getcwd(),
        venv_active="활성화됨" if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix) else "비활성화됨"
    )

@app.route('/api/status')
def status():
    return jsonify({
        'status': 'online',
        'timestamp': datetime.now().isoformat(),
        'directories': {
            'data': os.path.exists('data'),
            'logs': os.path.exists('logs'),
            'config': os.path.exists('config'),
            'models': os.path.exists('models')
        }
    })

if __name__ == '__main__':
    print("🌱 Plant Analysis SDK 웹 인터페이스 시작")
    print("📱 브라우저에서 http://localhost:5000 접속")
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# 권한 설정
log_info "권한 설정 중..."
sudo chown -R $USER:$USER $HOME/plant_analysis_env
sudo chown -R $USER:$USER $HOME/plant_monitoring

# .bashrc에 별칭 추가
log_info "편의 기능 설정 중..."
if ! grep -q "plant-analysis-sdk" $HOME/.bashrc; then
    cat >> $HOME/.bashrc << 'EOF'

# 🌱 Plant Analysis SDK 별칭
alias plant-sdk='cd ~/plant_monitoring && ./start_plant_sdk.sh'
alias plant-web='cd ~/plant_monitoring && source ~/plant_analysis_env/bin/activate && python3 web_interface.py'
alias plant-jupyter='cd ~/plant_monitoring && source ~/plant_analysis_env/bin/activate && jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser'
alias plant-status='cd ~/plant_monitoring && ls -la && echo "가상환경: $VIRTUAL_ENV"'

# Plant SDK 환경 자동 알림
if [ -d "$HOME/plant_analysis_env" ]; then
    echo "🌱 Plant Analysis SDK 설치됨!"
    echo "시작 명령어: plant-sdk"
    echo "웹 인터페이스: plant-web"
    echo "Jupyter 노트북: plant-jupyter"
fi
EOF
fi

# 시스템 서비스 생성 (선택사항)
log_info "시스템 서비스 설정 생성 중..."
cat > $HOME/plant_monitoring/plant-sdk.service << EOF
[Unit]
Description=Plant Analysis SDK Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/plant_monitoring
Environment=PATH=$HOME/plant_analysis_env/bin
ExecStart=$HOME/plant_analysis_env/bin/python plant_monitoring_system.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 설치 완료 정보 표시
if [ "$NON_INTERACTIVE" = false ]; then
    clear
fi
log_success "🎉 Plant Analysis SDK 설치 완료!"
echo "=========================================="
echo ""
echo "📂 설치 위치:"
echo "  • 가상환경: $HOME/plant_analysis_env"
echo "  • 프로젝트: $HOME/plant_monitoring"
echo ""

if [ "$IMAGE_MODE" = false ]; then
    echo "🚀 시작 방법:"
    echo "  • 빠른 시작: plant-sdk"
    echo "  • 웹 인터페이스: plant-web"
    echo "  • Jupyter 노트북: plant-jupyter"
    echo "  • 수동 실행: cd ~/plant_monitoring && ./start_plant_sdk.sh"
    echo ""
    echo "🔧 시스템 서비스 (선택사항):"
    echo "  sudo cp ~/plant_monitoring/plant-sdk.service /etc/systemd/system/"
    echo "  sudo systemctl enable plant-sdk.service"
    echo "  sudo systemctl start plant-sdk.service"
    echo ""
    echo "📱 웹 인터페이스: http://$(hostname -I | awk '{print $1}'):5000"
    echo "📊 Jupyter 노트북: http://$(hostname -I | awk '{print $1}'):8888"
    echo ""
    echo "✅ 지금 바로 'plant-sdk' 명령어를 실행해보세요!"
else
    echo "🌱 이미지 모드에서 설치 완료!"
    echo "부팅 후 자동으로 서비스가 시작됩니다."
fi
echo ""

# 설치 로그 저장
echo "$(date): Plant Analysis SDK 설치 완료" >> $HOME/plant_monitoring/logs/install.log

log_success "설치가 완료되었습니다. 터미널을 새로 열고 'plant-sdk' 명령어를 사용하세요!"
