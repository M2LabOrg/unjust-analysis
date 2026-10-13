# 07 -- Deployment (Netlify)

## Architecture

A single Netlify site serves both the dashboard and the report:

```
https://unjust.netlify.app/          → React dashboard (SPA)
https://unjust.netlify.app/report/   → Quarto HTML book
```

## Build Process

### `netlify.toml`

```toml
[build]
  command = "bash build.sh"
  publish = "dist"

[build.environment]
  NODE_VERSION = "20"

[[redirects]]
  from = "/report/*"
  to = "/report/:splat"
  status = 200

# SPA fallback for React router (if used)
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### `build.sh`

```bash
#!/bin/bash
set -e

# 1. Build the React dashboard
cd dashboard
npm ci
npm run build
cd ..

# 2. Build the Quarto report
cd report
quarto render
cd ..

# 3. Assemble the final dist/ folder
rm -rf dist
mkdir -p dist/report

# Dashboard goes to root
cp -r dashboard/dist/* dist/

# Report goes to /report/
cp -r report/_book/* dist/report/
```

### Quarto on Netlify

Quarto is not pre-installed on Netlify. Options:

1. **Pre-render locally** and commit `report/_book/` to git (simplest)
2. **Use a Netlify build plugin** or install Quarto in the build script
3. **Use GitHub Actions** to render the report and push the output

**Recommendation for now:** Pre-render the report locally and commit the HTML output. This avoids complex CI setup and keeps the Netlify build fast (just the React app). When the project goes public, switch to GitHub Actions for full automation.

## Privacy

- Deploy as a **private** Netlify site initially (password-protected or team-only)
- Netlify supports password protection on Pro plans, or use a simple auth gate
- When ready, remove the password to make it public

## Domain

- Start with `unjust.netlify.app` (free subdomain)
- Can add a custom domain later (e.g., `data.unjust.org.uk`)

## Alternative: Separate Deploys

If combining dashboard + report in one Netlify site proves difficult:

- **Site 1:** `unjust-dashboard.netlify.app` -- React app
- **Site 2:** `unjust-report.netlify.app` -- Quarto HTML book (deployed via `quarto publish netlify`)

Each site links to the other. This is simpler but less cohesive.

## Report Format Fallback

If Quarto + Netlify integration is problematic, alternatives for the report:

| Option | Pros | Cons |
|--------|------|------|
| **Quarto HTML book** (recommended) | Professional, citable, PDF option, integrates with R | Needs Quarto installed |
| **Quarto to PDF only** | Simplest, just host the PDF | Not interactive, no web navigation |
| **Docusaurus / Nextra** | React-based, great for web | Not designed for statistical reports |
| **LaTeX via Overleaf** | Academic gold standard | No web version, separate workflow |
| **The report as part of the dashboard** | Single codebase | Mixing concerns, harder to maintain |

**Our recommendation:** Stick with Quarto HTML book. It's purpose-built for this. Pre-render locally to avoid CI complexity.
