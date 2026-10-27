#!/usr/bin/env bash
# ==============================================================================
# NudgeLine Git Pre-Push Hook (로컬 사전 자동 검증 훅)
#
# 동작:
# 1. git push 실행 시 자동으로 ./scripts/run_tests.sh를 실행하여 단위 테스트 검증
# 2. 태그 푸시(git push origin v*) 시 태그 버전과 version.json 일치 여부 사전 검증
# 3. 긴급 시 'git push --no-verify' 플래그로 건너뛰기 가능
# 4. 제거 시: rm .git/hooks/pre-push 또는 ./scripts/hooks/uninstall_hook.sh 실행
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO_ROOT}"

echo "========================================================"
echo ">> [Pre-Push Hook] 로컬 사전 자동 검증 시작..."
echo "========================================================"

# 1. 태그 푸시 감지 및 version.json 정합성 검증
while read -r local_ref local_oid remote_ref remote_oid; do
    # 삭제 푸시(000000...)는 건너뜀
    if [[ "${local_oid}" == "0000000000000000000000000000000000000000" ]]; then
        continue
    fi

    if [[ "${local_ref}" =~ ^refs/tags/v ]]; then
        TAG_NAME="${local_ref#refs/tags/}"
        CLEAN_TAG="${TAG_NAME#v}"
        
        VERSION_FILE="${REPO_ROOT}/version.json"
        if [[ -f "${VERSION_FILE}" ]]; then
            EXPECTED_VERSION=$(osascript -l JavaScript -e "
                const v = JSON.parse($.NSString.stringWithContentsOfFileEncodingError('${VERSION_FILE}', $.NSUTF8StringEncoding, null).js);
                v.version + '.' + v.build;
            " 2>/dev/null || echo "")

            if [[ -n "${EXPECTED_VERSION}" && "${CLEAN_TAG}" != "${EXPECTED_VERSION}" ]]; then
                echo "❌ [오류] 태그 버전(${TAG_NAME})이 version.json (${EXPECTED_VERSION})과 일치하지 않습니다!"
                echo "   GitHub Actions 릴리즈 배포(release.yml)가 즉시 실패하므로 푸시를 차단합니다."
                echo "   해결 방법: version.json의 build 번호를 확인하거나 올바른 태그로 다시 생성하세요."
                exit 1
            fi
            echo "   • 태그 버전 정합성 검증 통과: ${TAG_NAME} == version.json (${EXPECTED_VERSION})"
        fi
    fi
done

# 2. 전체 단위 테스트 실행
echo ">> 단위 테스트(run_tests.sh) 자동 검증 중..."
if ! ./scripts/run_tests.sh; then
    echo "========================================================"
    echo "❌ [오류] 단위 테스트 검증에 실패하여 git push가 중단되었습니다."
    echo "   코드를 수정한 후 다시 푸시하거나,"
    echo "   긴급 시 'git push --no-verify' 플래그를 사용하여 건너뛸 수 있습니다."
    echo "========================================================"
    exit 1
fi

echo "========================================================"
echo ">> [Pre-Push Hook] 모든 사전 검증 통과 (GitHub로 푸시를 진행합니다)"
echo "========================================================"
exit 0
