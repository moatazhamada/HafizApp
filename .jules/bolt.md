## 2024-05-15 - [List Virtualization]
**Learning:** Using `ListView.builder` with `shrinkWrap: true` inside a `SingleChildScrollView` breaks lazy-loading and forces an O(N) layout time.
**Action:** Replace `SingleChildScrollView` + `Column` + `ListView.builder(shrinkWrap: true)` with a `CustomScrollView` and use `SliverList.builder` instead.
