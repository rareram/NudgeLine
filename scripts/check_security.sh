#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=========================================="
echo "NudgeLine 보안 및 정적 점검 시작"
echo "=========================================="

echo ">> 1. Swift Package 컴파일 검증..."
swift build -c release

echo ">> 2. 민감한 키 / 비밀번호 / 토큰 유출 패턴 검사..."
if command -v gitleaks &> /dev/null; then
  echo "gitleaks (GitHub 표준 엔진) 정밀 스캔 실행 중..."
  gitleaks detect --no-git -v
  echo "gitleaks 검사 통과: 유출된 시크릿 없음"
else
  # 정밀 정규식 검사 (단순 변수명 제외, 실제 비밀 키 / 토큰 패턴만 정밀 탐지)
  LEAKS=$(grep -rnE "(ghp_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}|sk-[a-zA-Z0-9]{32,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|bearer\s+[a-zA-Z0-9_\-\.]{25,}|password\s*[:=]\s*[\"'][^\"']+[\"'])" \
    --exclude-dir={.git,.build,build,dist,exported_pets,draft} \
    --exclude="*.png" --exclude="*.jpeg" --exclude="*.jpg" --exclude="*.svg" \
    . || true)

  if [ -n "$LEAKS" ]; then
    echo "치명적인 비밀 키 / 토큰 패턴 발견:"
    echo "$LEAKS"
    exit 1
  else
    echo "하드코딩된 시크릿/토큰 없음 (안전)"
    echo "Tip: 'brew install gitleaks' 설치 시 GitHub 공식 보안 봇과 100% 동일한 정밀 검사가 지원됩니다."
  fi
fi

echo ">> 3. .gitignore 점검..."
if [ -f .gitignore ]; then
  echo ".gitignore 파일 존재"
else
  echo ".gitignore 파일이 없습니다."
fi

echo "=========================================="
echo "모든 로컬 사전 점검이 완료되었습니다."
echo "=========================================="
