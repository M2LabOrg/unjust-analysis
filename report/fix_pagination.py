#!/usr/bin/env python3
"""
Post-process Quarto-rendered HTML files to fix two known pagination bugs.

Bug 1 — previous-page links (all 10 inner-page files):
  Quarto emits:
    class="pagination-link  aria-label=" &lt;span="">
  The class attribute is terminated early (aria-label leaked in) and the
  span tag is HTML-entity-encoded, so the browser sees a broken tag.
  Fix: rebuild the <a> tag from the nav-page-text span that follows it.

Bug 2 — next-page links (all files):
  aria-label contains raw HTML spans:
    aria-label="<span class='chapter-number'>8</span>&nbsp; ..."
  Fix: strip HTML tags and decode entities to produce a plain-text label.

Run after `quarto render` from the report/ directory.
"""

import re
import sys
from html import unescape
from pathlib import Path


_TAG_RE = re.compile(r"<[^>]+>")


def plain(html: str) -> str:
    """Strip HTML tags, decode entities, collapse whitespace."""
    text = _TAG_RE.sub("", html)
    text = unescape(text).replace("\xa0", " ")
    return " ".join(text.split()).strip()


# ── Bug 1: broken previous-link ──────────────────────────────────────────────
# Matches the entire previous-nav div so we can extract href and inner text.
_PREV_DIV_RE = re.compile(
    r'<div class="nav-page nav-page-previous">'          # opening div
    r'\s*<a href="(?P<href>[^"]+)"'                      # href attr
    r'[^>]*class="pagination-link[^>]*>'                 # broken class (stops at >)
    r'\s*<i[^>]*/?\s*></i>'                              # chevron icon
    r'\s*(?P<text_span><span class="nav-page-text">.*?</span>)'  # nav text
    r'\s*</a>'                                           # close anchor
    r'\s*</div>',                                        # close div
    re.DOTALL | re.IGNORECASE,
)


def _fix_prev_div(m: re.Match) -> str:
    href  = m.group("href")
    text_span = m.group("text_span")
    label = plain(text_span)
    return (
        f'<div class="nav-page nav-page-previous">\n'
        f'      <a href="{href}" class="pagination-link" aria-label="{label}">\n'
        f'        <i class="bi bi-arrow-left-short"></i> {text_span}\n'
        f'      </a>          \n'
        f'  </div>'
    )


# ── Bug 2: aria-label with raw HTML spans ─────────────────────────────────────
_HTML_LABEL_RE = re.compile(
    r'aria-label="(<span[^"]*)"',
    re.IGNORECASE,
)


def _fix_html_label(m: re.Match) -> str:
    return f'aria-label="{plain(m.group(1))}"'


def fix_file(path: Path) -> bool:
    original = path.read_text(encoding="utf-8")
    text = _PREV_DIV_RE.sub(_fix_prev_div, original)
    text = _HTML_LABEL_RE.sub(_fix_html_label, text)
    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main(book_dir: str = "_book") -> None:
    book = Path(book_dir)
    html_files = sorted(book.glob("*.html"))
    if not html_files:
        print(f"No HTML files found in {book}", file=sys.stderr)
        sys.exit(1)
    changed = 0
    for f in html_files:
        if fix_file(f):
            print(f"  fixed  {f.name}")
            changed += 1
        else:
            print(f"  ok     {f.name}")
    print(f"\n{changed}/{len(html_files)} files updated.")


if __name__ == "__main__":
    book_dir = sys.argv[1] if len(sys.argv) > 1 else "_book"
    main(book_dir)
