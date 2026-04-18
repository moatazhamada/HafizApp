## 2024-05-24 - Accessibility: IconButton Tooltips
**Learning:** `IconButton` widgets should always have a `tooltip` property matching the `Semantics` label. This ensures that while screen readers announce the semantic label, sighted users can discover the functionality through hover or long-press interactions, leading to a universally inclusive experience.
**Action:** Always map localized `Semantics` labels to the corresponding `tooltip` property on `IconButton` widgets.
