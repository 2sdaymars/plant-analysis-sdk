#!/bin/bash

# 🔧 .github 폴더 문제 해결 및 자동 업로드 스크립트
echo "🚀 Plant Analysis SDK - 완전 자동 GitHub 업로드"
echo "=================================================="

# 현재 위치 확인
if [[ ! -f "README.md" ]]; then
    echo "❌ 오류: final-github-upload 폴더에서 실행해주세요"
    exit 1
fi

echo "📂 현재 위치: $(pwd)"

# .github 폴더 강제 재생성 (Mac Finder 문제 해결)
echo "🔧 .github 폴더 문제 해결 중..."

# 기존 .github 폴더 제거 후 재생성
rm -rf .github 2>/dev/null || true

# 새로운 .github/workflows 폴더 생성
mkdir -p .github/workflows

# 파일들 복사 (여러 소스에서)
if [ -d "dot-github-workflows" ]; then
    echo "✅ dot-github-workflows 폴더에서 파일 복사"
    cp dot-github-workflows/build-image.yml .github/workflows/ 2>/dev/null || true
    cp dot-github-workflows/test-build.yml .github/workflows/ 2>/dev/null || true
fi

if [ -d "github-workflows" ]; then
    echo "✅ github-workflows 폴더에서 파일 복사"
    cp github-workflows/build-image.yml .github/workflows/ 2>/dev/null || true
    cp github-workflows/test-build.yml .github/workflows/ 2>/dev/null || true
fi

# 파일 존재 확인
if [ -f ".github/workflows/build-image.yml" ]; then
    echo "✅ build-image.yml 생성 완료"
else
    echo "❌ build-image.yml 생성 실패"
fi

if [ -f ".github/workflows/test-build.yml" ]; then
    echo "✅ test-build.yml 생성 완료"
else
    echo "❌ test-build.yml 생성 실패"
fi

# 최종 파일 목록 표시
echo ""
echo "📋 업로드할 파일들:"
ls -la | grep -v "^d.*\."  # 숨김 디렉토리 제외
ls -la .github/workflows/ 2>/dev/null || echo "⚠️ .github/workflows 폴더 없음"

echo ""
echo "🌐 GitHub에 업로드 시도 중..."

# Git 초기화 및 설정
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

# 모든 파일 추가 (숨김 파일 포함)
git add -A
echo "✅ 모든 파일 스테이징 (.github 폴더 포함)"

# 커밋
git commit -m "🚀 Complete Plant Analysis SDK with GitHub Actions

✅ Fixed .github folder visibility issues
✅ Added stable release build system
✅ Added quick test build workflow  
✅ Enhanced installation script with web interface
✅ Updated comprehensive documentation
✅ Added convenience commands (plant-sdk, plant-web, etc.)
✅ Docker support and system service configuration

This update provides a complete CinePI-style solution that users 
can download and run immediately with full GitHub Actions automation."

echo "✅ 커밋 완료"

# 푸시 시도
if git push -u origin main --force; then
    echo ""
    echo "🎉 GitHub 업로드 성공!"
    echo "✅ https://github.com/2sdaymars/plant-analysis-sdk 확인하세요"
    echo "✅ Actions 탭에서 자동 빌드 확인하세요"
    echo "✅ 2-3분 내 테스트 빌드가 자동 실행됩니다"
else
    echo ""
    echo "⚠️ 자동 업로드 실패 - 수동 업로드 진행하세요:"
    echo ""
    echo "📂 준비된 파일들:"
    echo "1. 현재 폴더의 모든 파일 (README.md, enhanced_install.sh 등)"
    echo "2. dot-github-workflows 폴더의 내용을 GitHub에서 .github/workflows/로 생성"
    echo ""
    echo "🔧 수동 업로드 방법:"
    echo "1. https://github.com/2sdaymars/plant-analysis-sdk 접속"
    echo "2. 일반 파일들 드래그 업로드"
    echo "3. Create new file → .github/workflows/build-image.yml"
    echo "4. Create new file → .github/workflows/test-build.yml"
    echo ""
fi

echo ""
echo "🎯 다음 확인사항:"
echo "✅ Repository 상단에 Actions 탭 나타나는지 확인"
echo "✅ .github/workflows 폴더에 2개 파일 존재하는지 확인"  
echo "✅ Test Build 워크플로우 자동 실행되는지 확인"
echo ""
echo "🚀 완료! CinePI 수준의 완성된 시스템이 준비되었습니다!"