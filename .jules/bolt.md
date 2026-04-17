# Bolt's Journal
## $(date +%Y-%m-%d) - [Replace shrinkWrap ListView inside SingleChildScrollView]
**Learning:** Using `ListView.builder` with `shrinkWrap: true` inside a `SingleChildScrollView` defeats the purpose of the lazy-loading `.builder` constructor. It forces Flutter to instantiate, layout, and render all children synchronously at once to measure the total height of the `ListView`, causing a huge performance bottleneck (O(N) layout time) and high memory usage.
**Action:** Always use `CustomScrollView` with `SliverList.builder` instead of `SingleChildScrollView` containing a `shrinkWrap` `ListView` for rendering large lists alongside other content.
