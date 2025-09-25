# 📤 GitHub 업로드 상세 가이드

## 🎯 업로드할 파일들

이 폴더(`github-upload-files/`)에 있는 모든 파일들을 GitHub에 업로드하세요:

```
github-upload-files/
├── .github/workflows/build-image.yml  # ⭐ 가장 중요! (자동 빌드)
├── plant_monitoring_system.py         # 식물 모니터링 시스템
├── automated_monitoring.py            # 자동화 도구
├── one_click_install.sh               # 원클릭 설치
├── updated_setup.sh                   # 설치 스크립트
├── README.md                          # 프로젝트 설명
└── UPLOAD_GUIDE.md                    # 이 파일
```

## 📱 업로드 방법 (웹 브라우저)

### 방법 1: 드래그 & 드롭 (가장 쉬움)

1. **https://github.com/2sdaymars/plant-analysis-sdk** 접속

2. **"uploading an existing file"** 링크 클릭
   (또는 페이지 중간에 "drag files here" 영역)

3. **파일들을 드래그해서 끌어다 놓기**
   - `github-upload-files` 폴더에서 모든 파일 선택
   - 브라우저 창으로 드래그

4. **폴더 구조 확인**
   - `.github/workflows/build-image.yml` 이 올바른 위치에 있는지 확인

5. **Commit 메시지 작성:**
   ```
   Add complete Plant Analysis SDK files

   - GitHub Actions workflow for automatic image building
   - Complete monitoring system with plant analysis
   - One-click installation script
   - Documentation and guides
   ```

6. **"Commit changes"** 클릭

### 방법 2: 개별 파일 업로드

각 파일을 하나씩 업로드하는 방법:

1. **"Add file" → "Create new file"** 클릭

2. **파일 이름 입력** (예: `plant_monitoring_system.py`)

3. **파일 내용 복사 & 붙여넣기**

4. **"Commit new file"** 클릭

5. **다음 파일로 반복**

## ⚠️ 중요한 주의사항

### 폴더 구조 유지
```
✅ 올바른 구조:
.github/workflows/build-image.yml

❌ 잘못된 구조:  
github/workflows/build-image.yml
build-image.yml
```

### 파일 권한
- `.sh` 파일들은 실행 가능해야 함
- GitHub이 자동으로 처리해줌

### 필수 파일
**반드시 업로드해야 하는 파일:**
- ⭐ `.github/workflows/build-image.yml` (자동 빌드)
- 🌱 `plant_monitoring_system.py` (메인 시스템)
- 🚀 `one_click_install.sh` (간편 설치)

## 🔍 업로드 완료 확인

업로드 후 다음을 확인하세요:

1. **Repository 메인 페이지**에서 모든 파일이 보이는지
2. **Actions 탭**이 나타났는지 (GitHub Actions 활성화 확인)
3. **README.md**가 제대로 표시되는지

## 🚀 다음 단계

파일 업로드가 완료되면:

1. **GitHub Actions 활성화 확인**
2. **첫 번째 빌드 실행**  
3. **완성된 이미지 다운로드**

---

## 💡 도움이 필요하면

- 스크린샷을 찍어서 보여주세요
- 어떤 단계에서 막혔는지 알려주세요  
- 오류 메시지가 있으면 복사해서 붙여넣기 해주세요

**CinePI와 동일한 완성된 이미지**를 만드는 게 목표입니다! 🎯