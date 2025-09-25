# GitHub Actions로 Raspberry Pi 이미지 생성 방법들

## 방법 1: Docker 기반 이미지 빌드 (실제 사용 가능)

```yaml
name: Build Raspberry Pi Image
on:
  push:
    tags:
      - 'v*'

jobs:
  build-image:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Build Raspberry Pi Image
        run: |
          # pi-gen 기반 이미지 빌드
          docker run --rm --privileged \
            -v $PWD:/workspace \
            -e IMG_NAME=plant-analysis-sdk \
            rpgforge/pi-gen:latest
```

## 방법 2: QEMU + chroot 방식 (GitHub Actions에서 실제 작동)

```yaml
name: Build Custom Pi Image
on:
  release:
    types: [created]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y qemu-user-static

      - name: Download base image
        run: |
          wget -O raspios-lite.zip https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-03-15/2024-03-15-raspios-lite.zip
          unzip raspios-lite.zip

      - name: Mount and customize image
        run: |
          # 루프백 마운트로 이미지 수정
          sudo losetup -P /dev/loop0 *.img
          sudo mkdir -p /mnt/rpi-boot /mnt/rpi-root
          sudo mount /dev/loop0p1 /mnt/rpi-boot
          sudo mount /dev/loop0p2 /mnt/rpi-root
          
          # chroot 환경에서 패키지 설치
          sudo cp /usr/bin/qemu-arm-static /mnt/rpi-root/usr/bin/
          sudo chroot /mnt/rpi-root /bin/bash -c "
            apt-get update
            apt-get install -y python3 python3-pip
            # 우리 시스템 설치
            wget https://github.com/2sdaymars/plant-analysis-sdk/archive/main.zip
            unzip main.zip
            cd plant-analysis-sdk-main
            chmod +x enhanced_install.sh
            ./enhanced_install.sh --image-mode
          "
          
      - name: Create release image
        run: |
          sudo umount /mnt/rpi-*
          sudo losetup -d /dev/loop0
          
          # 이미지 압축 및 업로드
          zip plant-analysis-sdk-$(date +%Y%m%d).zip *.img
```

## 방법 3: 실제 CinePI가 사용하는 방식

CinePI는 다음과 같은 방식을 사용합니다:
1. **베이스 이미지**: Raspberry Pi OS Lite
2. **Docker 기반 빌드**: pi-gen 또는 유사한 도구
3. **GitHub Actions**: 자동 빌드 및 릴리즈
4. **분할 다운로드**: 큰 이미지를 여러 파트로 분할

## 방법 4: 하이브리드 접근법 (권장)

```yaml
name: Multi-Format Release
on:
  push:
    tags: ['v*']

jobs:
  # SDK 패키지 빌드 (빠름)
  build-sdk:
    runs-on: ubuntu-latest
    steps:
      - name: Create SDK package
        run: |
          tar -czf plant-analysis-sdk.tar.gz .
          
  # 완성된 이미지 빌드 (느림)  
  build-image:
    runs-on: ubuntu-latest
    if: contains(github.ref, 'image')  # image 태그일 때만
    steps:
      - name: Build full image
        # 위 방법들 중 하나 사용
```

## 실제 성공 사례들

- **CinePI**: pi-gen + GitHub Actions
- **DietPi**: 자체 빌드 시스템 + GitHub
- **RetroPie**: Docker 기반 이미지 빌드
- **Volumio**: Jenkins + 자체 빌드 서버

## 결론

GitHub Actions로 이미지 생성은 **완전히 가능**합니다!
다만 시간과 복잡성을 고려해 단계적 접근이 필요:

1. **1단계**: SDK 패키지 (현재 완성)
2. **2단계**: Docker 기반 이미지 빌드 추가  
3. **3단계**: 사용자 선택 옵션 제공