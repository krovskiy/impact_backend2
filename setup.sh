#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
case "${1:-check}" in
  db) printf 'H2 starts inside Java automatically. Run: bash setup.sh run\n'; exit 0 ;;
  run|check)
    if ! command -v mvn >/dev/null 2>&1; then
      environment="$HOME/.local/share/impact-backend/toolchains/env.sh"
      if [[ -f "$environment" ]]; then source "$environment"; fi
    fi
    command -v mvn >/dev/null 2>&1 || { printf 'Install Java 21 and Maven, or run: bash setup.sh install\n' >&2; exit 1; }
    if [[ "${1:-check}" == check ]]; then exec mvn --batch-mode --no-transfer-progress test; fi
    port=${2:-8080}
    if [[ ! "$port" =~ ^[1-9][0-9]{0,4}$ ]] || (( port > 65535 )); then printf 'Port must be 1-65535.\n' >&2; exit 1; fi
    exec mvn spring-boot:run "-Dspring-boot.run.arguments=--server.port=$port" ;;
  install|redis)
    if [[ "$1" == redis ]]; then set -- redis; else set --; fi
    case "$(uname -s)" in
      Darwin) exec bash scripts/setup-macos.sh "$@" ;;
      Linux) exec bash scripts/setup-debian.sh "$@" ;;
      *) printf 'Use setup.cmd on Windows.\n' >&2; exit 1 ;;
    esac ;;
  *) printf 'Use bash setup.sh [run [port]|check|db|install|redis].\n' >&2; exit 1 ;;
esac
