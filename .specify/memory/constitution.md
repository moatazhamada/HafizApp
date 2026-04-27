---
name: HafizApp Project Constitution
version: 1.0.0
ratified: 2026-04-28
---

# HafizApp Project Constitution

## Principles

### 1. Quranic Reverence & Cultural Appropriateness

All Quranic content is displayed with appropriate reverence. Arabic text uses RTL direction consistently. Bismillah display logic follows Islamic scholarship (skipping Surah 9, including Surah 1 as the opening). No decorative use of verses or Allah's names. UI labels respect Arabic text shaping (no `.toUpperCase()` on Arabic).

### 2. Clean Architecture Separation

The project follows Clean Architecture with BLoC state management. Domain, Data, and Presentation layers are strictly separated. Exceptions in the data layer must NEVER directly manipulate UI. BLoCs mediate between data and presentation. Use cases encapsulate business logic (to be expanded).

### 3. Offline-First Reliability

The app must function fully offline. All core features (reading, memorization, bookmarks, khatmah tracking) work without network. Cloud sync is additive — local data is the source of truth. Network failures degrade gracefully with queue-and-sync behavior.

### 4. Accessibility & Inclusivity

Touch targets meet Material Design minimum 48x48px. Text is readable at standard font sizes. Arabic and English are first-class languages with complete localization. Color contrast meets WCAG AA standards. Motor-impaired users can navigate all features.

### 5. Performance Responsiveness

Core operations (search, verse study, streak calculation) must feel instant. Expensive I/O is cached. API calls are parallelized when possible. UI never blocks on network requests. Loading states are shown for any operation exceeding 200ms.

## Governance

- All changes must pass `flutter analyze` with zero warnings
- Architecture violations (data importing presentation) are blocking
- New QF API integrations must include offline fallback
- Specs follow the speckit workflow: specify → clarify → plan → tasks → implement
