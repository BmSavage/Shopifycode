# Import and Export Workflow

This document walks through the full lifecycle of a Golden Gardens content page — from raw import through to a Shopify-ready output.

---

## Overview

```
Raw source (URL / file / paste)
        │
        ▼ import.sh
pages/<page-id>/source/raw.html
        │
        ▼ manual edit (normalize content)
pages/<page-id>/normalized/normalized.html
        │
        ▼ export.sh
pages/<page-id>/output/
    content-only.html        ← paste into Shopify
    shopify-page.html        ← standalone preview
    shopify-liquid.html      ← Liquid theme template
```

---

## Step 1 – Import

Run the import script with the page identifier and source type.

### From a URL

```bash
bash scripts/import.sh safety-page url https://your-store.myshopify.com/pages/safety
```

The script:
1. Fetches the URL with `curl`
2. Saves raw HTML to `pages/safety-page/source/raw.html`
3. Creates a normalized stub at `pages/safety-page/normalized/normalized.html`
4. Adds the page to `library/manifest.json`

### From a local file

```bash
bash scripts/import.sh safety-page file /tmp/safety.html
```

### Manual paste

```bash
bash scripts/import.sh safety-page manual
# Opens stub at pages/safety-page/source/raw.html — paste your content there
```

---

## Step 2 – Normalize

Open `pages/<page-id>/normalized/normalized.html` and clean up the content:

- Remove `<html>`, `<head>`, `<body>`, `<header>`, `<footer>` wrappers
- Strip all inline `style=""` attributes
- Remove script tags and tracking pixels
- Fix heading hierarchy (page should start with a single `<h1>`)
- Wrap the whole thing in `<article class="gg-page-content">…</article>`
- Use semantic HTML5 elements (`<ul>`, `<ol>`, `<p>`, `<strong>`, etc.)
- Replace any absolute links with relative Shopify URLs (`/pages/…`)

The normalized file is the **source of truth** for all exports.

---

## Step 3 – Export

```bash
bash scripts/export.sh safety-page
```

This generates three files under `pages/safety-page/output/`:

### content-only.html

Bare HTML fragment. Paste the entire contents into the Shopify **Page** editor:
1. Go to Shopify Admin → Online Store → Pages
2. Open or create your page
3. Click **< >** (HTML mode) in the rich text editor
4. Paste the content from `content-only.html`
5. Save

### shopify-page.html

Full standalone HTML file. Open in a browser to preview the page exactly as it will look on Shopify. Also useful as a reference when testing layouts.

### shopify-liquid.html

Liquid template. To use:
1. Upload `assets/brand.css` to your Shopify theme's **Assets** folder
2. Rename `shopify-liquid.html` to `page.<slug>.liquid`
3. Add it to your Shopify theme under **Templates**
4. In Shopify Admin → Pages, set the page's template to `page.<slug>`

---

## Step 4 – Update the manifest

After exporting, open `library/manifest.json` and update:
- `"optimized_date"`: today's date
- `"keywords"`: any relevant terms for search
- `"notes"`: anything useful for future reference

The export script automatically updates `optimized_date`.

---

## Adding a new page from scratch

```bash
bash scripts/add-page.sh faq-page "Frequently Asked Questions" "faq" "faq" "help"
```

Then:
1. Edit `pages/faq-page/source/raw.html` — add the original or draft content
2. Edit `pages/faq-page/normalized/normalized.html` — clean it up
3. Run `bash scripts/export.sh faq-page`

---

## Reusing brand assets

All badge and logo partials are in `assets/` and `components/`. Copy-paste their HTML blocks into any page's normalized content.

The combined trust badge block is in `components/trust-badges.html` — it's also automatically prepended by `export.sh`.

---

## File structure for each page

```
pages/<page-id>/
  source/
    raw.html            ← untouched original (never edit this)
  normalized/
    normalized.html     ← cleaned content (edit this)
  output/
    content-only.html   ← for Shopify page editor
    shopify-page.html   ← standalone HTML preview
    shopify-liquid.html ← for Shopify theme templates
```
