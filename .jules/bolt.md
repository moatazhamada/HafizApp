## 2024-05-24 - [Avoid ListView.builder with shrinkWrap inside SingleChildScrollView]
**Learning:** Using ListView.builder with shrinkWrap: true inside a SingleChildScrollView breaks lazy-loading and causes O(N) layout time because all children are built synchronously.
**Action:** Replace SingleChildScrollView + Column + shrinkWrap ListView.builder with a CustomScrollView and Slivers (e.g., SliverToBoxAdapter for top items and SliverList.builder for the list) to preserve list virtualization.
