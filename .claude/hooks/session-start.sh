#!/bin/bash
# SessionStart hook for Claude Code on the web.
# MATLAB is not available in web sessions, so this installs the tools used
# for static verification instead:
#   - MISS_HIT (mh_lint): MATLAB parser/linter       -> `mh_lint .`
#   - numpy + networkx: optional graph cross-check   -> scripts/reference/audit_dataset_reference.py --graph
# Idempotent: pip skips packages that are already installed.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

python3 -m pip install --quiet --disable-pip-version-check --root-user-action=ignore \
  miss_hit numpy networkx

echo "session-start: $(mh_lint --version 2>/dev/null | head -n1) ready; run 'mh_lint .' for static MATLAB checks"
