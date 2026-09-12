#!/usr/bin/env bash
# adopt.sh'ın ürettiği ci.yml'in karar defterindeki kararları
# (05-karar-defteri.md) bozmadığını doğrular. Belgeye yazılan bir kural,
# burada bir satır olmadan kendini korumaz — bugün paths-ignore'da
# fastlane/metadata'nın (K9) sessizce geri sızdığı fark edilmeden yedi
# projeye yayılmıştı. Bu script onu bir daha yakalar.
#
# Kullanım: scripts/test-adopt.sh   (apple-ci kökünden)

set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FAIL=0

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAIL=1; }

not_contains() { # açıklama, dosya, desen
  if grep -q -- "$3" "$2"; then fail "$1"; else pass "$1"; fi
}
contains() { # açıklama, dosya, desen
  if grep -q -- "$3" "$2"; then pass "$1"; else fail "$1"; fi
}

echo "== Senaryo: --self-hosted --notify =="
TMP=$(mktemp -d)
"$HERE/scripts/adopt.sh" "$TMP" --scheme Ornek --project Ornek.xcodeproj --self-hosted --notify >/dev/null
CI="$TMP/.github/workflows/ci.yml"

not_contains "K9: fastlane/metadata paths-ignore'da YOK" "$CI" 'fastlane/metadata'
if [ "$(grep -c 'runs-on: self-hosted' "$CI")" = "2" ]; then
  pass "--self-hosted her iki job'ı da kapsıyor"
else
  fail "--self-hosted her iki job'ı da kapsıyor"
fi
contains "--notify ULAK bildirimini açıyor" "$CI" 'notify: true'

rm -rf "$TMP"

echo
echo "== Senaryo: bayraksız (varsayılan) =="
TMP=$(mktemp -d)
"$HERE/scripts/adopt.sh" "$TMP" --scheme Ornek --project Ornek.xcodeproj >/dev/null
CI="$TMP/.github/workflows/ci.yml"

not_contains "K9: fastlane/metadata paths-ignore'da YOK" "$CI" 'fastlane/metadata'
not_contains "--notify verilmeden 'notify:' satırı hiç yok" "$CI" 'notify:'

rm -rf "$TMP"

echo
if [ "$FAIL" = 1 ]; then
  echo "BAŞARISIZ — adopt.sh, karar defteriyle çelişen bir dosya üretiyor."
  exit 1
fi
echo "Hepsi geçti."
