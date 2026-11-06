#!/usr/bin/env bash
# Compiles and tests the Dart templates the skills hand out.
# Usage: tool/verify-templates.sh [flutter-command]   (default: flutter; e.g. "fvm flutter")
set -euo pipefail
FLUTTER=${1:-flutter}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILLS="$ROOT/plugins/iphone-duo/skills"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cd "$WORK"
$FLUTTER create --template=package duo_tpl >/dev/null
cd duo_tpl
$FLUTTER pub add foldable:1.0.5 >/dev/null
rm -rf test lib/*.dart && mkdir -p test lib/src/fold

cp "$SKILLS"/hinge-detection/references/fold/*.dart lib/src/fold/
printf "export 'app_fold_scope.dart';\nexport 'fold_info.dart';\n" > lib/src/fold/fold.dart
cp "$SKILLS"/hinge-avoidance/references/fold_split_view.dart \
   "$SKILLS"/responsive-layout/references/app_content_constraint.dart \
   "$SKILLS"/lifecycle-camera/references/compact_portrait_lock.dart lib/src/
cat > lib/duo_tpl.dart <<'DART'
library;

export 'src/app_content_constraint.dart';
export 'src/compact_portrait_lock.dart';
export 'src/fold/fold.dart';
export 'src/fold_split_view.dart';
DART
cp "$ROOT/tests/templates_test.dart" test/

$FLUTTER analyze
$FLUTTER test
