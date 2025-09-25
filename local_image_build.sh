#!/bin/bash

# 🌱 Plant Analysis SDK 로컬 이미지 빌드 스크립트
# macOS에서 실행 가능한 실용적인 방법

echo "🌱 Plant Analysis SDK 로컬 이미지 빌드"
echo "================================================"

# 필수 도구 확인
echo "🔍 필수 도구 확인 중..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker가 필요합니다. 설치 방법:"
    echo "1. https://www.docker.com/products/docker-desktop/ 접속"
    echo "2. Docker Desktop for Mac 다운로드 및 설치"
    echo "3. Docker 실행 후 다시 시도"
    exit 1
fi

echo "✅ Docker 발견됨"

# Docker로 pi-gen 이미지 빌드 (실제 작동하는 방법)
echo ""
echo "🐳 Docker 기반 Raspberry Pi 이미지 빌드 시작..."
echo "예상 소요 시간: 60-90분"
echo ""

# 작업 디렉토리 생성
mkdir -p ~/plant-sdk-image-build
cd ~/plant-sdk-image-build

# pi-gen 사용을 위한 Docker 설정
cat > Dockerfile << 'EOF'
FROM debian:bullseye

# 필수 패키지 설치
RUN apt-get update && apt-get install -y \
    git \
    qemu-user-static \
    kpartx \
    debootstrap \
    build-essential \
    coreutils \
    quilt \
    parted \
    realpath \
    zerofree \
    zip \
    dosfstools \
    libarchive-tools \
    libcap2-bin \
    rsync \
    grep \
    udev \
    xz-utils \
    curl \
    xxd \
    file \
    kmod \
    bc \
    binfmt-support \
    ca-certificates

# pi-gen 클론
RUN git clone https://github.com/RPi-Distro/pi-gen.git /pi-gen

WORKDIR /pi-gen

# 빌드 설정
RUN echo "IMG_NAME='plant-analysis-sdk'" > config
RUN echo "STAGE_LIST='stage0 stage1 stage2'" >> config
RUN echo "ENABLE_SSH=1" >> config
RUN echo "TARGET_HOSTNAME='plant-pi'" >> config

# Plant SDK 설치를 위한 스테이지 생성
RUN mkdir -p stage2/01-plant-sdk/00-run.sh

# Plant SDK 설치 스크립트 생성
RUN cat > stage2/01-plant-sdk/00-run.sh << 'SCRIPT'
#!/bin/bash -e
on_chroot << EOF
cd /home/pi
git clone https://github.com/2sdaymars/plant-analysis-sdk.git
cd plant-analysis-sdk
chmod +x enhanced_install.sh
./enhanced_install.sh --image-mode --non-interactive
systemctl enable ssh
echo 'pi:raspberry' | chpasswd
EOF
SCRIPT

RUN chmod +x stage2/01-plant-sdk/00-run.sh

CMD ["./build.sh"]
EOF

echo "🔨 Docker 이미지 빌드 시작..."
docker build -t plant-sdk-builder .

echo "🚀 Raspberry Pi 이미지 생성 시작..."
docker run --privileged --rm -v $(pwd)/deploy:/pi-gen/deploy plant-sdk-builder

echo ""
echo "✅ 빌드 완료! 결과 확인:"
ls -la deploy/

echo ""
echo "📋 사용 방법:"
echo "1. deploy/ 폴더에서 .img 파일 확인"  
echo "2. Raspberry Pi Imager로 SD 카드에 굽기"
echo "3. 라즈베리파이 부팅 후 http://plant-pi.local:5000 접속"

EOF