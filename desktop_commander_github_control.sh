#!/bin/bash

# 🎯 Desktop Commander GitHub 제어 스크립트
# VS Code 기존 인증을 활용한 완전 자동화

echo "🚀 Desktop Commander GitHub 자동 제어 시작"
echo "============================================="

# 현재 상태 확인
echo "📍 현재 위치: $(pwd)"
echo "📍 Git 상태:"
git status --short

# 변경사항 확인
if [ -n "$(git status --porcelain)" ]; then
    echo ""
    echo "📝 변경사항 감지됨. 업데이트 진행 중..."
    
    # 불필요한 파일들 제거
    echo "🧹 불필요한 파일들 정리 중..."
    
    # 중복 폴더들 제거
    if [ -d "dot-github-workflows" ]; then
        git rm -r --cached dot-github-workflows 2>/dev/null || rm -rf dot-github-workflows
        echo "✅ dot-github-workflows 폴더 제거"
    fi
    
    if [ -d "github-workflows" ]; then
        git rm -r --cached github-workflows 2>/dev/null || rm -rf github-workflows  
        echo "✅ github-workflows 폴더 제거"
    fi
    
    # 내부 문서들 제거
    for file in DESKTOP_COMMANDER_COMPLETION.md FINAL_UPLOAD_INSTRUCTIONS.md GITHUB_CLEANUP_GUIDE.md MISSING_GITHUB_FOLDER_FIX.md auto_upload.sh auto_upload_fixed.sh; do
        if [ -f "$file" ]; then
            git rm --cached "$file" 2>/dev/null || rm -f "$file"
            echo "✅ $file 제거"
        fi
    done
    
    # .DS_Store 제거
    find . -name ".DS_Store" -delete 2>/dev/null || true
    echo "✅ .DS_Store 파일들 제거"
    
    # .gitignore 생성
    cat > .gitignore << 'EOF'
# macOS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# 개발 환경
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# 로그
*.log
logs/
*.log.*

# 환경 설정
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/settings.json
.vscode/launch.json
.idea/
*.swp
*.swo
*~

# 내부 문서 (사용자에게 불필요)
DESKTOP_COMMANDER_*.md
FINAL_UPLOAD_*.md
GITHUB_CLEANUP_*.md
MISSING_GITHUB_*.md
auto_upload*.sh
EOF
    
    # 모든 변경사항 스테이징
    git add .
    echo "✅ 모든 변경사항 스테이징 완료"
    
    # 커밋
    git commit -m "🧹 Clean up repository and add .gitignore

✅ Removed duplicate workflow folders (dot-github-workflows, github-workflows)
✅ Removed internal documentation files  
✅ Removed temporary upload scripts
✅ Added comprehensive .gitignore
✅ Repository now clean and production-ready

This keeps only the essential files that users need:
- Enhanced installation scripts
- Core Python monitoring system
- Complete documentation
- GitHub Actions workflows"
    
    echo "✅ 커밋 완료"
    
    # GitHub에 푸시
    echo "🚀 GitHub에 푸시 중..."
    if git push origin main; then
        echo ""
        echo "🎉 GitHub 업데이트 성공!"
        echo "✅ Repository가 깨끗하게 정리되었습니다"
        echo "✅ 사용자에게 필요한 파일들만 남았습니다"
        echo ""
        echo "📋 남은 핵심 파일들:"
        echo "  - .github/workflows/ (GitHub Actions)"
        echo "  - enhanced_install.sh (개선된 설치)"
        echo "  - plant_monitoring_system.py (메인 시스템)"
        echo "  - automated_monitoring.py (자동화)"
        echo "  - README.md (완전한 문서)"
        echo "  - LICENSE, .gitignore"
        echo ""
        echo "🔧 GitHub Actions 상태:"
        echo "  Repository → Actions 탭에서 빌드 상태 확인"
    else
        echo "⚠️ 푸시 실패. VS Code에서 GitHub 재인증 필요할 수 있음"
        echo "💡 VS Code에서 Terminal → New Terminal 열고 다시 시도해보세요"
    fi
else
    echo ""
    echo "✅ Repository가 이미 깨끗한 상태입니다"
    echo "📋 현재 파일들:"
    git ls-files | head -10
fi

echo ""
echo "🎯 Desktop Commander GitHub 제어 완료!"
echo ""
echo "📱 확인사항:"
echo "1. https://github.com/2sdaymars/plant-analysis-sdk 접속"
echo "2. Actions 탭에서 자동 빌드 확인"
echo "3. Repository가 깨끗하게 정리되었는지 확인"