#!/usr/bin/env bash
# ============================================================
# reprovision.sh - Re-run Ansible without recreating VMs
# Usage: ./scripts/reprovision.sh [--tags <tag1,tag2>]
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"

TAGS="${1:-}"
EXTRA_ARGS=""
[[ -n "$TAGS" ]] && EXTRA_ARGS="--tags $TAGS"

ansible-playbook \
  -i inventory/hosts.ini \
  playbooks/site.yml \
  $EXTRA_ARGS \
  "$@"
