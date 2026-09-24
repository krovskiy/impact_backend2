#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case "$(uname -s)" in
    Darwin) exec bash "$project_dir/scripts/setup-macos.sh" "$@" ;;
    Linux) exec bash "$project_dir/scripts/setup-debian.sh" "$@" ;;
    *) printf 'On Windows, double-click setup.cmd.\n' >&2; exit 1 ;;
esac
