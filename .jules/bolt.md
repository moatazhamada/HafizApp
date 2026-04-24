## 2026-04-24 - [List Virtualization]
**Learning:** Using `ListView.builder` with `shrinkWrap: true` inside a `SingleChildScrollView` or `Column` breaks Flutter's list virtualization. This forces the framework to calculate layout for all items simultaneously (e.g., all 114 Surahs), turning what should be O(1) into O(N) rendering performance.
**Action:** Use `CustomScrollView` with `SliverList.builder` (and `SliverToBoxAdapter` for static elements above/below) for any long or potentially long lists to ensure elements are only laid out when scrolled into the viewport.
