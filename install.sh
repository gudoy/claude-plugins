#!/usr/bin/env bash
# Install, reinstall or update the Claude Code plugins listed in plugins.txt.
# macOS, Linux, WSL and Git Bash. Windows PowerShell: use install.ps1.
#
#   ./install.sh            add missing marketplaces, install missing plugins, update the rest
#   ./install.sh --export   rewrite plugins.txt from the plugins installed on this machine
#
# Remote one-liner:
#   curl -fsSL https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.sh | bash
set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/gudoy/claude-plugins/main/plugins.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
MANIFEST="$SCRIPT_DIR/plugins.txt"

command -v claude >/dev/null || { echo "claude CLI not found: https://docs.claude.com/en/docs/claude-code/setup" >&2; exit 1; }

# Clone GitHub repos over HTTPS so a machine without SSH keys (or with a stuck SSH agent) still works.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf" GIT_CONFIG_VALUE_0="git@github.com:"

# Plugins synced from claude.ai (@synced) are managed by the account, not by this script.
installed_marketplaces() { claude plugin marketplace list 2>/dev/null | sed -n 's/^ *❯ *//p'; }
installed_plugins()      { claude plugin list 2>/dev/null | sed -n 's/^ *❯ *//p' | grep -v '@synced$' || true; }

export_manifest() {
  {
    echo "# Claude Code plugins manifest, read by install.sh / install.ps1."
    echo "# Regenerate with: ./install.sh --export"
    echo "# marketplace <name> <source>   source = GitHub owner/repo, git URL, or 'builtin'"
    echo "# plugin <name@marketplace>"
    echo
    claude plugin marketplace list 2>/dev/null | awk '
      /❯/ { sub(/^ *❯ */, ""); name = $0; next }
      /Source:/ && name != "" {
        src = $0; sub(/^ *Source: */, "", src)
        if (src ~ /^Built in/) src = "builtin"
        else { sub(/^[^(]*\(/, "", src); sub(/\)$/, "", src) }
        print "marketplace " name " " src; name = ""
      }' | sort
    echo
    installed_plugins | sort | sed 's/^/plugin /'
  } > "$MANIFEST"
  echo "Wrote $MANIFEST ($(grep -c '^plugin ' "$MANIFEST") plugins)."
}

sync_plugins() {
  if [[ ! -f "$MANIFEST" ]]; then
    MANIFEST="$(mktemp)"
    curl -fsSL "$RAW_URL" -o "$MANIFEST"
  fi
  local have_mkt have_plg failed=()
  have_mkt="$(installed_marketplaces)"
  have_plg="$(installed_plugins)"

  while read -r kind name src; do
    [[ "$kind" == marketplace && "$src" != builtin ]] || continue
    if grep -qx "$name" <<<"$have_mkt"; then
      echo "↻ marketplace $name"
      claude plugin marketplace update "$name" >/dev/null 2>&1 || failed+=("marketplace update $name")
    else
      echo "+ marketplace $name ($src)"
      claude plugin marketplace add "$src" >/dev/null 2>&1 || failed+=("marketplace add $src")
    fi
  done < "$MANIFEST"

  while read -r kind id _; do
    [[ "$kind" == plugin ]] || continue
    if grep -qx "$id" <<<"$have_plg"; then
      echo "↻ $id"
      claude plugin update "$id" >/dev/null 2>&1 || failed+=("update $id")
    else
      echo "+ $id"
      claude plugin install "$id" >/dev/null 2>&1 || failed+=("install $id")
    fi
  done < "$MANIFEST"

  echo
  if ((${#failed[@]})); then
    printf 'Failed (%d):\n' "${#failed[@]}"; printf '  %s\n' "${failed[@]}"
    exit 1
  fi
  echo "Done. Restart Claude Code (or run /reload-plugins) to load the changes."
}

case "${1:-}" in
  --export) export_manifest ;;
  ""|--install) sync_plugins ;;
  *) echo "usage: $0 [--install|--export]" >&2; exit 2 ;;
esac
