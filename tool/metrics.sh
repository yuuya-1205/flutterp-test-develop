#!/usr/bin/env bash
#
# metrics.sh — テスト品質メトリクスを算出する。
#
#   物理KLOC (lib)   : lib/ 配下の Dart 実装行数（KLOC）
#   テスト件数        : test/ 配下の test(...) / testWidgets(...) / blocTest(...) の数
#   テスト密度        : テスト件数 / 物理KLOC（件/KLOC）
#   バグ密度          : バグ件数 / 物理KLOC（件/KLOC）※バグ件数は引数で渡す
#
# 使い方:
#   tool/metrics.sh            # バグ件数 0 として算出
#   tool/metrics.sh 3          # バグ件数 3 として算出
#
# 参照: .github/skills/test-workflow/SKILL.md
set -euo pipefail

# リポジトリルートへ移動（どこから呼んでも動くように）
cd "$(dirname "$0")/.."

BUG_COUNT="${1:-0}"

# --- 物理LOC（lib/ の .dart、空行を除く実行行の目安）---
if [ -d lib ]; then
  LIB_LOC=$(find lib -name '*.dart' -type f -print0 \
    | xargs -0 grep -vhc '^[[:space:]]*$' 2>/dev/null \
    | awk '{s+=$1} END {print s+0}')
else
  LIB_LOC=0
fi
LIB_KLOC=$(awk "BEGIN {printf \"%.3f\", ${LIB_LOC}/1000}")

# --- テスト件数（test / testWidgets / blocTest の宣言数）---
if [ -d test ]; then
  TEST_COUNT=$(grep -rEo '(blocTest<[^>]*>|testWidgets|test)[[:space:]]*\(' test \
    --include='*.dart' 2>/dev/null | wc -l | tr -d ' ')
else
  TEST_COUNT=0
fi

# --- 密度計算（0除算ガード）---
if [ "${LIB_LOC}" -gt 0 ]; then
  TEST_DENSITY=$(awk "BEGIN {printf \"%.2f\", ${TEST_COUNT}/${LIB_KLOC}}")
  BUG_DENSITY=$(awk "BEGIN {printf \"%.2f\", ${BUG_COUNT}/${LIB_KLOC}}")
else
  TEST_DENSITY="N/A"
  BUG_DENSITY="N/A"
fi

printf '================ metrics ================\n'
printf '物理LOC (lib)     : %s 行\n' "${LIB_LOC}"
printf '物理KLOC (lib)    : %s KLOC\n' "${LIB_KLOC}"
printf 'テスト件数        : %s 件\n' "${TEST_COUNT}"
printf 'テスト密度        : %s 件/KLOC\n' "${TEST_DENSITY}"
printf 'バグ件数          : %s 件\n' "${BUG_COUNT}"
printf 'バグ密度          : %s 件/KLOC\n' "${BUG_DENSITY}"
printf '=========================================\n'
