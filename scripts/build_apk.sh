#!/usr/bin/env bash
# Builds a release APK stamped with the git state it came from, so an install
# on a device can be traced back to a branch and commit.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//' | tr -d '[:space:]')
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT=$(git rev-parse --short HEAD)
BUILT_AT=$(date -u '+%Y-%m-%d %H:%M UTC')

# Uncommitted changes mean the APK does not match the commit it names.
if ! git diff --quiet || ! git diff --cached --quiet; then
  COMMIT="${COMMIT}-dirty"
fi

echo "Building ${VERSION} · ${BRANCH} · ${COMMIT}"

flutter build apk --release \
  --dart-define=APP_VERSION="${VERSION}" \
  --dart-define=GIT_BRANCH="${BRANCH}" \
  --dart-define=GIT_COMMIT="${COMMIT}" \
  --dart-define=BUILT_AT="${BUILT_AT}" \
  "$@"
