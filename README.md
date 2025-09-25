# 🌱 Plant Analysis SDK

**라즈베리파이용 완전 자동화 식물 분석 시스템**

> CinePI 스타일의 완성된 식물 모니터링 솔루션 - 다운로드해서 바로 사용!

## 🚀 빠른 시작

### 방법 1: 원클릭 설치 (추천)
```bash
# 저장소 복제
git clone https://github.com/2sdaymars/plant-analysis-sdk.git
cd plant-analysis-sdk

# 개선된 설치 스크립트 실행
chmod +x enhanced_install.sh
./enhanced_install.sh

# 설치 완료 후 바로 시작
plant-sdk
```

### 방법 2: 릴리즈 패키지 다운로드
1. [Releases 페이지](https://github.com/2sdaymars/plant-analysis-sdk/releases)에서 최신 버전 다운로드
2. 라즈베리파이에 압축 해제: `tar -xzf plant-analysis-sdk-release.tar.gz`
3. 설치 실행: `./one_click_install.sh`
4. 시작: `plant-sdk`

## 📦 포함된 기능

### 🌿 핵심 기능
- **실시간 식물 모니터링** - 카메라 기반 식물 상태 분석
- **🔴 실시간 카메라 보기** - 웹 브라우저에서 라이브 스트리밍
- **📸 원클릭 촬영** - 웹 인터페이스에서 즉시 촬영
- **자동화 시스템** - 스케줄링 기반 자동 모니터링
- **웹 인터페이스** - 브라우저에서 시스템 제어
- **Jupyter 노트북** - 대화형 데이터 분석
- **완전 자동 설치** - 원클릭으로 모든 환경 구성

### 🛠️ 기술 스택
- **Python 3.9+** - 메인 프로그래밍 언어
- **OpenCV** - 컴퓨터 비전 및 이미지 처리
- **PlantCV** - 전문 식물 분석 라이브러리
- **Flask** - 웹 인터페이스
- **Jupyter** - 대화형 분석 환경
- **scikit-learn** - 머신러닝

## 🎯 시스템 요구사항

### 하드웨어
- **Raspberry Pi 4** (권장) 또는 Pi 3B+
- **16GB+ SD 카드** (Class 10 권장)
- **Pi Camera Module** V2 또는 HQ Camera
- **선택사항**: 환경 센서들 (온도, 습도, 토양 센서)

### 소프트웨어
- **Raspberry Pi OS** (Bookworm 권장)
- **Python 3.9+**
- **인터넷 연결** (초기 설치용)

## 📱 사용 방법

### 기본 명령어
```bash
# SDK 환경 시작
plant-sdk

# 🔴 실시간 웹 인터페이스 실행 (http://라즈베리파이IP:5000)
# - 라이브 카메라 스트리밍
# - 원클릭 이미지 촬영
# - 실시간 시스템 제어
plant-web

# Jupyter 노트북 실행 (http://라즈베리파이IP:8888)
plant-jupyter

# 시스템 상태 확인
plant-status
```

### 🔴 실시간 웹 인터페이스 기능
- **라이브 카메라**: 실시간 MJPEG 스트리밍
- **즉시 촬영**: 웹에서 버튼 클릭으로 촬영
- **전체화면 보기**: 카메라 화면 확대
- **식물별 분류**: 이름 설정하여 자동 분류 저장
- **자동 모니터링**: 간격 설정 및 제어
- **시스템 상태**: 실시간 통계 및 정보

### 메인 모니터링 시스템
```bash
cd ~/plant_monitoring
source ~/plant_analysis_env/bin/activate
python3 plant_monitoring_system.py
```

### 자동화 모니터링
```bash
cd ~/plant_monitoring
source ~/plant_analysis_env/bin/activate
python3 automated_monitoring.py
```

## 🔧 고급 설정

### 시스템 서비스로 등록
```bash
# 서비스 파일 복사
sudo cp ~/plant_monitoring/plant-sdk.service /etc/systemd/system/

# 서비스 활성화
sudo systemctl enable plant-sdk.service
sudo systemctl start plant-sdk.service

# 상태 확인
sudo systemctl status plant-sdk.service
```

### Docker로 실행
```bash
cd plant-analysis-sdk-release
docker-compose up -d
```

## 📂 프로젝트 구조

```
~/plant_monitoring/
├── plant_monitoring_system.py    # 메인 모니터링 시스템
├── automated_monitoring.py       # 자동화 스크립트
├── web_interface.py              # 웹 인터페이스
├── start_plant_sdk.sh            # 시작 스크립트
├── data/                         # 수집된 데이터
├── logs/                         # 시스템 로그
├── config/                       # 설정 파일
└── models/                       # 학습된 모델
```

## 🌐 웹 인터페이스

설치 완료 후 브라우저에서 접속:
- **메인 대시보드**: `http://라즈베리파이IP:5000`
- **Jupyter 노트북**: `http://라즈베리파이IP:8888`

## 📊 데이터 분석

### Jupyter 노트북 사용
1. `plant-jupyter` 명령어 실행
2. 브라우저에서 `http://라즈베리파이IP:8888` 접속
3. 노트북에서 대화형 분석 수행

### 수집된 데이터 위치
- **이미지**: `~/plant_monitoring/data/images/`
- **측정 데이터**: `~/plant_monitoring/data/measurements/`
- **분석 결과**: `~/plant_monitoring/data/analysis/`

## 🔍 문제 해결

### 일반적인 문제들

**카메라가 인식되지 않을 때:**
```bash
# 카메라 모듈 활성화
sudo raspi-config nonint do_camera 0
sudo reboot
```

**권한 문제가 발생할 때:**
```bash
sudo chown -R $USER:$USER ~/plant_analysis_env
sudo chown -R $USER:$USER ~/plant_monitoring
```

**패키지 설치 실패시:**
```bash
# 패키지 캐시 정리
sudo apt clean && sudo apt update

# 재설치
./enhanced_install.sh
```

### 로그 확인
```bash
# 설치 로그
cat ~/plant_monitoring/logs/install.log

# 시스템 로그 
cat ~/plant_monitoring/logs/system.log

# 서비스 로그 (서비스 사용시)
sudo journalctl -u plant-sdk.service
```

## 🚀 개발자 정보

### GitHub Actions 자동 빌드
- **테스트 빌드**: 모든 push에서 자동 실행
- **릴리즈 빌드**: 태그 생성시 자동 패키지 생성
- **Artifacts**: 빌드된 패키지 자동 업로드

### 기여하기
1. 이 저장소를 Fork
2. 새로운 기능 브랜치 생성: `git checkout -b feature/amazing-feature`
3. 변경사항 커밋: `git commit -m 'Add amazing feature'`
4. 브랜치에 Push: `git push origin feature/amazing-feature`
5. Pull Request 생성

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 💡 영감

이 프로젝트는 [CinePI](https://github.com/cinepi/cinepi-raw)의 완성된 이미지 배포 방식에서 영감을 받았습니다. CinePI처럼 사용자가 복잡한 설정 없이 바로 사용할 수 있는 완성된 시스템을 목표로 합니다.

## 🆘 지원

문제가 발생하거나 도움이 필요하시면:
1. [Issues 페이지](https://github.com/2sdaymars/plant-analysis-sdk/issues)에서 검색
2. 새로운 Issue 생성
3. 상세한 문제 상황과 로그 포함

---

**🌱 Happy Plant Monitoring! 🌱**

> "식물의 건강을 기술로 지켜주는 스마트 가드닝의 시작"