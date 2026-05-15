# Golden Gardens Shopify Page System

A content management system for Golden Gardens Shopify pages. The goal is to maintain a reusable page library with clean code, shared brand assets, Shopify-friendly output, and a repeatable workflow for importing older pages and turning them into stronger Golden Gardens pages.

---

## Repository layout

```
assets/         Shared CSS and HTML partials (logo, trust badges)
components/     Reusable page-section blocks (header, footer, trust badges)
library/        manifest.json — searchable index of all pages
pages/          Page content: source → normalized → Shopify output
scripts/        Shell scripts for importing and exporting pages
docs/           Full documentation
```

---

## Quick start

```bash
# Add a new page
bash scripts/add-page.sh my-page "My Page Title" "my-slug"

# Import an existing page from a file or URL
bash scripts/import.sh about-page file /path/to/about.html
bash scripts/import.sh about-page url https://your-store.myshopify.com/pages/about

# Export to Shopify-ready output
bash scripts/export.sh my-page
```

---

## Documentation

- **[docs/README.md](docs/README.md)** — overview of all features
- **[docs/workflow.md](docs/workflow.md)** — step-by-step import and export walkthrough

---

## Example page

`pages/safety-page/` is a fully worked example showing the complete workflow:

| File | Contents |
|---|---|
| `source/raw.html` | Original imported source |
| `normalized/normalized.html` | Cleaned, semantic HTML |
| `output/content-only.html` | Paste into Shopify page editor |
| `output/shopify-page.html` | Full standalone HTML preview |
| `output/shopify-liquid.html` | Liquid theme template |

---

## Shared branding

All Golden Gardens brand assets are in `assets/` and `components/`:

- **Logo** — `assets/logos/golden-gardens-logo.html`
- **Lab Tested badge** — `assets/badges/lab-tested-badge.html`
- **Discreet Delivery badge** — `assets/badges/discreet-delivery-badge.html`
- **High Terpene badge** — `assets/badges/high-terpene-badge.html`
- **All badges combined** — `components/trust-badges.html`
- **Brand CSS** — `assets/brand.css`
