## 2024-11-20 - [Optimize Single-Line View performance]
**Learning:** `ListView` mapped over `children: chapters.map` is inefficient for lists inside a `CustomScrollView`. Using `SliverList.builder` inside `SliverMainAxisGroup` is much better for lazy loading elements inside the scroll view.
**Action:** Used `SliverList.builder` for the single line verse view to preserve list virtualization and avoid large O(N) operations.
