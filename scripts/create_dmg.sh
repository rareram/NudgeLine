#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== 1. App 빌드 실행 ==="
./scripts/build_app.sh "$@"

echo "=== 2. 배포용 DMG 패키징 ==="
mkdir -p dist
DMG_PATH="dist/NudgeLine.dmg"
BG_IMAGE="${PROJECT_ROOT}/Resources/dmg_background.png"
APP_PATH="${PROJECT_ROOT}/build/NudgeLine.app"
APP_DEV_PATH="${PROJECT_ROOT}/build/NudgeLine (Dev).app"

# 빌드된 타깃 앱 번들 확인
TARGET_APP="${APP_PATH}"
if [[ ! -d "${TARGET_APP}" && -d "${APP_DEV_PATH}" ]]; then
    TARGET_APP="${APP_DEV_PATH}"
fi

APP_NAME="$(basename "${TARGET_APP}" .app)"
VOL_NAME="${APP_NAME}"

rm -f "${DMG_PATH}"

if command -v create-dmg &> /dev/null; then
    echo ">> [create-dmg] 커스텀 디자인 DMG 생성 중..."
    
    CREATE_DMG_ARGS=(
        --volname "${VOL_NAME}"
        --window-pos 200 120
        --window-size 640 400
        --icon-size 180
        --icon "${APP_NAME}.app" 160 200
        --app-drop-link 480 200
        --hide-extension "${APP_NAME}.app"
        --no-internet-enable
    )
    
    if [[ -f "${TARGET_APP}/Contents/Resources/AppIcon.icns" ]]; then
        CREATE_DMG_ARGS+=(--volicon "${TARGET_APP}/Contents/Resources/AppIcon.icns")
    fi
    
    if [[ -f "${BG_IMAGE}" ]]; then
        CREATE_DMG_ARGS+=(--background "${BG_IMAGE}")
    fi
    
    create-dmg "${CREATE_DMG_ARGS[@]}" "${DMG_PATH}" "${TARGET_APP}" || true
fi

# create-dmg가 TCC 권한 등으로 실패했을 경우 fallback 생성
if [[ ! -f "${DMG_PATH}" ]]; then
    echo ">> [hdiutil fallback] Applications 심볼릭 링크 포함 DMG 생성 중..."
    TMP_DMG_DIR=$(mktemp -d /tmp/nudgeline_dmg.XXXXXX)
    cp -R "${TARGET_APP}" "${TMP_DMG_DIR}/"
    ln -s /Applications "${TMP_DMG_DIR}/Applications"
    
    if [[ -f "${BG_IMAGE}" ]]; then
        mkdir -p "${TMP_DMG_DIR}/.background"
        cp "${BG_IMAGE}" "${TMP_DMG_DIR}/.background/"
    fi
    
    hdiutil create -volname "${VOL_NAME}" \
        -srcfolder "${TMP_DMG_DIR}" \
        -ov -format UDZO "${DMG_PATH}"
    
    rm -rf "${TMP_DMG_DIR}"
fi

echo ">> 3. SHA256 체크섬 생성..."
cd dist
shasum -a 256 "NudgeLine.dmg" > SHA256SUMS.txt

echo "=== DMG 패키징 완료 ==="
echo "생성된 DMG: $PROJECT_ROOT/$DMG_PATH"
ls -lh "$PROJECT_ROOT/$DMG_PATH"
