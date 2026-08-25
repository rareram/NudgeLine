#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ">> 1. 1024x1024 원본 아이콘 생성 중..."
swift "${SCRIPT_DIR}/make_sample_icon.swift" "${ROOT_DIR}/Resources/icon_1024.png"

echo ">> 2. .iconset 구성 중..."
ICONSET_DIR="${ROOT_DIR}/Resources/AppIcon.iconset"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

SRC="${ROOT_DIR}/Resources/icon_1024.png"

sips -z 16 16     "${SRC}" --out "${ICONSET_DIR}/icon_16x16.png" > /dev/null
sips -z 32 32     "${SRC}" --out "${ICONSET_DIR}/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "${SRC}" --out "${ICONSET_DIR}/icon_32x32.png" > /dev/null
sips -z 64 64     "${SRC}" --out "${ICONSET_DIR}/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "${SRC}" --out "${ICONSET_DIR}/icon_128x128.png" > /dev/null
sips -z 256 256   "${SRC}" --out "${ICONSET_DIR}/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "${SRC}" --out "${ICONSET_DIR}/icon_256x256.png" > /dev/null
sips -z 512 512   "${SRC}" --out "${ICONSET_DIR}/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "${SRC}" --out "${ICONSET_DIR}/icon_512x512.png" > /dev/null
sips -z 1024 1024 "${SRC}" --out "${ICONSET_DIR}/icon_512x512@2x.png" > /dev/null

echo ">> 3. iconutil로 AppIcon.icns 생성 중..."
iconutil -c icns "${ICONSET_DIR}" -o "${ROOT_DIR}/Resources/AppIcon.icns"
rm -rf "${ICONSET_DIR}"

echo "=== AppIcon.icns 생성 완료: ${ROOT_DIR}/Resources/AppIcon.icns ==="
