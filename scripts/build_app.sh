#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== NudgeLine 빌드 시작 ==="

cd "${ROOT_DIR}"

CONFIGURATION="release"
BUILD_UNIVERSAL=false
IS_DEV=true

for arg in "$@"; do
    case "${arg}" in
        --debug)
            CONFIGURATION="debug"
            ;;
        --universal|--release|--prod)
            IS_DEV=false
            if [[ "${arg}" == "--universal" ]]; then
                BUILD_UNIVERSAL=true
            fi
            ;;
    esac
done

if [[ "${IS_DEV}" == true ]]; then
    echo ">> [개발 모드] 로컬 개발 빌드 (NudgeLine (Dev), BUNDLE_ID: com.rareram.NudgeLine.dev)..."
    SWIFT_FLAGS=(-Xswiftc -DLOCAL_DEV)
    APP_NAME="NudgeLine (Dev)"
    BUNDLE_ID="com.rareram.NudgeLine.dev"
else
    echo ">> [릴리즈 모드] 정식 배포 빌드 (NudgeLine, BUNDLE_ID: com.rareram.NudgeLine)..."
    SWIFT_FLAGS=()
    APP_NAME="NudgeLine"
    BUNDLE_ID="com.rareram.NudgeLine"
fi

if [[ "${BUILD_UNIVERSAL}" == true ]]; then
    echo ">> 1. Swift Package Manager 유니버설 빌드 (arm64 + x86_64, ${CONFIGURATION})..."
    swift build -c "${CONFIGURATION}" ${SWIFT_FLAGS[@]+"${SWIFT_FLAGS[@]}"} --triple arm64-apple-macosx14.0
    swift build -c "${CONFIGURATION}" ${SWIFT_FLAGS[@]+"${SWIFT_FLAGS[@]}"} --triple x86_64-apple-macosx14.0
    
    mkdir -p "${ROOT_DIR}/.build/universal/${CONFIGURATION}"
    lipo -create \
        "${ROOT_DIR}/.build/arm64-apple-macosx/${CONFIGURATION}/NudgeLine" \
        "${ROOT_DIR}/.build/x86_64-apple-macosx/${CONFIGURATION}/NudgeLine" \
        -output "${ROOT_DIR}/.build/universal/${CONFIGURATION}/NudgeLine"
        
    BIN_PATH="${ROOT_DIR}/.build/universal/${CONFIGURATION}/NudgeLine"
else
    echo ">> 1. Swift Package Manager 빌드 (${CONFIGURATION})..."
    swift build -c "${CONFIGURATION}" ${SWIFT_FLAGS[@]+"${SWIFT_FLAGS[@]}"}
    BIN_PATH="${ROOT_DIR}/.build/${CONFIGURATION}/NudgeLine"
fi

APP_DIR="${ROOT_DIR}/build/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo ">> 2. 버전 및 빌드 번호 동기화 (version.json)..."
VERSION_FILE="${ROOT_DIR}/version.json"
if [[ -f "${VERSION_FILE}" ]]; then
    CURRENT_VERSION=$(osascript -l JavaScript -e "JSON.parse($.NSString.stringWithContentsOfFileEncodingError('${VERSION_FILE}', $.NSUTF8StringEncoding, null).js).version" 2>/dev/null || echo "0.1")
    CURRENT_BUILD=$(osascript -l JavaScript -e "JSON.parse($.NSString.stringWithContentsOfFileEncodingError('${VERSION_FILE}', $.NSUTF8StringEncoding, null).js).build" 2>/dev/null || echo "150")
    
    if [[ "${IS_DEV}" == true ]]; then
        TARGET_BUILD=$((CURRENT_BUILD + 1))
        cat << EOF > "${VERSION_FILE}"
{
  "version": "${CURRENT_VERSION}",
  "build": ${TARGET_BUILD}
}
EOF
        echo "   • Version: ${CURRENT_VERSION}"
        echo "   • Build: ${TARGET_BUILD} (개발 빌드 누적 증가)"
    else
        TARGET_BUILD="${CURRENT_BUILD}"
        echo "   • Version: ${CURRENT_VERSION}"
        echo "   • Build: ${TARGET_BUILD} (릴리즈 고정)"
    fi
else
    CURRENT_VERSION="0.1"
    TARGET_BUILD="1"
fi

echo ">> 3. App 번들 생성: ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BIN_PATH}" "${MACOS_DIR}/NudgeLine"
cp "${ROOT_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleName ${APP_NAME}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleName string ${APP_NAME}" "${CONTENTS_DIR}/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName ${APP_NAME}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string ${APP_NAME}" "${CONTENTS_DIR}/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string ${BUNDLE_ID}" "${CONTENTS_DIR}/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${CURRENT_VERSION}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string ${CURRENT_VERSION}" "${CONTENTS_DIR}/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${TARGET_BUILD}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${TARGET_BUILD}" "${CONTENTS_DIR}/Info.plist"

# 아이콘 탑재 (DEV 모드 시 DEV 리본 배지 합성)
if [[ "${IS_DEV}" == true ]]; then
    DEV_ICNS="${ROOT_DIR}/build/AppIcon_Dev.icns"
    if [[ ! -f "${DEV_ICNS}" && -f "${ROOT_DIR}/Resources/icon_1024.png" ]]; then
        echo ">> DEV 앱 아이콘 배지 합성 중..."
        mkdir -p "${ROOT_DIR}/build/icon_dev.iconset"
        swift "${ROOT_DIR}/scripts/generate_dev_icon.swift" "${ROOT_DIR}/Resources/icon_1024.png" "/tmp/icon_dev_1024.png"
        
        sips -z 16 16     "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_16x16.png" >/dev/null
        sips -z 32 32     "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_16x16@2x.png" >/dev/null
        sips -z 32 32     "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_32x32.png" >/dev/null
        sips -z 64 64     "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_32x32@2x.png" >/dev/null
        sips -z 128 128   "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_128x128.png" >/dev/null
        sips -z 256 256   "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_128x128@2x.png" >/dev/null
        sips -z 256 256   "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_256x256.png" >/dev/null
        sips -z 512 512   "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_256x256@2x.png" >/dev/null
        sips -z 512 512   "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_512x512.png" >/dev/null
        sips -z 1024 1024 "/tmp/icon_dev_1024.png" --out "${ROOT_DIR}/build/icon_dev.iconset/icon_512x512@2x.png" >/dev/null
        
        iconutil -c icns "${ROOT_DIR}/build/icon_dev.iconset" -o "${DEV_ICNS}"
        rm -rf "${ROOT_DIR}/build/icon_dev.iconset" "/tmp/icon_dev_1024.png"
    fi
    if [[ -f "${DEV_ICNS}" ]]; then
        cp "${DEV_ICNS}" "${RESOURCES_DIR}/AppIcon.icns"
    elif [[ -f "${ROOT_DIR}/Resources/AppIcon.icns" ]]; then
        cp "${ROOT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
    fi
else
    if [[ -f "${ROOT_DIR}/Resources/AppIcon.icns" ]]; then
        cp "${ROOT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
    fi
fi

echo ">> 4. Ad-hoc 코드 서명 적용..."
codesign --force --deep -s - "${APP_DIR}"

if [[ "${IS_DEV}" == true ]]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${APP_DIR}" 2>/dev/null || true
    echo ">> 5. LaunchServices 등록: ${APP_NAME} 런치패드/Spotlight 등록 완료"
fi

echo "=== 빌드 및 번들 패키징 완료 (${APP_NAME} v${CURRENT_VERSION} Build ${TARGET_BUILD}) ==="
echo "생성된 앱 경로: ${APP_DIR}"
echo "직접 실행 명령어: open \"${APP_DIR}\""
