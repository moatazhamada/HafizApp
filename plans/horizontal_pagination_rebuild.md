# Horizontal Pagination Rebuild Plan

## Problem Statement

The current horizontal pagination implementation in `surah_screen.dart` is broken at the foundation:

1. **Wrong layout host** — it wraps the `PageView` inside `CustomScrollView → SliverFillRemaining`, copied from the vertical-scroll path. `SliverFillRemaining(hasScrollBody: false)` does not give a reliable bounded height to its child in all Flutter versions, so the `PageView` has no measured height to work with.
2. **Broken verse-capacity calculation** — it guesses how many verses fit per page using fixed pixel constants (72px / 56px per verse). Arabic verse text wraps differently on every device width and font size; a two-word verse and a twenty-word verse both get the same slot. The Bismillah offset (`-1 verse`) is also a guess.
3. **Navigation footer crammed into the last verse page** — the footer consumes space that belongs to verses, causing the last page to overflow or show fewer verses than it should.

## Reference: How MushafScreen Does It

`MushafScreen` (the existing horizontal page-turn Quran view) uses the correct pattern:

```dart
Scaffold(
  appBar: AppBar(...),         // regular AppBar, fixed height, managed by Scaffold
  body: SafeArea(
    child: Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            reverse: true,     // RTL: swipe right = next page
            itemCount: totalPages,
            itemBuilder: (_, index) => _buildPage(index, isDark),
          ),
        ),
        // page indicator sits below PageView, inside Column
        Text('$currentPage / $totalPages'),
      ],
    ),
  ),
)
```

Key properties of this pattern:
- `Scaffold.appBar` guarantees the AppBar a fixed slot; the remaining `body` height is exact.
- `Column → Expanded → PageView` is the canonical Flutter pattern for a full-height `PageView`. The `Expanded` widget forces `PageView` to take exactly the remaining height with zero ambiguity.
- The page indicator lives **outside** the `PageView` in the `Column`, so it never consumes page space.
- No `CustomScrollView`, no `SliverFillRemaining`, no `NestedScrollView`.

This is the exact pattern we will follow.

## Architecture Decision: Single-Line Mode Only in Horizontal Pagination

`_buildRichTextContent` renders all verses as one flowing `RichText` paragraph — a single indivisible render object. There is no verse boundary at the layout level. Splitting it cleanly across pages would require measuring character offsets inside a `RenderParagraph`, which is fragile and breaks with `WidgetSpan` badges.

**Decision:** when `_isHorizontalPagination` is true, always use `_buildSingleLineContent` regardless of `PrefUtils().getVerseViewMode()`. The user's setting is preserved; it simply does not apply while horizontal mode is active. A small note is shown to the user in the future (out of scope here).

## New Layout Structure

### Replacing (horizontal branch only)
```
// CURRENT — broken
Directionality(rtl)
  CustomScrollView(NeverScrollableScrollPhysics)
    SliverAppBar(pinned)         ← sliver app bar
    SliverFillRemaining          ← unreliable bounded height
      LayoutBuilder
        PageView.builder
          SizedBox.expand
            Padding
              Column
                Expanded(_buildSurahList)     ← unconstrained Column inside
                [last page] _buildNavigationFooter   ← crammed into verse page
```

### New structure (mirrors MushafScreen)
```
// NEW — correct
Scaffold(
  appBar: _buildHorizontalAppBar(isDark)   ← regular AppBar
  body: SafeArea
    Column
      Expanded
        Directionality(rtl)
          PageView.builder(reverse: true, BouncingScrollPhysics)
            pages[0..N-1]: _buildVersePage(...)   ← verse pages
            page[N]:       _buildNavigationFooterPage(...)   ← dedicated final page
      _buildPageIndicator(...)   ← sits below PageView, outside it
)
```

## Page-Building Algorithm

### Why we cannot pre-measure verse heights

Flutter layout is single-pass and synchronous. A widget's pixel height is only known after `performLayout()` has been called. We cannot call it ourselves before building. The only correct options are:

1. **Post-frame measurement**: render all verses offscreen, capture heights via `RenderBox.size`, then rebuild with correct page splits. Two frames, complex state management.
2. **Conservative static minimum**: use a height that is guaranteed ≤ the actual rendered height of any verse card. Pages may have visible empty space at the bottom, but will **never** overflow. This is the practical, correct choice.

We use option 2, with clearly documented constants.

### Why the constants are minimums, not averages

```
kVerseMinHeight = 90.0
```

A single-line verse card in `_buildSingleLineContent` has these guaranteed structural costs:
- Vertical padding inside container: 8px top + 8px bottom = 16px
- Bottom margin between cards: 12px
- Minimum Arabic text height: fontSize(24) × lineHeight(2.2) = 52.8px

Total minimum: 52.8 + 16 + 12 = 80.8px → rounded up to **90px**.

Using the minimum means we underestimate capacity → fewer verses per page than could fit → safe. Using an average would overestimate on devices where verses are long → overflow → broken.

```
kBismillahHeight = 64.0
```
Bismillah widget: `Container(padding: vertical(20))` + Text at fontSize(24) × lineHeight ≈ 64px.

```
kPageIndicatorHeight = 28.0
```
Sits outside the PageView in the Column (see structure above), so it does **not** count against page budget. Documented here for reference only.

```
kPagePaddingVertical = 32.0  // 16px top + 16px bottom inside each page
```

### `_buildPages` — the only place verse-to-page assignment happens

```dart
// Constants — minimums, not averages. See comments above for derivation.
static const double _kVerseMinHeight   = 90.0;
static const double _kBismillahHeight  = 64.0;
static const double _kPagePaddingV     = 32.0;

List<List<Verse>> _buildPages(
  List<Verse> verses,
  double availableHeight,  // constraints.maxHeight from LayoutBuilder wrapping PageView
  bool hasBismillah,
) {
  final double page0Budget = availableHeight
      - _kPagePaddingV
      - (hasBismillah ? _kBismillahHeight : 0.0);
  final double otherBudget = availableHeight - _kPagePaddingV;

  // clamp(1, 999): always at least 1 verse per page to prevent infinite loop.
  final int page0Cap = (page0Budget / _kVerseMinHeight).floor().clamp(1, 999);
  final int otherCap = (otherBudget / _kVerseMinHeight).floor().clamp(1, 999);

  final List<List<Verse>> pages = [];
  int cursor = 0;
  while (cursor < verses.length) {
    final int cap = pages.isEmpty ? page0Cap : otherCap;
    final int end = (cursor + cap).clamp(0, verses.length);
    pages.add(verses.sublist(cursor, end));
    cursor = end;
  }
  return pages;
}
```

This is called inside a `LayoutBuilder` that wraps the `PageView` body area, giving us the exact available height at runtime. Pages are rebuilt whenever constraints change (e.g. orientation change).

## Step-by-Step Implementation

### Step 1 — Add `_buildHorizontalAppBar`

Add a new method returning a regular `AppBar` (not `SliverAppBar`) with the same visual style. It carries:
- Back button (same as `_buildSliverAppBar`)
- Surah name title
- Bookmark toggle icon (same logic)
- Settings popup menu (layout toggle, hifz mode, help — same as current)
- The green gradient `flexibleSpace` background (same as current)

`_buildSliverAppBar` is **not modified** — it stays for the vertical scroll path.

### Step 2 — Fix `PageController` lifecycle

In the `PopupMenuButton`'s `'layout'` case (where `_isHorizontalPagination` is toggled), reset the controller:

```dart
case 'layout':
  setState(() {
    _horizontalPageController?.dispose();
    _horizontalPageController = null;  // recreated lazily on next build
    _isHorizontalPagination = !_isHorizontalPagination;
    PrefUtils().setHorizontalPagination(_isHorizontalPagination);
  });
```

The existing lazy `_horizontalPageController ??= PageController()` handles creation.

### Step 3 — Replace the horizontal branch in `build`

Current code (around line 466) wraps in `CustomScrollView`. Replace with:

```dart
if (_isHorizontalPagination) {
  return Scaffold(
    backgroundColor: isDark ? Colors.black : const Color(0xFFFAF6EB),
    appBar: _buildHorizontalAppBar(isDark),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _buildHorizontalPageView(
                context, chapters, bookmarkState, errorState, isDark,
              ),
            ),
          ),
          _buildPageIndicator(isDark),
        ],
      ),
    ),
  );
}
```

Note: returning a `Scaffold` here from inside the outer `Scaffold`'s body is the standard Flutter nested-Scaffold pattern; it is used by `MushafScreen` the same way. Flutter handles it correctly.

### Step 4 — Rewrite `_buildHorizontalPageView`

Full replacement:

```dart
Widget _buildHorizontalPageView(
  BuildContext context,
  List<Verse> chapters,
  BookmarkState bookmarkState,
  RecitationErrorState errorState,
  bool isDark,
) {
  // Rich-text mode is incompatible with per-verse pagination.
  // Horizontal mode always uses single-line rendering.

  _horizontalPageController ??= PageController();

  final bool hasBismillah =
      chapters.isNotEmpty &&
      chapters.first.verseNumber == 1 &&
      surah?.id != 1 &&
      surah?.id != 9;

  return LayoutBuilder(
    builder: (context, constraints) {
      final List<List<Verse>> pages = _buildPages(
        chapters,
        constraints.maxHeight,
        hasBismillah,
      );

      // +1 for the dedicated navigation footer page at the end.
      return PageView.builder(
        controller: _horizontalPageController!,
        itemCount: pages.length + 1,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, pageIndex) {
          if (pageIndex == pages.length) {
            return _buildNavigationFooterPage(context, isDark);
          }
          return _buildVersePage(
            context,
            pages[pageIndex],
            pageIndex == 0 && hasBismillah,
            bookmarkState,
            errorState,
            isDark,
          );
        },
      );
    },
  );
}
```

### Step 5 — Add `_buildVersePage`

```dart
Widget _buildVersePage(
  BuildContext context,
  List<Verse> pageVerses,
  bool showBismillah,
  BookmarkState bookmarkState,
  RecitationErrorState errorState,
  bool isDark,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBismillah) _buildBismillah(isDark),
        Expanded(
          child: _buildSingleLineContent(
            context,
            pageVerses,
            bookmarkState,
            errorState,
            isDark,
          ),
        ),
      ],
    ),
  );
}
```

`_buildSingleLineContent` is called directly — bypassing the `PrefUtils().getVerseViewMode()` branch that lives in `_buildSurahList`. `_buildSurahList` itself is not changed.

### Step 6 — Add `_buildNavigationFooterPage`

`_buildNavigationFooter` (which returns a `Padding > Row`) is unchanged. Add a thin wrapper:

```dart
Widget _buildNavigationFooterPage(BuildContext context, bool isDark) {
  return Center(
    child: _buildNavigationFooter(context, isDark),
  );
}
```

Centering vertically on a full-height page makes the footer feel intentional.

### Step 7 — Move page indicator outside PageView

Add a new `_buildPageIndicator` that reads current page from `_horizontalPageController` (or a tracked `_currentHorizontalPage` int). It sits in the `Column` below `Expanded`, mirroring `MushafScreen`'s page indicator:

```dart
// Add to state:
int _currentHorizontalPage = 0;

// In _buildHorizontalPageView, add onPageChanged to PageView.builder:
onPageChanged: (i) => setState(() => _currentHorizontalPage = i),

// New method:
Widget _buildPageIndicator(bool isDark) {
  return Container(
    height: 28,
    alignment: Alignment.center,
    child: Text(
      '${_currentHorizontalPage + 1} / ...',  // total derived from pages.length + 1
      style: TextStyle(
        fontSize: 13,
        color: isDark ? const Color(0xFF87D1A4) : const Color(0xFF006754),
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
```

Because `_buildPages` is inside `LayoutBuilder`, the total page count needs to be lifted to state or passed through. The simplest approach: store `_horizontalTotalPages` in state and update it whenever `_buildPages` is called (via a post-frame callback or direct assignment inside `LayoutBuilder`).

## What Stays Unchanged

| Component | Reason |
|---|---|
| `_buildSliverAppBar` | Still used by vertical scroll path |
| `_buildSurahList` | Still used by vertical scroll path |
| `_buildSingleLineContent` — verse item widget | Reused directly; no changes needed |
| `_buildRichTextContent` | Still used in vertical mode |
| `_buildBismillah` | No changes needed |
| `_buildNavigationFooter` | No changes; called from new wrapper |
| All BLoC/state logic | Not touched |
| Verse tap/long-press/voice handlers | Not touched |
| Hifz mode, `_revealedVerses` | Not touched |
| `_scrollController`, scroll-to-verse logic | Not touched (only used in vertical mode) |
| `_verseKeys`, `_richTextVerseKeys` | Harmlessly populated in horizontal mode too |

## New Methods Summary

| Method | Returns | Purpose |
|---|---|---|
| `_buildHorizontalAppBar(isDark)` | `AppBar` | Regular AppBar for horizontal mode |
| `_buildPages(verses, height, hasBismillah)` | `List<List<Verse>>` | Conservative page-split algorithm |
| `_buildVersePage(ctx, verses, showBismillah, ...)` | `Widget` | One verse-carrying page |
| `_buildNavigationFooterPage(ctx, isDark)` | `Widget` | Dedicated final page with surah navigation |
| `_buildPageIndicator(isDark)` | `Widget` | "3 / 12" indicator below PageView |
