#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== 1. App 빌드 실행 ==="
./scripts/build_app.sh

echo "=== 2. 배포용 DMG 패키징 ==="
mkdir -p dist
DMG_PATH="dist/NudgeLine.dmg"

echo ">> 1. DMG 패키징..."
hdiutil create -volname "NudgeLine" \
  -srcfolder build/NudgeLine.app \
  -ov -format UDZO "${DMG_PATH}"

echo ">> 2. SHA256 체크섬 생성..."
cd dist
shasum -a 256 "NudgeLine.dmg" > SHA256SUMS.txt

echo "=== DMG 패키징 완료 ==="
echo "생성된 DMG: $PROJECT_ROOT/$DMG_PATH"
ls -lh "$PROJECT_ROOT/$DMG_PATH"
