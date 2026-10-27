#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK_SRC="${REPO_ROOT}/scripts/hooks/pre-push.sh"
HOOK_DST="${REPO_ROOT}/.git/hooks/pre-push"

if [[ ! -f "${HOOK_SRC}" ]]; then
    echo "오류: ${HOOK_SRC} 파일이 존재하지 않습니다."
    exit 1
fi

chmod +x "${HOOK_SRC}"
ln -sf "${HOOK_SRC}" "${HOOK_DST}"
echo ">> NudgeLine Git Pre-Push Hook 설치 완료 (${HOOK_DST} -> ${HOOK_SRC})"
echo "   이제부터 'git push' 실행 시 자동으로 사전 단위 테스트 및 태그 검증이 실행됩니다."
echo "   제거 시: ./scripts/hooks/uninstall_hook.sh 실행"
