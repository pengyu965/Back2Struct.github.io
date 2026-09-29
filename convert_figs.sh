#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Render the paper's figure PDFs -> web PNGs (static/images/*.png).
# Sources are the paper's figure folders (default: ../figs and
# ../supplementary_figs, i.e. run this from neurips2026/webpage/).
# Override with:  FIGS=/path/to/figs SUPP=/path/to/supplementary_figs bash convert_figs.sh
#
# Only the figures ACTUALLY used in the paper are converted:
#   Fig 1  comparison            Fig 2  framework (framework_yunjie)
#   Fig 3  dataset_overview      Fig 5  data_samples (new_data_samples)
#   Fig 4  performance (performance_by_sources_v2)
#   Fig 10 qualitative (qualitative_sample)   Fig 11 text2svg (comparison_prompt2svg)
#
# Needs a rasterizer: pdftoppm (poppler) > magick/convert (ImageMagick) > gs.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")"

FIGS="${FIGS:-../figs}"
SUPP="${SUPP:-../supplementary_figs}"
OUT="static/images"
DPI="${DPI:-200}"
mkdir -p "$OUT"

# "src_pdf_path : out_png_basename"
MAP=(
  "$FIGS/comparison.pdf:comparison"
  "$FIGS/framework_yunjie.pdf:framework"
  "$FIGS/dataset_overview.pdf:dataset_overview"
  "$FIGS/new_data_samples.pdf:data_samples"
  "$FIGS/performance_by_sources_v2.pdf:performance"
  "$SUPP/qualitative_sample.pdf:qualitative"
  "$SUPP/comparison_prompt2svg.pdf:text2svg"
)

TOOL=""
for t in pdftoppm magick convert gs; do
  if command -v "$t" >/dev/null 2>&1; then TOOL="$t"; break; fi
done
if [ -z "$TOOL" ]; then
  echo "ERROR: no PDF rasterizer found. Install poppler-utils (pdftoppm), imagemagick, or ghostscript."
  exit 1
fi
echo "Using: $TOOL   DPI=$DPI   FIGS=$FIGS   SUPP=$SUPP"

render() {  # $1=src.pdf  $2=out.png
  case "$TOOL" in
    pdftoppm) pdftoppm -png -r "$DPI" -f 1 -l 1 -singlefile "$1" "${2%.png}" ;;
    magick)   magick -density "$DPI" "${1}[0]" -background white -alpha remove -alpha off -quality 92 "$2" ;;
    convert)  convert -density "$DPI" "${1}[0]" -background white -alpha remove -alpha off -quality 92 "$2" ;;
    gs)       gs -q -dBATCH -dNOPAUSE -sDEVICE=png16m -r"$DPI" -dFirstPage=1 -dLastPage=1 -dUseCropBox -sOutputFile="$2" "$1" ;;
  esac
}

missing=0
for pair in "${MAP[@]}"; do
  in="${pair%%:*}"; out="$OUT/${pair##*:}.png"
  if [ -f "$in" ]; then
    echo "  $in  ->  $out"; render "$in" "$out"
  else
    echo "  MISSING SOURCE: $in"; missing=1
  fi
done
[ "$missing" = 1 ] && echo "NOTE: some sources were missing — check FIGS/SUPP paths."
echo "Done. Preview with:  python3 -m http.server 8000"
