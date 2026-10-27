#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK_DST="${REPO_ROOT}/.git/hooks/pre-push"

if [[ -e "${HOOK_DST}" || -L "${HOOK_DST}" ]]; then
    rm -f "${HOOK_DST}"
    echo ">> NudgeLine Git Pre-Push Hook 제거 완료 (${HOOK_DST} 삭제됨)"
    echo "   이제 'git push' 실행 시 사전 검증 없이 즉시 원격으로 푸시됩니다."
else
    echo ">> 설치된 Pre-Push Hook이 없습니다."
fi
