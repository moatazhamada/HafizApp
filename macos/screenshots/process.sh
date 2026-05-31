#!/bin/bash
# Process raw macOS screenshots into App Store Connect format (2880x1800, no distortion).
# Each image is scaled to FIT inside 2880x1800 (aspect preserved), then padded/centered on a
# solid background to reach exactly 2880x1800. Output is a crisp PNG.
#
# Capture the app window with Cmd+Shift+4 -> Space -> Option+click (Option drops the drop-shadow,
# giving an opaque rectangle with no transparent border). Save raws into ./raw, then run this.
#
# Usage:  ./process.sh [PAD_HEX]      (PAD_HEX defaults to FFFFFF / white for the light theme)
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
RAW="$DIR/raw"
OUT="$DIR/final"
PAD="${1:-FFFFFF}"
TW=2880; TH=1800

mkdir -p "$OUT"
rm -f "$OUT"/*.png 2>/dev/null || true
shopt -s nullglob nocaseglob
files=("$RAW"/*.png "$RAW"/*.jpg "$RAW"/*.jpeg)
[ ${#files[@]} -eq 0 ] && { echo "No images in $RAW — drop your captures there first."; exit 0; }

i=0
for f in "${files[@]}"; do
  i=$((i+1))
  w=$(sips -g pixelWidth  "$f" | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')
  read nw nh < <(awk -v w="$w" -v h="$h" -v TW="$TW" -v TH="$TH" \
    'BEGIN{s=TW/w; if(TH/h<s)s=TH/h; printf "%d %d", (w*s)+0.5, (h*s)+0.5}')
  out="$OUT/$(printf '%02d' "$i")_$(basename "${f%.*}").png"
  sips -s format png "$f" --out "$out" >/dev/null
  sips --resampleHeightWidth "$nh" "$nw" "$out" --out "$out" >/dev/null
  sips --padToHeightWidth "$TH" "$TW" --padColor "$PAD" "$out" --out "$out" >/dev/null
  dims=$(sips -g pixelWidth -g pixelHeight "$out" | awk '/pixel/{printf "%sx",$2}' | sed 's/x$//')
  alpha=$(sips -g hasAlpha "$out" | awk '/hasAlpha/{print $2}')
  warn=""; [ "$alpha" = "yes" ] && warn="  ⚠ has alpha (recapture with Option to drop shadow)"
  echo "✓ $(basename "$out")  ${dims}px${warn}"
done
echo "Done -> $OUT"
