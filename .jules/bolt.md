## 2025-02-20 - Removed ListView shrinkWrap anti-pattern
**Learning:** Found a major performance anti-pattern where a large `ListView.builder` was placed inside a `SingleChildScrollView` with `shrinkWrap: true`. This disables lazy rendering, forcing all items to be built at once and causes an O(N) layout pass every time.
**Action:** Replaced `SingleChildScrollView` + `ListView` with `CustomScrollView` + `SliverList.builder`. This allows for efficient virtualization, improving layout performance drastically for large lists while preserving scroll context for previously rendered slivers.
