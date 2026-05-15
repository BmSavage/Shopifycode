#!/usr/bin/env bash
# =============================================================================
# import.sh – Golden Gardens Page Import Pipeline
# =============================================================================
# Usage:
#   bash scripts/import.sh <page-id> <source-type> [source]
#
# Arguments:
#   page-id      Unique identifier for the page, e.g. "safety-page"
#   source-type  One of: manual | file | url
#   source       For "file": path to the HTML file to import
#                For "url":  full URL to fetch (requires curl)
#                For "manual": leave blank; you will paste content manually
#
# Examples:
#   bash scripts/import.sh about-page manual
#   bash scripts/import.sh about-page file /tmp/about.html
#   bash scripts/import.sh about-page url https://example.myshopify.com/pages/about
#
# What it does:
#   1. Creates the page directory scaffold under pages/<page-id>/
#   2. Saves the raw source to pages/<page-id>/source/raw.html
#   3. Runs basic normalization to pages/<page-id>/normalized/normalized.html
#   4. Adds a stub entry to library/manifest.json
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGE_ID="${1:-}"
SOURCE_TYPE="${2:-manual}"
SOURCE="${3:-}"
TODAY="$(date +%Y-%m-%d)"

# ── Validate arguments ────────────────────────────────────────────────────────
if [[ -z "$PAGE_ID" ]]; then
  echo "ERROR: page-id is required."
  echo "Usage: bash scripts/import.sh <page-id> <source-type> [source]"
  exit 1
fi

PAGE_DIR="$REPO_ROOT/pages/$PAGE_ID"
SOURCE_DIR="$PAGE_DIR/source"
NORM_DIR="$PAGE_DIR/normalized"
OUT_DIR="$PAGE_DIR/output"

# ── Create directory scaffold ─────────────────────────────────────────────────
echo "→ Creating page directory scaffold for '$PAGE_ID' …"
mkdir -p "$SOURCE_DIR" "$NORM_DIR" "$OUT_DIR"

# ── Fetch / copy raw source ───────────────────────────────────────────────────
RAW_FILE="$SOURCE_DIR/raw.html"

case "$SOURCE_TYPE" in
  url)
    if [[ -z "$SOURCE" ]]; then
      echo "ERROR: A URL is required when source-type is 'url'."
      exit 1
    fi
    echo "→ Fetching page from $SOURCE …"
    curl -fsSL "$SOURCE" -o "$RAW_FILE"
    echo "→ Saved raw source to $RAW_FILE"
    ;;
  file)
    if [[ -z "$SOURCE" ]] || [[ ! -f "$SOURCE" ]]; then
      echo "ERROR: A valid file path is required when source-type is 'file'."
      exit 1
    fi
    echo "→ Copying $SOURCE → $RAW_FILE …"
    cp "$SOURCE" "$RAW_FILE"
    ;;
  manual)
    if [[ ! -f "$RAW_FILE" ]]; then
      cat > "$RAW_FILE" <<'STUB'
<!-- RAW SOURCE STUB -->
<!-- Replace this file with the full HTML content you want to import. -->
<!-- Then re-run: bash scripts/import.sh <page-id> manual -->
<html><body><h1>Replace me</h1></body></html>
STUB
      echo "→ Created stub at $RAW_FILE – replace with your content and re-run."
    else
      echo "→ Existing raw.html found – skipping stub creation."
    fi
    ;;
  *)
    echo "ERROR: Unknown source-type '$SOURCE_TYPE'. Use: manual | file | url"
    exit 1
    ;;
esac

# ── Normalize ─────────────────────────────────────────────────────────────────
NORM_FILE="$NORM_DIR/normalized.html"

echo "→ Generating normalized output …"
cat > "$NORM_FILE" <<NORM_STUB
<!--
  NORMALIZED PAGE
  id:               $PAGE_ID
  source_type:      $SOURCE_TYPE
  normalized_date:  $TODAY
  notes:            Auto-generated stub. Edit to clean up the imported content.
-->
<article class="gg-page-content">

  <!-- TODO: paste cleaned content from source/raw.html here -->
  <!-- Remove <html>, <head>, <body> wrappers.               -->
  <!-- Strip inline styles; use assets/brand.css classes.    -->
  <!-- Ensure heading hierarchy starts at <h1>.              -->

</article>
NORM_STUB
echo "→ Saved normalized stub to $NORM_FILE"

# ── Update manifest ───────────────────────────────────────────────────────────
MANIFEST="$REPO_ROOT/library/manifest.json"
echo "→ Checking manifest …"

if python3 - "$MANIFEST" "$PAGE_ID" "$TODAY" "$SOURCE_TYPE" <<'PY'
import json, sys

manifest_path = sys.argv[1]
page_id       = sys.argv[2]
today         = sys.argv[3]
source_type   = sys.argv[4]

with open(manifest_path) as f:
    manifest = json.load(f)

existing_ids = [p["id"] for p in manifest.get("pages", [])]
if page_id in existing_ids:
    print(f"  Page '{page_id}' already in manifest – skipping.")
    sys.exit(0)

new_entry = {
    "id": page_id,
    "title": page_id.replace("-", " ").title(),
    "slug": page_id,
    "source_url": "",
    "source_type": source_type,
    "created_date": today,
    "optimized_date": "",
    "keywords": [],
    "notes": "Imported via import.sh",
    "files": {
        "source":     f"pages/{page_id}/source/raw.html",
        "normalized": f"pages/{page_id}/normalized/normalized.html",
        "output": {
            "content_only":   f"pages/{page_id}/output/content-only.html",
            "shopify_page":   f"pages/{page_id}/output/shopify-page.html",
            "shopify_liquid": f"pages/{page_id}/output/shopify-liquid.html"
        }
    }
}
manifest["pages"].append(new_entry)

with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)
print(f"  Added '{page_id}' to manifest.")
PY
then
  echo "→ Manifest updated."
else
  echo "WARNING: Could not update manifest automatically. Add '$PAGE_ID' to library/manifest.json manually."
fi

echo ""
echo "✓ Import complete for '$PAGE_ID'."
echo "  Next steps:"
echo "  1. Review / replace $RAW_FILE with the full page source."
echo "  2. Clean up $NORM_FILE."
echo "  3. Run: bash scripts/export.sh $PAGE_ID"
