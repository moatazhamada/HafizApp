# Feature Specification: Image-Based Mushaf Viewer

**Feature Branch**: `007-image-mushaf`
**Created**: 2026-04-29
**Status**: Draft
**Input**: User feedback — current text-based mushaf is ugly, too large, has vertical scroll. User prefers image-based viewing since text is already in surah view.

## User Scenarios & Testing

### User Story 1 - Mushaf Displays Page-Level Visual Layout (Priority: P1)

As a user opening the mushaf view, I see a visually authentic mushaf page that fits my screen without vertical scrolling. The page uses the QF glyph rendering system (code_v2) for authentic calligraphic appearance, with ayah images from EveryAyah CDN as fallback.

**Why this priority**: The current text-based mushaf is the user's biggest visual complaint. The QF glyph rendering (`/v4/verses/by_page/{page}` with `code_v2` fields) provides authentic calligraphic appearance using the QF API.

**Independent Test**: Open mushaf view for page 1 (Al-Fatiha). Verify the page fits the screen without scrolling, shows calligraphic Arabic text via QF glyph codes, and looks like a real mushaf page.

**Acceptance Scenarios**:
1. **Given** the mushaf view is opened, **When** a page loads, **Then** the content fits the screen viewport (no vertical scroll), scaled to fill width.
2. **Given** QF glyph data is available, **When** a page renders, **Then** ayahs are positioned at their correct x,y coordinates using code_v2 glyph positioning from the QF API.
3. **Given** QF glyph data fails to load, **When** fallback activates, **Then** ayah images from EveryAyah CDN (`everyayah.com/data/images_png/{surah}_{ayah}.png`) are displayed.
4. **Given** the user swipes left/right, **When** navigating between pages, **Then** the mushaf smoothly transitions to the adjacent page (1–604).

---

### User Story 2 - Mushaf Page Navigation (Priority: P1)

As a user, I can navigate between the 604 mushaf pages using swipe gestures, a page indicator, and jump-to-page/surah controls.

**Why this priority**: Basic navigation is essential for any mushaf viewer.

**Independent Test**: Swipe between pages 1, 2, 3. Tap page indicator to jump to page 100. Use surah picker to jump to Al-Baqarah (page 2).

**Acceptance Scenarios**:
1. **Given** any mushaf page is displayed, **When** the user swipes left, **Then** the next page appears.
2. **Given** any mushaf page is displayed, **When** the user swipes right, **Then** the previous page appears.
3. **Given** the mushaf view, **When** the page indicator is tapped, **Then** a page picker dialog allows jumping to any page 1–604.
4. **Given** the mushaf view, **When** the surah name is tapped, **Then** a surah list allows jumping to that surah's first page.

---

### User Story 3 - Mushaf Visual Theme (Priority: P2)

As a user, the mushaf has a traditional appearance with warm parchment background, dark calligraphic text, and proper page borders — resembling a physical mushaf.

**Why this priority**: The user specifically complained about "ugly colors". A traditional theme dramatically improves the experience.

**Independent Test**: Open mushaf. Verify warm parchment background (#FFFFFBF0), dark sepia text (#FF1A1A1A), and subtle page border/shadow.

**Acceptance Scenarios**:
1. **Given** the mushaf view in light mode, **When** a page renders, **Then** the background is warm parchment (#FFFFFBF0) with subtle border.
2. **Given** the mushaf view in dark mode, **When** a page renders, **Then** the background is dark (#FF1A1A2E) with light text.
3. **Given** any page, **When** rendered, **Then** the page has a subtle shadow/border giving a physical page appearance.

---

## Edge Cases

- What if QF API returns incomplete glyph data for a page? → Fall back to ayah images from EveryAyah CDN, then to text mode.
- What if the user is offline? → Cache the last viewed page's glyph data. Show cached pages. Show "offline" for uncached pages.
- What about landscape orientation? → Page scales to fill width in both orientations.
- What about very large font sizes in accessibility? → Glyph rendering respects the page layout; ayah images scale naturally.

## Requirements

### Functional Requirements

- **FR-001**: Mushaf MUST render pages using QF glyph codes (code_v2) from `api.quran.com/api/v4/verses/by_page/{page}` as the primary rendering mode. (US-1, QF priority)
- **FR-002**: Mushaf pages MUST fit the screen viewport without vertical scrolling, using horizontal PageView for swipe navigation. (US-1)
- **FR-003**: Mushaf MUST fall back to ayah images from EveryAyah CDN when glyph data is unavailable. (US-1)
- **FR-004**: Mushaf MUST use a PageView with 604 pages for horizontal swipe navigation. (US-2)
- **FR-005**: Mushaf MUST show page number indicator and provide jump-to-page functionality. (US-2)
- **FR-006**: Mushaf MUST apply a traditional parchment theme in light mode and dark theme in dark mode. (US-3)
- **FR-007**: Glyph data SHOULD be cached per page to avoid re-fetching on revisit. (US-1)
- **FR-008**: The existing `text` rendering mode MUST remain available as a final fallback. (US-1)

### Key Entities

- **QfGlyphPageDataSource**: Fetches page-level glyph data from QF API (already partially exists in `qf_mushaf_page_data_source.dart`)
- **MushafPageView**: PageView widget with horizontal swipe, page indicator overlay
- **GlyphPageRenderer**: Custom painter/positioned widget that places ayah glyphs at code_v2 coordinates
- **AyahImageFallback**: CachedNetworkImage grid for EveryAyah CDN ayah images

## Success Criteria

- **SC-001**: Mushaf page fits screen without vertical scroll
- **SC-002**: QF glyph rendering is the default and primary rendering mode
- **SC-003**: Horizontal swipe navigates between 604 pages smoothly
- **SC-004**: Parchment theme gives traditional mushaf appearance
- **SC-005**: Fallback to ayah images works when glyph data fails
- **SC-006**: Page loads within 2 seconds on normal connection

## Assumptions

- QF API v4 glyph data (`code_v2`) provides x,y positioning for each ayah on a page
- The existing `qf_mushaf_page_data_source.dart` already fetches some of this data
- EveryAyah CDN ayah-level images remain available (confirmed: 200 status)
- The rendering mode preference system (PrefUtils.getMushafRenderingMode) already exists
- MushafPageIndex provides the mapping between surah/ayah and page numbers (1–604)
