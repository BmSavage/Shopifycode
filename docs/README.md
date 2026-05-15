# Golden Gardens Shopify Page System

This repository stores, manages, and exports Golden Gardens content pages for Shopify.

---

## What's in this repository

| Folder | Purpose |
|---|---|
| `assets/` | Shared CSS and reusable HTML partials (logo, badges) |
| `components/` | Reusable page-section blocks (header, footer, trust badges) |
| `library/` | Page manifest — the searchable index of all pages |
| `pages/` | All page content: source → normalized → Shopify output |
| `scripts/` | Shell scripts for importing and exporting pages |
| `docs/` | This documentation |

---

## Quick start

### Add a brand-new page

```bash
bash scripts/add-page.sh my-page "My Page Title" "my-page-slug" "keyword1" "keyword2"
```

Then fill in the content stubs:
- `pages/my-page/source/raw.html` — full raw HTML
- `pages/my-page/normalized/normalized.html` — cleaned content

Then export:

```bash
bash scripts/export.sh my-page
```

---

### Import an existing page

**From a local HTML file:**
```bash
bash scripts/import.sh about-page file /path/to/about.html
```

**From a URL:**
```bash
bash scripts/import.sh about-page url https://example.myshopify.com/pages/about
```

**Manual paste:**
```bash
bash scripts/import.sh about-page manual
# Then edit pages/about-page/source/raw.html
```

---

### Export a page

```bash
# Export all three output formats (default)
bash scripts/export.sh safety-page

# Export only the content-only fragment
bash scripts/export.sh safety-page content

# Export only the full standalone HTML preview
bash scripts/export.sh safety-page shopify

# Export only the Liquid template
bash scripts/export.sh safety-page liquid
```

---

## Page library

All pages are indexed in `library/manifest.json`. Open that file to see every stored page along with its metadata (title, slug, source URL, keywords, dates, file paths).

---

## Output formats

| File | Use |
|---|---|
| `output/content-only.html` | Paste into Shopify Page editor → HTML mode |
| `output/shopify-page.html` | Standalone preview; also copy `<main>` content to Shopify |
| `output/shopify-liquid.html` | Add to Shopify theme as `templates/page.<slug>.liquid` |

---

## Shared branding assets

| Asset | Location |
|---|---|
| Logo partial | `assets/logos/golden-gardens-logo.html` |
| Lab Tested badge | `assets/badges/lab-tested-badge.html` |
| Discreet Delivery badge | `assets/badges/discreet-delivery-badge.html` |
| High Terpene badge | `assets/badges/high-terpene-badge.html` |
| All badges (combined) | `components/trust-badges.html` |
| Brand CSS | `assets/brand.css` |

Upload `assets/brand.css` to your Shopify theme's **Assets** folder so the Liquid template can load it.

---

## Example page

The `pages/safety-page/` directory is the first fully worked example:

```
pages/safety-page/
  source/raw.html                 ← original imported content
  normalized/normalized.html      ← cleaned, semantic HTML
  output/content-only.html        ← paste into Shopify page editor
  output/shopify-page.html        ← full standalone preview
  output/shopify-liquid.html      ← Liquid theme template
```

See `docs/workflow.md` for a step-by-step walkthrough.
