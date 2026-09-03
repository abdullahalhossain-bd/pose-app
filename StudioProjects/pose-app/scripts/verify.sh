#!/usr/bin/env bash
# Runs the same verification steps as .github/workflows/flutter_ci.yml,
# in the same order, so a failure here is a failure in CI too — no
# surprises after pushing.
#
# This exists because the development sandbox this project was scaffolded
# in has no network access to pub.dev or the Flutter SDK host, so none of
# these steps could be run there. Run this on your own machine, with a
# real Flutter install, before trusting any change.
#
# Usage: ./scripts/verify.sh

set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Flutter version =="
flutter --version

echo
echo "== flutter pub get =="
flutter pub get

echo
echo "== flutter analyze =="
flutter analyze --fatal-infos

echo
echo "== dart format (check only) =="
dart format --output=none --set-exit-if-changed lib test

echo
echo "== flutter test =="
flutter test --reporter expanded

echo
echo "== flutter build apk --debug =="
flutter build apk --debug

echo
echo "All checks passed."
echo "Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
echo
echo "This script does NOT cover real-device checks — see the"
echo "'Device Testing Required' section in docs/P0_VERIFICATION_REPORT.md"
echo "for what still needs a physical phone (background/resume, front-camera"
echo "mirroring direction, low-light behavior, etc)."
