#!/bin/bash

# 🎉 Desktop Commander 자동 GitHub 업로드 (선택사항)
# 만약 Git 인증이 설정되어 있다면 이 스크립트로 자동 업로드 가능

echo "🚀 Plant Analysis SDK - GitHub 자동 업로드 스크립트"
echo "=================================================="

# 현재 디렉토리 확인
if [[ ! -f "README.md" || ! -f "enhanced_install.sh" ]]; then
    echo "❌ 오류: final-github-upload 폴더에서 실행해주세요"
    exit 1
fi

echo "📂 현재 위치: $(pwd)"
echo "📋 업로드할 파일들:"
ls -la

echo ""
echo "🔧 Git 설정 확인 중..."

# Git 초기화
if [ ! -d ".git" ]; then
    git init
    echo "✅ Git 저장소 초기화"
fi

# 원격 저장소 설정
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/2sdaymars/plant-analysis-sdk.git
echo "✅ 원격 저장소 연결"

# 브랜치 설정
git branch -M main

# 파일 추가
git add .
echo "✅ 모든 파일 스테이징"

# 커밋
git commit -m "🚀 Fix GitHub Actions build issues and add enhanced features

✅ Fixed GitHub Actions workflow build failures
✅ Added stable release build system
✅ Added quick test build workflow  
✅ Enhanced installation script with web interface
✅ Updated comprehensive documentation
✅ Added convenience commands (plant-sdk, plant-web, etc.)
✅ Docker support and system service configuration

This update resolves the complex image building issues and provides
a CinePI-style complete solution that users can download and run immediately."

echo "✅ 커밋 완료"

echo ""
echo "🌐 GitHub에 업로드 시도 중..."
echo "⚠️  GitHub 인증이 필요할 수 있습니다."

# 푸시 시도
if git push -u origin main; then
    echo ""
    echo "🎉 GitHub 업로드 성공!"
    echo "✅ https://github.com/2sdaymars/plant-analysis-sdk 확인하세요"
    echo "✅ Actions 탭에서 자동 빌드 확인하세요"
else
    echo ""
    echo "⚠️  자동 업로드 실패 - 수동 업로드 방법:"
    echo ""
    echo "1. https://github.com/2sdaymars/plant-analysis-sdk 접속"
    echo "2. 'Add file' → 'Upload files' 클릭"
    echo "3. 이 폴더의 모든 파일을 드래그 & 드롭"
    echo "4. Commit 메시지 입력 후 'Commit changes' 클릭"
    echo ""
    echo "📖 자세한 방법은 DESKTOP_COMMANDER_COMPLETION.md 참조"
fi

echo ""
echo "🚀 완료! CinePI 스타일의 완성된 시스템이 준비되었습니다!"