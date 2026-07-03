# 06 -- Dashboard Design

## Design Philosophy: Inspired by Apple.com

The dashboard should feel like an Apple product page: clean, spacious, purposeful. Every element earns its place. The data tells a serious story -- the design should respect that gravity while making the numbers accessible.

### Design Principles

1. **Generous whitespace** -- let the data breathe
2. **Minimal chrome** -- no borders, no boxes, no clutter
3. **Bold typography** -- large, confident headings (SF Pro or Inter)
4. **Subtle motion** -- scroll-triggered animations, smooth transitions
5. **Dark/light sections** -- alternating backgrounds to create visual rhythm
6. **Muted palette** -- greys, whites, with one accent colour for emphasis
7. **Mobile-first** -- responsive down to 375px

## Tech Stack

| Tool | Purpose |
|------|---------|
| **React 18+** | UI framework |
| **TypeScript** | Type safety |
| **Vite** | Build tool |
| **Tailwind CSS 3+** | Utility-first styling |
| **Framer Motion** | Scroll animations, transitions |
| **Recharts** or **Nivo** | Chart library (React-native, responsive) |
| **D3.js** | Choropleth map (regional data) |
| **react-simple-maps** | Alternative for maps (simpler than raw D3) |

## Page Sections (Single-Page Scroll)

### 1. Hero Section
- Full-viewport height
- Large headline: e.g., "Stop and Search in Black Communities"
- Subtitle: "A statistical analysis of policing practices in England & Wales, 2020--2025"
- A single striking number (e.g., "3.8x") with context
- Subtle scroll indicator
- UNJUST + RSS logos

### 2. Key Findings (Sticky Number Cards)
- 3--4 large stat cards that animate in on scroll
- Examples:
  - "2.9x" -- adjusted disparity rate for Black individuals
  - "71%" -- searches resulting in no further action
  - "403K" -- total searches in 2024/25
  - "18%" -- missing ethnicity data
- Each card has a one-line explanation below

### 3. Trend Over Time (Animated Line Chart)
- X-axis: financial years (2020/21 to 2024/25)
- Y-axis: disparity ratio (IRR)
- Lines for Black, Asian, Mixed (relative to White baseline)
- Smooth entry animation
- Hover tooltips with exact values
- Caption explaining what the viewer is seeing

### 4. Regional Map (Choropleth)
- England & Wales map coloured by disparity rate or rate per 1,000
- Toggle between: All ethnicities / Black / Asian
- Hover shows region name + exact rate
- Clean, minimal map style (no busy borders)

### 5. Outcome Analysis (Stacked Bar or Grouped Bar)
- By ethnicity: what happens after a stop?
- Categories: Arrest, No Further Action, Penalty Notice, etc.
- Highlight the NFA rate disparity
- Interactive: click an ethnicity to filter

### 6. Force Rankings (Horizontal Bar Chart or Table)
- Top 10 / Bottom 10 forces by disparity
- Sortable by different metrics
- Clean table with subtle row shading

### 7. The Story in Numbers (Scrollytelling Section)
- Apple-style "scroll to reveal" narrative
- 3--5 key insights, each with a number and a paragraph
- Background colour shifts as you scroll
- This is where the new insights shine

### 8. Methodology Summary
- Brief, accessible explanation of the approach
- Link to the full Quarto report for details
- "Read the full report" CTA button

### 9. Footer
- Credits: Michel Mesquita, UNJUST, RSS
- Data sources with links
- "Report" link (to the Quarto book on `/report/`)
- GitHub repo link (when public)
- License information

## Colour Palette

```
Background (light):  #FAFAFA
Background (dark):   #1D1D1F  (Apple dark)
Text primary:        #1D1D1F
Text secondary:      #6E6E73
Accent:              #0071E3  (Apple blue -- used sparingly)
Chart colours:
  - Black ethnicity:  #1D1D1F
  - White ethnicity:  #A1A1A6
  - Asian ethnicity:  #6E6E73
  - Mixed ethnicity:  #D2D2D7
  - Highlight/alert:  #FF3B30  (sparingly, for key disparities)
```

## Data Flow

```
analysis/06_export_for_dashboard.R
    ↓
dashboard/public/data/*.json
    ↓
React components fetch JSON at build time (static import)
    ↓
Rendered as interactive charts
```

No backend. No API. The dashboard is a fully static site that reads pre-built JSON files.

## Responsive Breakpoints

| Breakpoint | Behaviour |
|------------|-----------|
| < 640px (mobile) | Single column, stacked charts, smaller text |
| 640--1024px (tablet) | Two-column where appropriate |
| > 1024px (desktop) | Full layout with generous margins |

## Accessibility

- All charts have `aria-label` descriptions
- Colour choices pass WCAG AA contrast
- Keyboard navigable
- Alt text for the map
- Screen-reader-friendly stat cards
