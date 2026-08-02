#!/usr/bin/env bash
#
# Shrinks the artwork in assets/v3/ to what the app actually renders.
#
# The exports arrive at 1024x1024 (or larger) and ~1.2 MB each, regardless of
# whether a screen shows them at 330dp or 34dp. Two passes fix that:
#
#   1. Resize to 3x the largest width any screen renders the asset at. 3x
#      covers every mainstream Android and iOS density (the reporter's A52 is
#      2.625x), and Flutter downsamples cleanly below that.
#   2. Quantise to an 8-bit palette (pngquant), then losslessly re-pack
#      (oxipng). These are flat-shaded illustrations with soft shadows, so a
#      palette holds up; the quality floor below aborts rather than shipping a
#      banded image.
#
# The widths come from the DesignImage call sites. When artwork or a layout
# changes, update TARGETS and re-run. Re-running on already-optimised files is
# safe — resize never upscales, and pngquant skips images already at or below
# the target palette.
#
# Requires: pngquant, oxipng (brew install pngquant oxipng). sips ships with
# macOS.
#
# Usage:  tool/optimize_assets.sh [--dry-run]

set -euo pipefail

cd "$(dirname "$0")/.."
DIR="assets/v3"
DRY_RUN=${1:-}

# asset : largest width rendered, in logical pixels
TARGETS="
logo.png:200
running.png:306
onboard-1.png:322
onboard-2.png:322
onboard-3.png:322
sign-in.png:300
sign-up.png:186
forgot-password.png:334
verify-code.png:270
reset-password.png:280
owner-details.png:120
analyzing.png:330
great-job.png:270
vet-alert.png:230
order-placed.png:280
order-tracking.png:150
emo-happy.png:160
emo-tilt.png:160
emo-question.png:160
emo-sleep.png:160
emo-excited.png:160
emo-surprised.png:160
emo-thinking.png:160
emo-worried.png:160
emo-determined.png:160
"

# Density multiplier. 3x is the highest mainstream device density.
SCALE=3

# pngquant gives up rather than producing a visibly degraded image below this.
MIN_QUALITY=70
MAX_QUALITY=95

before_total=0
after_total=0

for entry in $TARGETS; do
  name="${entry%%:*}"
  dp="${entry##*:}"
  file="$DIR/$name"

  [ -f "$file" ] || { echo "skip (absent): $name"; continue; }

  target=$((dp * SCALE))
  before=$(stat -f%z "$file")
  width=$(sips -g pixelWidth "$file" | awk '/pixelWidth/{print $2}')

  if [ -n "$DRY_RUN" ]; then
    printf '%-24s %5s px -> %4s px  %6s KB\n' \
      "$name" "$width" "$target" "$((before / 1024))"
    continue
  fi

  # Never upscale: an asset already smaller than its target is left alone.
  if [ "$width" -gt "$target" ]; then
    sips --resampleWidth "$target" "$file" >/dev/null
  fi

  pngquant --quality="$MIN_QUALITY-$MAX_QUALITY" --skip-if-larger \
    --strip --force --output "$file" -- "$file" 2>/dev/null || true

  oxipng --quiet --opt 4 --strip safe "$file"

  after=$(stat -f%z "$file")
  before_total=$((before_total + before))
  after_total=$((after_total + after))

  printf '%-24s %6s KB -> %5s KB  (-%s%%)\n' \
    "$name" "$((before / 1024))" "$((after / 1024))" \
    "$(((before - after) * 100 / before))"
done

[ -n "$DRY_RUN" ] && exit 0

echo
printf 'total: %s KB -> %s KB  (-%s%%)\n' \
  "$((before_total / 1024))" "$((after_total / 1024))" \
  "$(((before_total - after_total) * 100 / before_total))"
