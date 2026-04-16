
## 2024-05-24 - Consistent Tooltips for IconButtons
**Learning:** While `Semantics` widgets provide excellent accessibility for screen reader users, sighted users relying on mouse hover or long-press on mobile miss out on these labels. We discovered several `IconButton`s in the `SurahScreen` that had `Semantics` but lacked the native `tooltip` property.
**Action:** Always map the localized `Semantics` label to the `IconButton`'s `tooltip` property to ensure inclusive UX for both screen reader users and sighted users.
