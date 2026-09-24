#!/usr/bin/env bash
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source ./scripts/setup-common.sh
trap 'printf "\nSetup failed at line %s. Fix the error above, then rerun: bash setup.sh\n" "$LINENO" >&2' ERR
[[ "$(uname -s)" == Linux && -f /etc/debian_version ]] || fail 'This script is for Debian-based Linux. Use setup.sh on macOS.'
case "${1:-}" in
    '') setup_main linux ;;
    db) database_main ;;
    check) check_lesson2 ;;
    run) start_main "${2:-8080}" ;;
    *) fail 'Use bash setup.sh [db|run|check].' ;;
esac
