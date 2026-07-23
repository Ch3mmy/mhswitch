#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${MHSWITCH_SCRIPT:-$ROOT_DIR/mhswitch}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

export MIHOMO_HOME="$WORKDIR/mihomo"
export MIHOMO_CONTROLLER="http://127.0.0.1:1"
export MHSWITCH_FORCE_INTERACTIVE=1
export MHSWITCH_NO_EMOJI=1
mkdir -p "$MIHOMO_HOME/providers"

LIB="$WORKDIR/mhswitch-lib.sh"
awk '/^# ----------------- Command Dispatcher -----------------$/ { exit } { print }' "$SCRIPT" > "$LIB"
# shellcheck disable=SC1090
source "$LIB"

fail() {
  echo "ui interaction test failed: $*" >&2
  exit 1
}

declare -F panel_runtime_snapshot >/dev/null || fail "missing panel_runtime_snapshot"

subscription_source_valid "https://example.test/subscription" || fail "HTTPS subscription rejected"
if subscription_source_valid "ftp://example.test/subscription"; then
  fail "unsupported subscription scheme accepted"
fi

MENU_LABELS=("第一项" "第二项" "第三项")
MENU_VALUES=("one" "two" "three")
MENU_SELECTION=""
MENU_SELECTION_LABEL=""
choose_menu "测试菜单" "状态" "正常" <<< "2" >/dev/null
[[ "$MENU_SELECTION" == "two" ]] || fail "number shortcut did not select second item"
[[ "$MENU_SELECTION_LABEL" == "第二项" ]] || fail "number shortcut returned wrong label"

cat > "$STATE_FILE" <<'JSON'
{
  "airports": [
    {"id": "a_one", "name": "机场一", "url": "", "exclude_regex": ""},
    {"id": "a_two", "name": "机场二", "url": "", "exclude_regex": ""}
  ]
}
JSON

panel_runtime_snapshot
[[ "$PANEL_SERVICE_STATUS" == "未运行" ]] || fail "unexpected stopped service label"
[[ "$PANEL_MODE_STATUS" == "-" ]] || fail "unexpected stopped mode"
[[ "$PANEL_AIRPORT_COUNT" == "2" ]] || fail "airport count is not 2"
[[ "$PANEL_OPENAI_STATUS" == "-" ]] || fail "unexpected stopped OpenAI strategy"

grep -Fq 'panel_confirm "确认停止 Mihomo"' "$SCRIPT" || fail "stop confirmation missing"
grep -Fq 'panel_confirm "确认重启 Mihomo"' "$SCRIPT" || fail "restart confirmation missing"
grep -Fq 'panel_confirm "确认切断所有现有连接"' "$SCRIPT" || fail "flush confirmation missing"

echo "ui interaction regression test passed"
