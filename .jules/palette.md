## 2024-11-20 - [Tooltip Mapping]
**Learning:** In Flutter, adding a `tooltip` property directly to an `IconButton` implicitly provides the semantic label for screen readers. Explicit `Semantics` wrapper widgets around `IconButton`s are often redundant if a `tooltip` is used, though not harmful.
**Action:** When adding accessibility to `IconButton` widgets, prefer using the `tooltip` property to provide both hover text for sighted users and semantic labels for screen readers in a single step, reducing widget tree nesting.
