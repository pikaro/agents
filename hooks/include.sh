set -eEuo pipefail

# shellcheck source=../../dotinc/entrypoint.sh
. "${HOME}/.local/shell-include/entrypoint.sh"

HOOK_NAME="$(basename "$0")"

STDIN="$(cat -)"

read -r ROOT SESSION_ID < <(echo "${STDIN}" | jq -r '[.cwd, .session_id] | @tsv')

SESSION_LOG_DIR="/tmp/codex/${SESSION_ID}/${ROOT}"
mkdir -p "${SESSION_LOG_DIR}" || _fatal "Failed to create log directory at ${SESSION_LOG_DIR}"

SESSION_LOG_FILE="${SESSION_LOG_DIR}/${HOOK_NAME}.log"

exec 2>>"${SESSION_LOG_FILE}"

cd "${ROOT}" || _fatal "Failed to change directory to ${ROOT}"

_info "Changed to directory: ${ROOT}"

export ROOT SESSION_ID SESSION_LOG_DIR SESSION_LOG_FILE HOOK_NAME
