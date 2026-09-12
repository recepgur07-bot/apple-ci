#!/usr/bin/env bash
# Bir Apple projesine ortak CI çağırıcısını ekler.
# Mevcut dosyanın üzerine sormadan yazmaz.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

usage() {
  cat >&2 <<'USAGE'
Kullanım:
  adopt.sh <proje-yolu> --scheme <ad> [--project X.xcodeproj | --workspace X.xcworkspace]
                        [--destination '...'] [--no-xcodegen] [--no-tests]
                        [--extra-checks 'komut'] [--self-hosted]
                        [--runs-on <ad>] [--checks-runs-on <ad>] [--force]

--self-hosted: hem derleme/test hem hızlı kontroller job'ını self-hosted'a
alır (--runs-on self-hosted --checks-runs-on self-hosted ile aynı).
USAGE
  exit 2
}

[ "$#" -ge 1 ] || usage
TARGET=$1; shift
[ -d "$TARGET" ] || { echo "Proje klasörü yok: $TARGET" >&2; exit 2; }

scheme=""; project=""; workspace=""; destination="platform=iOS Simulator,name=iPhone 17"
xcodegen=true; tests=true; extra=""; force=false; runson=""; checksrunson=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --scheme) scheme=${2:-}; shift 2 ;;
    --project) project=${2:-}; shift 2 ;;
    --workspace) workspace=${2:-}; shift 2 ;;
    --destination) destination=${2:-}; shift 2 ;;
    --extra-checks) extra=${2:-}; shift 2 ;;
    --runs-on) runson=${2:-}; shift 2 ;;
    --checks-runs-on) checksrunson=${2:-}; shift 2 ;;
    --self-hosted) runson="self-hosted"; checksrunson="self-hosted"; shift ;;
    --no-xcodegen) xcodegen=false; shift ;;
    --no-tests) tests=false; shift ;;
    --force) force=true; shift ;;
    *) usage ;;
  esac
done

[ -n "$scheme" ] || usage

mkdir -p "$TARGET/.github/workflows"
CI="$TARGET/.github/workflows/ci.yml"

if [ -e "$CI" ] && [ "$force" != true ]; then
  echo "Zaten var: $CI" >&2
  echo "Üzerine yazmak için --force ver. Önce içeriğini incele." >&2
  exit 1
fi

{
  echo "name: CI"
  echo
  echo "on:"
  echo "  workflow_dispatch:"
  echo "  pull_request:"
  echo "  push:"
  echo "    branches: [main]"
  echo "    paths-ignore:"
  echo '      - "docs/**"'
  echo '      - "fastlane/metadata/**"'
  echo '      - "fastlane/screenshots/**"'
  echo '      - "**/*.md"'
  echo
  echo "concurrency:"
  echo '  group: ci-${{ github.ref }}'
  echo "  cancel-in-progress: true"
  echo
  echo "jobs:"
  echo "  ci:"
  echo "    uses: recepgur07-bot/apple-ci/.github/workflows/apple-ci.yml@main"
  echo "    with:"
  echo "      scheme: $scheme"
  [ -n "$project" ]   && echo "      project: $project"
  [ -n "$workspace" ] && echo "      workspace: $workspace"
  echo "      destination: \"$destination\""
  echo "      xcodegen: $xcodegen"
  [ "$tests" = true ] || echo "      run-tests: false"
  [ -n "$runson" ] && echo "      runs-on: $runson"
  [ -n "$checksrunson" ] && echo "      checks-runs-on: $checksrunson"
  [ -n "$extra" ] && echo "      extra-checks: $extra"
} > "$CI"

DEP="$TARGET/.github/dependabot.yml"
if [ ! -e "$DEP" ]; then
  cp "$HERE/templates/dependabot.yml" "$DEP"
  echo "yazıldı: $DEP"
fi

echo "yazıldı: $CI"
