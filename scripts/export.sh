#!/usr/bin/env bash
# =============================================================================
# export.sh – Golden Gardens Page Export Pipeline
# =============================================================================
# Usage:
#   bash scripts/export.sh <page-id> [output-type]
#
# Arguments:
#   page-id      Unique identifier for the page, e.g. "safety-page"
#   output-type  One of: all | content | shopify | liquid  (default: all)
#
# Examples:
#   bash scripts/export.sh safety-page
#   bash scripts/export.sh safety-page content
#   bash scripts/export.sh safety-page liquid
#
# What it does:
#   Reads pages/<page-id>/normalized/normalized.html and generates one or more
#   output files under pages/<page-id>/output/:
#     content-only.html   – bare HTML fragment for Shopify page editor
#     shopify-page.html   – full standalone HTML preview
#     shopify-liquid.html – Liquid template for a Shopify theme
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGE_ID="${1:-}"
OUTPUT_TYPE="${2:-all}"
TODAY="$(date +%Y-%m-%d)"

# ── Validate arguments ────────────────────────────────────────────────────────
if [[ -z "$PAGE_ID" ]]; then
  echo "ERROR: page-id is required."
  echo "Usage: bash scripts/export.sh <page-id> [output-type]"
  exit 1
fi

NORM_FILE="$REPO_ROOT/pages/$PAGE_ID/normalized/normalized.html"
OUT_DIR="$REPO_ROOT/pages/$PAGE_ID/output"

if [[ ! -f "$NORM_FILE" ]]; then
  echo "ERROR: Normalized file not found: $NORM_FILE"
  echo "Run import first: bash scripts/import.sh $PAGE_ID"
  exit 1
fi

mkdir -p "$OUT_DIR"

# ── Read page title from manifest ─────────────────────────────────────────────
PAGE_TITLE=$(python3 - "$REPO_ROOT/library/manifest.json" "$PAGE_ID" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    manifest = json.load(f)
page = next((p for p in manifest["pages"] if p["id"] == sys.argv[2]), None)
print(page["title"] if page else sys.argv[2].replace("-", " ").title())
PY
)

# ── Shared badge block (inline for portability) ───────────────────────────────
BADGES_BLOCK='<!-- Trust Badges -->
<div class="gg-badges" role="list" aria-label="Golden Gardens quality badges">
  <div class="gg-badge gg-badge--lab-tested" role="listitem">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22" height="22" aria-hidden="true" focusable="false"><path fill="#4caf50" d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
    <span>Lab Tested</span>
  </div>
  <div class="gg-badge gg-badge--discreet-delivery" role="listitem">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22" height="22" aria-hidden="true" focusable="false"><path fill="#1976d2" d="M20 8h-3V4H3c-1.1 0-2 .9-2 2v11h2c0 1.66 1.34 3 3 3s3-1.34 3-3h6c0 1.66 1.34 3 3 3s3-1.34 3-3h2v-5l-3-4zM6 18.5c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm13.5-9l1.96 2.5H17V9.5h2.5zm-1.5 9c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/></svg>
    <span>Discreet Delivery</span>
  </div>
  <div class="gg-badge gg-badge--high-terpene" role="listitem">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22" height="22" aria-hidden="true" focusable="false"><path fill="#ff9800" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14H9V8h2v8zm4 0h-2V8h2v8z"/></svg>
    <span>High Terpene</span>
  </div>
</div>'

# ── Extract inner content from normalized file ────────────────────────────────
# Strips the outer <article> wrapper and HTML comment header to get just content
INNER_CONTENT=$(python3 - "$NORM_FILE" <<'PY'
import re, sys
with open(sys.argv[1]) as f:
    html = f.read()
# Remove leading HTML comment block
html = re.sub(r'<!--.*?-->', '', html, flags=re.DOTALL).strip()
# Unwrap <article ...> ... </article> if present
m = re.search(r'<article[^>]*>(.*?)</article>', html, re.DOTALL)
print(m.group(1).strip() if m else html)
PY
)

# ── Generate content-only output ──────────────────────────────────────────────
generate_content_only() {
  local out_file="$OUT_DIR/content-only.html"
  cat > "$out_file" <<CONTENT_ONLY
<!--
  OUTPUT: content-only
  id:    $PAGE_ID
  title: $PAGE_TITLE
  Use:   Paste the content inside this file directly into the Shopify
         Page content editor (HTML mode). No <html>/<head>/<body> wrappers needed.
  Generated: $TODAY
-->

$BADGES_BLOCK

$INNER_CONTENT
CONTENT_ONLY
  echo "  ✓ content-only.html → $out_file"
}

# ── Generate shopify-page output ──────────────────────────────────────────────
generate_shopify_page() {
  local out_file="$OUT_DIR/shopify-page.html"
  cat > "$out_file" <<SHOPIFY_PAGE
<!DOCTYPE html>
<!--
  OUTPUT: shopify-page
  id:    $PAGE_ID
  title: $PAGE_TITLE
  Use:   Full standalone HTML preview. Copy the content of <main> into the
         Shopify Page editor (HTML mode).
  Generated: $TODAY
-->
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$PAGE_TITLE | Golden Gardens</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; }
    body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #222; background: #fff; }
    .gg-header { padding: 1rem 2rem; border-bottom: 1px solid #e0e0e0; }
    .gg-logo img { display: block; height: 60px; width: auto; }
    .gg-page-content { max-width: 800px; margin: 0 auto; padding: 2rem 1rem; font-size: 1rem; line-height: 1.6; }
    .gg-page-content h1 { font-size: 2rem; margin-bottom: 1rem; }
    .gg-page-content h2 { font-size: 1.4rem; margin-top: 2rem; margin-bottom: 0.75rem; border-bottom: 1px solid #e0e0e0; padding-bottom: 4px; }
    .gg-page-content p  { margin-bottom: 1rem; }
    .gg-page-content ul { margin-bottom: 1rem; padding-left: 1.5rem; }
    .gg-page-content li { margin-bottom: 0.4rem; }
    .gg-badges { display: flex; flex-wrap: wrap; gap: 0.75rem; margin: 1.5rem 0; }
    .gg-badge  { display: flex; align-items: center; gap: 0.5rem; background: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; padding: 0.4rem 0.75rem; font-size: 0.85rem; font-weight: 600; color: #333; }
    .gg-notice--warning { background: #fff8e1; border-left: 4px solid #ffa000; padding: 0.75rem 1rem; margin: 1rem 0; border-radius: 0 4px 4px 0; }
    .gg-footer { text-align: center; padding: 2rem 1rem; border-top: 1px solid #e0e0e0; font-size: 0.85rem; color: #666; }
  </style>
</head>
<body>
<header class="gg-header">
  <div class="gg-logo">
    <a href="/" aria-label="Golden Gardens – Home">
      <img src="https://cdn.shopify.com/s/files/1/golden-gardens/logo.png" alt="Golden Gardens" width="180" height="60" loading="lazy" />
    </a>
  </div>
</header>
<main class="gg-page-content">
$BADGES_BLOCK
$INNER_CONTENT
</main>
<footer class="gg-footer">
  <p>&copy; <span id="gg-year">2024</span> Golden Gardens. All rights reserved.</p>
  <script>document.getElementById('gg-year').textContent = new Date().getFullYear();</script>
</footer>
</body>
</html>
SHOPIFY_PAGE
  echo "  ✓ shopify-page.html → $out_file"
}

# ── Generate shopify-liquid output ────────────────────────────────────────────
generate_shopify_liquid() {
  local out_file="$OUT_DIR/shopify-liquid.html"
  cat > "$out_file" <<SHOPIFY_LIQUID
{%- comment -%}
  OUTPUT: shopify-liquid
  id:    $PAGE_ID
  title: $PAGE_TITLE
  Use:   Add this file to your Shopify theme as:
           templates/page.$PAGE_ID.liquid
         or copy the content into an existing page template.
  Requires: assets/brand.css uploaded to the theme assets folder.
  Generated: $TODAY
{%- endcomment -%}

{{ 'brand.css' | asset_url | stylesheet_tag }}

<div class="gg-page-content">

$BADGES_BLOCK

$INNER_CONTENT

</div>
SHOPIFY_LIQUID
  echo "  ✓ shopify-liquid.html → $out_file"
}

# ── Run requested exports ─────────────────────────────────────────────────────
echo "→ Exporting '$PAGE_ID' ($PAGE_TITLE) …"

case "$OUTPUT_TYPE" in
  all)
    generate_content_only
    generate_shopify_page
    generate_shopify_liquid
    ;;
  content)
    generate_content_only
    ;;
  shopify)
    generate_shopify_page
    ;;
  liquid)
    generate_shopify_liquid
    ;;
  *)
    echo "ERROR: Unknown output-type '$OUTPUT_TYPE'. Use: all | content | shopify | liquid"
    exit 1
    ;;
esac

# ── Update optimized_date in manifest ────────────────────────────────────────
python3 - "$REPO_ROOT/library/manifest.json" "$PAGE_ID" "$TODAY" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    manifest = json.load(f)
for page in manifest["pages"]:
    if page["id"] == sys.argv[2]:
        page["optimized_date"] = sys.argv[3]
        break
with open(sys.argv[1], "w") as f:
    json.dump(manifest, f, indent=2)
PY

echo ""
echo "✓ Export complete for '$PAGE_ID'."
echo "  Output files are in: $OUT_DIR"
