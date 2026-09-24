#!/usr/bin/env bash
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source ./scripts/setup-common.sh
trap 'printf "\nSetup failed at line %s. Fix the error above, then rerun: bash setup.sh\n" "$LINENO" >&2' ERR
[[ "$(uname -s)" == Darwin ]] || fail 'This script is for macOS. Use setup.cmd on Windows or setup.sh on Debian.'
case "${1:-}" in
    '') setup_main mac ;;
    redis) redis_main mac ;;
    db) database_main ;;
    check) check_lessons ;;
    run) start_main "${2:-8080}" ;;
    *) fail 'Use bash setup.sh [redis|db|run|check].' ;;
esac
