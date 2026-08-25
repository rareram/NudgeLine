#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== NudgeLine 빌드 시작 ==="

cd "${ROOT_DIR}"

CONFIGURATION="release"
BUILD_UNIVERSAL=false

for arg in "$@"; do
    case "${arg}" in
        --debug)
            CONFIGURATION="debug"
            ;;
        --universal)
            BUILD_UNIVERSAL=true
            ;;
    esac
done

if [[ "${BUILD_UNIVERSAL}" == true ]]; then
    echo ">> 1. Swift Package Manager 유니버설 빌드 (arm64 + x86_64, ${CONFIGURATION})..."
    swift build -c "${CONFIGURATION}" --triple arm64-apple-macosx14.0
    swift build -c "${CONFIGURATION}" --triple x86_64-apple-macosx14.0
    
    mkdir -p "${ROOT_DIR}/.build/universal/${CONFIGURATION}"
    lipo -create \
        "${ROOT_DIR}/.build/arm64-apple-macosx/${CONFIGURATION}/NudgeLine" \
        "${ROOT_DIR}/.build/x86_64-apple-macosx/${CONFIGURATION}/NudgeLine" \
        -output "${ROOT_DIR}/.build/universal/${CONFIGURATION}/NudgeLine"
        
    BIN_PATH="${ROOT_DIR}/.build/universal/${CONFIGURATION}/NudgeLine"
else
    echo ">> 1. Swift Package Manager 빌드 (${CONFIGURATION})..."
    swift build -c "${CONFIGURATION}"
    BIN_PATH="${ROOT_DIR}/.build/${CONFIGURATION}/NudgeLine"
fi
APP_DIR="${ROOT_DIR}/build/NudgeLine.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo ">> 2. 버전 및 빌드 번호 갱신 (version.json)..."
VERSION_FILE="${ROOT_DIR}/version.json"
if [[ -f "${VERSION_FILE}" ]]; then
    CURRENT_VERSION=$(osascript -l JavaScript -e "JSON.parse($.NSString.stringWithContentsOfFileEncodingError('${VERSION_FILE}', $.NSUTF8StringEncoding, null).js).version" 2>/dev/null || echo "0.1")
    CURRENT_BUILD=$(osascript -l JavaScript -e "JSON.parse($.NSString.stringWithContentsOfFileEncodingError('${VERSION_FILE}', $.NSUTF8StringEncoding, null).js).build" 2>/dev/null || echo "134")
    NEXT_BUILD=$((CURRENT_BUILD + 1))
    
    cat << EOF > "${VERSION_FILE}"
{
  "version": "${CURRENT_VERSION}",
  "build": ${NEXT_BUILD}
}
EOF
    echo "   • Version: ${CURRENT_VERSION}"
    echo "   • Build: ${NEXT_BUILD}"
else
    CURRENT_VERSION="0.1"
    NEXT_BUILD="1"
fi

echo ">> 3. App 번들 생성: ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BIN_PATH}" "${MACOS_DIR}/NudgeLine"
cp "${ROOT_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${CURRENT_VERSION}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string ${CURRENT_VERSION}" "${CONTENTS_DIR}/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEXT_BUILD}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${NEXT_BUILD}" "${CONTENTS_DIR}/Info.plist"

if [[ -f "${ROOT_DIR}/Resources/AppIcon.icns" ]]; then
    cp "${ROOT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

echo ">> 4. Ad-hoc 코드 서명 적용..."
codesign --force --deep -s - "${APP_DIR}"

echo "=== 빌드 및 번들 패키징 완료 (v${CURRENT_VERSION} Build ${NEXT_BUILD}) ==="
echo "생성된 앱 경로: ${APP_DIR}"
echo "직접 실행 명령어: open ${APP_DIR}"
