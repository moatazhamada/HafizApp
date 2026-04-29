# Implementation Plan: Spec 007 — Image-Based Mushaf

## Research Findings

- Page-level CDNs are all dead (403/404): islamic.network, alquran.cloud
- EveryAyah ayah-level images work (200 status)
- QF API v4 glyph data (code_v2) provides line-based positioning (line_v2 field)
- Current glyph rendering uses WRONG font (NotoNaskhArabic instead of QCF v2)
- Current mushaf uses SingleChildScrollView → vertical scroll instead of fit-to-screen
- MushafPageIndex already maps surah/ayah ↔ page number (1-604)

## Key Insight: QCF Font

The code_v2 glyphs are Unicode PUA characters (U+FC41+) designed for the **QCF v2 font** (available from Quran.com). Without this font, glyphs render as boxes. We need to:
1. Bundle the QCF v2 font OR
2. Use ayah images as primary (they work and look like real mushaf)

**Decision**: Use ayah images as primary mode since they provide authentic visual appearance without needing a custom font. Arrange per-ayah images in a page-like layout using MushafPageIndex for surah/ayah boundaries per page.

## Implementation Steps

1. Replace mushaf screen with PageView (horizontal swipe, 604 pages)
2. For each page: load ayah images from EveryAyah CDN for all ayahs on that page
3. Use MushafPageIndex to determine which ayahs belong to each page
4. Layout: fit to screen width, wrap content, no vertical scroll
5. Add page indicator overlay (current/total)
6. Add jump-to-page and surah picker
7. Apply parchment theme (light) / dark theme (dark mode)
8. Cache loaded images via CachedNetworkImage
9. Keep glyph mode as secondary option in settings

## Key Decisions

- Ayah images as default rendering (visual, works, no font dependency)
- Horizontal PageView for page navigation
- Fit to screen (FittedBox/AspectRatio) instead of scroll
- Traditional parchment theme
