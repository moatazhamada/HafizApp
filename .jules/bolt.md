## 2024-05-16 - [Surah Screen Render Optimizations]
**Learning:** Found multiple operations running in rendering loops or on state re-evaluations inside the `SurahScreen` specifically. `_getVerseStates` creates new `Set` instances each time `_buildRichTextContent` or `_buildSingleLineContent` is called, which happens frequently on scrolling or state changes.
**Action:** Extract repetitive operations, like filtering lists and creating Sets out of the layout building logic, and use `Set` appropriately for O(1) lookups.
## 2024-05-16 - [Home Screen List Optimization]
**Learning:** `ListView.builder` combined with `shrinkWrap: true` within a `SingleChildScrollView` completely breaks virtualization and instantiates/builds all items synchronously causing O(N) layout time, which is terrible for performance, specially here where there are 114 Surahs.
**Action:** Replace `SingleChildScrollView` with `CustomScrollView`, and use `SliverList.builder` instead of `ListView.builder` to preserve lazy loading functionality and vastly improve layout efficiency.
