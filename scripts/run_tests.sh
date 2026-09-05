#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== NudgeLine 단위 테스트(Unit Tests) 실행 ==="

TEST_ARGS=()
if [[ ! -d "/Applications/Xcode.app" ]]; then
    TEST_ARGS+=(--build-system native)
    if [[ -z "${SDKROOT:-}" && -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk" ]]; then
        export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
    fi
    CLT_FRAMEWORKS="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
    CLT_USRLIB="/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
    if [[ -d "${CLT_FRAMEWORKS}" ]]; then
        TEST_ARGS+=(-Xswiftc -F -Xswiftc "${CLT_FRAMEWORKS}")
        TEST_ARGS+=(-Xlinker -rpath -Xlinker "${CLT_FRAMEWORKS}")
    fi
    if [[ -d "${CLT_USRLIB}" ]]; then
        TEST_ARGS+=(-Xlinker -rpath -Xlinker "${CLT_USRLIB}")
    fi
fi

swift test "${TEST_ARGS[@]}" "$@"
