#!/usr/bin/env bash
# =============================================================================
# add-page.sh – Add a new Golden Gardens page to the library
# =============================================================================
# Usage:
#   bash scripts/add-page.sh <page-id> "<title>" "<slug>" [keywords...]
#
# Arguments:
#   page-id   Unique identifier, e.g. "about-page" (use hyphens, no spaces)
#   title     Human-readable page title, e.g. "About Golden Gardens"
#   slug      Shopify page slug, e.g. "about"
#   keywords  Optional space-separated keywords (quote individually)
#
# Examples:
#   bash scripts/add-page.sh about-page "About Golden Gardens" "about"
#   bash scripts/add-page.sh faq-page "Frequently Asked Questions" "faq" "faq" "help" "questions"
#
# What it does:
#   1. Creates the page directory scaffold under pages/<page-id>/
#   2. Creates a content stub in source/, normalized/, and output/
#   3. Adds the page to library/manifest.json
#   4. Prints next steps
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGE_ID="${1:-}"
PAGE_TITLE="${2:-}"
PAGE_SLUG="${3:-}"
TODAY="$(date +%Y-%m-%d)"

# ── Validate arguments ────────────────────────────────────────────────────────
if [[ -z "$PAGE_ID" ]] || [[ -z "$PAGE_TITLE" ]] || [[ -z "$PAGE_SLUG" ]]; then
  echo "ERROR: page-id, title, and slug are all required."
  echo 'Usage: bash scripts/add-page.sh <page-id> "<title>" "<slug>"'
  exit 1
fi

# Collect optional keywords (remaining args)
shift 3 || true
KEYWORDS=("$@")

# ── Create directory scaffold ─────────────────────────────────────────────────
PAGE_DIR="$REPO_ROOT/pages/$PAGE_ID"

if [[ -d "$PAGE_DIR" ]]; then
  echo "ERROR: Page directory already exists: $PAGE_DIR"
  echo "If you want to re-import, run: bash scripts/import.sh $PAGE_ID manual"
  exit 1
fi

mkdir -p "$PAGE_DIR/source" "$PAGE_DIR/normalized" "$PAGE_DIR/output"
echo "→ Created directory scaffold at $PAGE_DIR"

# ── Create source stub ────────────────────────────────────────────────────────
cat > "$PAGE_DIR/source/raw.html" <<STUB
<!-- RAW SOURCE STUB -->
<!-- id: $PAGE_ID -->
<!-- source_type: manual -->
<!-- Replace this content with the actual page HTML. -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>$PAGE_TITLE | Golden Gardens</title>
</head>
<body>
  <h1>$PAGE_TITLE</h1>
  <p>Add your page content here.</p>
</body>
</html>
STUB
echo "→ Created source stub"

# ── Create normalized stub ────────────────────────────────────────────────────
cat > "$PAGE_DIR/normalized/normalized.html" <<NORM
<!--
  NORMALIZED PAGE
  id:               $PAGE_ID
  title:            $PAGE_TITLE
  slug:             $PAGE_SLUG
  source_type:      manual
  normalized_date:  $TODAY
  notes:            Auto-generated stub. Edit with cleaned page content.
-->
<article class="gg-page-content">

  <h1>$PAGE_TITLE</h1>

  <p>Add your cleaned, normalized page content here.</p>
  <!-- Remove inline styles, <html>/<head>/<body> wrappers.     -->
  <!-- Use brand.css classes for styling.                       -->

</article>
NORM
echo "→ Created normalized stub"

# ── Create output stubs ───────────────────────────────────────────────────────
cat > "$PAGE_DIR/output/content-only.html" <<CONTENT
<!--
  OUTPUT: content-only (stub)
  id:    $PAGE_ID
  title: $PAGE_TITLE
  Run: bash scripts/export.sh $PAGE_ID
  to regenerate this file from the normalized source.
-->
<h1>$PAGE_TITLE</h1>
<p>Run export.sh to generate this output.</p>
CONTENT

cat > "$PAGE_DIR/output/shopify-page.html" <<SHOPIFY
<!DOCTYPE html>
<!-- OUTPUT: shopify-page (stub) – run export.sh to generate -->
<html lang="en"><head><title>$PAGE_TITLE | Golden Gardens</title></head>
<body><h1>$PAGE_TITLE</h1><p>Run export.sh to generate this output.</p></body>
</html>
SHOPIFY

cat > "$PAGE_DIR/output/shopify-liquid.html" <<LIQUID
{%- comment -%} OUTPUT: shopify-liquid (stub) – run export.sh to generate {%- endcomment -%}
<div class="gg-page-content"><h1>{{ page.title }}</h1><p>Run export.sh to generate.</p></div>
LIQUID

echo "→ Created output stubs"

# ── Update manifest ───────────────────────────────────────────────────────────
MANIFEST="$REPO_ROOT/library/manifest.json"

python3 - "$MANIFEST" "$PAGE_ID" "$PAGE_TITLE" "$PAGE_SLUG" "$TODAY" "${KEYWORDS[@]+"${KEYWORDS[@]}"}" <<'PY'
import json, sys

manifest_path = sys.argv[1]
page_id       = sys.argv[2]
page_title    = sys.argv[3]
page_slug     = sys.argv[4]
today         = sys.argv[5]
keywords      = sys.argv[6:]

with open(manifest_path) as f:
    manifest = json.load(f)

existing_ids = [p["id"] for p in manifest.get("pages", [])]
if page_id in existing_ids:
    print(f"  Page '{page_id}' already in manifest – skipping.")
    sys.exit(0)

new_entry = {
    "id": page_id,
    "title": page_title,
    "slug": page_slug,
    "source_url": "",
    "source_type": "manual",
    "created_date": today,
    "optimized_date": "",
    "keywords": keywords,
    "notes": "",
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

echo "→ Manifest updated"
echo ""
echo "✓ Page '$PAGE_ID' created successfully."
echo "  Next steps:"
echo "  1. Edit pages/$PAGE_ID/source/raw.html   – add full page source"
echo "  2. Edit pages/$PAGE_ID/normalized/normalized.html – add cleaned content"
echo "  3. Run: bash scripts/export.sh $PAGE_ID"
