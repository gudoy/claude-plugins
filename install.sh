#!/usr/bin/env bash
# Install, reinstall or update the Claude Code plugins and skills listed in plugins.txt.
# macOS, Linux, WSL and Git Bash. Windows PowerShell: use install.ps1.
#
#   ./install.sh                  all plugins: add missing marketplaces, install missing plugins, update the rest
#   ./install.sh caveman headroom   only the named plugins
#   ./install.sh --pick           choose from a numbered list
#   ./install.sh --export         add plugins installed on this machine but not yet listed in plugins.txt
#
# Remote one-liner (append "-s -- --pick" or "-s -- <names>" to select):
#   curl -fsSL https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.sh | bash
set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/gudoy/claude-plugins/main/plugins.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
MANIFEST="$SCRIPT_DIR/plugins.txt"

usage() { sed -n '4,8p' "$0" 2>/dev/null | sed 's/^# *//'; exit "${1:-0}"; }

command -v claude >/dev/null || { echo "claude CLI not found: https://docs.claude.com/en/docs/claude-code/setup" >&2; exit 1; }

# Clone GitHub repos over HTTPS so a machine without SSH keys (or with a stuck SSH agent) still works.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf" GIT_CONFIG_VALUE_0="git@github.com:"

# Plugins synced from claude.ai (@synced) are managed by the account, not by this script.
installed_plugins() { claude plugin list 2>/dev/null | sed -n 's/^ *❯ *//p' | grep -v '@synced$' || true; }
# "<name> <source>" for each marketplace configured on this machine.
installed_marketplaces() {
  claude plugin marketplace list 2>/dev/null | awk '
    /❯/ { sub(/^ *❯ */, ""); name = $0; next }
    /Source:/ && name != "" {
      src = $0; sub(/^ *Source: */, "", src)
      if (src ~ /^Built in/) src = "builtin"
      else { sub(/^[^(]*\(/, "", src); sub(/\)$/, "", src) }
      print name " " src; name = ""
    }'
}

manifest_ids() { awk -v k="$1" '$1 == k { print $2 }' "$MANIFEST"; }
marketplace_source() { awk -v n="$1" '$1 == "marketplace" && $2 == n { print $3 }' "$MANIFEST"; }
skill_source() { awk -v n="$1" '$1 == "skill" && $2 == n { print $3 }' "$MANIFEST"; }

export_new() {
  local known new mkts added=0 id mkt
  known="$(manifest_ids plugin; manifest_ids exclude)"
  new="$(installed_plugins | grep -vxF "$known" || true)"
  mkts="$(installed_marketplaces)"
  for id in $new; do
    mkt="${id#*@}"
    if [[ -z "$(marketplace_source "$mkt")" ]]; then
      echo "marketplace $(grep "^$mkt " <<<"$mkts")" >> "$MANIFEST"
    fi
    echo "plugin $id" >> "$MANIFEST"
    echo "+ $id"
    added=$((added + 1))
  done
  echo "Added $added plugin(s) to $MANIFEST. Change 'plugin' to 'exclude' for any you do not want to share."
}

# Prints the selected plugin ids and skill names, one per line.
select_plugins() {
  local all; all="$(manifest_ids plugin; manifest_ids skill)"
  if [[ "$MODE" == pick ]]; then
    local i=0 id; local -a ids=()
    for id in $all; do ids+=("$id"); i=$((i + 1)); printf '%3d) %s\n' "$i" "$id" >&2; done
    printf 'Numbers or ranges (e.g. "1 4 7-9"), or "all": ' >&2
    local answer tok n; read -r answer < /dev/tty
    [[ "$answer" == all ]] && { echo "$all"; return; }
    for tok in $answer; do
      if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        for ((n = BASH_REMATCH[1]; n <= BASH_REMATCH[2]; n++)); do ((n >= 1 && n <= ${#ids[@]})) && echo "${ids[n - 1]}"; done
      elif [[ "$tok" =~ ^[0-9]+$ ]] && ((tok >= 1 && tok <= ${#ids[@]})); then
        echo "${ids[tok - 1]}"
      else
        echo "Ignored: $tok" >&2
      fi
    done | awk '!seen[$0]++'
  elif ((${#NAMES[@]})); then
    local name match
    for name in "${NAMES[@]}"; do
      match="$(grep -E "^${name}(@|$)" <<<"$all" || true)"
      [[ -n "$match" ]] && echo "$match" || echo "Not in plugins.txt: $name" >&2
    done
  else
    echo "$all"
  fi
}

sync_plugins() {
  local selected skills have_mkt have_plg mkt src id name failed=()
  selected="$(select_plugins)"
  [[ -n "$selected" ]] || { echo "Nothing selected."; exit 1; }
  # Plugin ids contain "@"; skill names do not.
  skills="$(grep -v '@' <<<"$selected" || true)"
  selected="$(grep '@' <<<"$selected" || true)"
  have_mkt="$(installed_marketplaces | cut -d' ' -f1)"
  have_plg="$(installed_plugins)"

  for mkt in $(sed 's/.*@//' <<<"$selected" | sort -u); do
    src="$(marketplace_source "$mkt")"
    [[ "$src" == builtin ]] && continue
    if grep -qx "$mkt" <<<"$have_mkt"; then
      echo "↻ marketplace $mkt"
      claude plugin marketplace update "$mkt" >/dev/null 2>&1 || failed+=("marketplace update $mkt")
    elif [[ -n "$src" ]]; then
      echo "+ marketplace $mkt ($src)"
      claude plugin marketplace add "$src" >/dev/null 2>&1 || failed+=("marketplace add $src")
    else
      failed+=("no 'marketplace $mkt' line in plugins.txt")
    fi
  done

  for id in $selected; do
    if grep -qx "$id" <<<"$have_plg"; then
      echo "↻ $id"
      claude plugin update "$id" >/dev/null 2>&1 || failed+=("update $id")
    else
      echo "+ $id"
      claude plugin install "$id" >/dev/null 2>&1 || failed+=("install $id")
    fi
  done

  # Standalone skills (no plugin marketplace) go through the Skills CLI; "add" also updates.
  for name in $skills; do
    src="$(skill_source "$name")"
    echo "+ skill $name ($src)"
    (cd "$HOME" && npx -y skills add "$src" --skill "$name" --global --agent claude-code --yes) >/dev/null 2>&1 \
      || failed+=("skill $name (needs Node.js/npx)")
  done

  echo
  if ((${#failed[@]})); then
    printf 'Failed (%d):\n' "${#failed[@]}"; printf '  %s\n' "${failed[@]}"
    exit 1
  fi
  echo "Done. Restart Claude Code (or run /reload-plugins) to load the changes."
}

MODE=install
NAMES=()
for arg in "$@"; do
  case "$arg" in
    --export) MODE=export ;;
    --pick) MODE=pick ;;
    -h|--help) usage ;;
    -*) usage 2 >&2 ;;
    *) NAMES+=("$arg") ;;
  esac
done

if [[ ! -f "$MANIFEST" ]]; then
  [[ "$MODE" == export ]] && { echo "--export needs a local clone of the repository." >&2; exit 1; }
  MANIFEST="$(mktemp)"
  curl -fsSL "$RAW_URL" -o "$MANIFEST"
fi

if [[ "$MODE" == export ]]; then export_new; else sync_plugins; fi
