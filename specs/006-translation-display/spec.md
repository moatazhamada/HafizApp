# Feature Specification: Translation Display in Surah & Search

**Feature Branch**: `006-translation-display`
**Created**: 2026-04-29
**Status**: Draft
**Input**: User feedback — translations fetched but never shown in reading/search views

## User Scenarios & Testing

### User Story 1 - Surah Reading Shows Translation Toggle (Priority: P1)

As a reader viewing a surah, I can toggle translation display so that English (or Arabic-localized) translation appears below each Arabic verse, fetched from the QF Content API.

**Why this priority**: The surah screen is the most-used view. Translations are already fetched by Verse Study but invisible here. QF Content API (`/content/v1/translations/{id}/by_chapter/{surahId}`) is the primary source.

**Independent Test**: Open any surah. Tap translation toggle. Verify English translation appears below each verse. Toggle off. Translations disappear.

**Acceptance Scenarios**:
1. **Given** the surah screen is open, **When** the user taps the translation toggle, **Then** English translation (Sahih International, ID 131) appears below each verse, fetched from QF Content API.
2. **Given** translations are shown, **When** the user scrolls through the surah, **Then** translations scroll with their corresponding Arabic verses.
3. **Given** translations are toggled on, **When** the app restarts, **Then** the toggle state is remembered ( persisted in PrefUtils).
4. **Given** no network is available, **When** translation toggle is active, **Then** translations that were previously cached are shown, or a graceful "offline" message appears.

---

### User Story 2 - Search Results Show Translation Preview (Priority: P1)

As a user searching for verses, each search result shows the Arabic text with a one-line translation preview below it, making it easier to identify the right verse.

**Why this priority**: Search is a primary discovery tool. Currently shows only Arabic text, making it hard for non-Arabic readers to find verses.

**Independent Test**: Search for "mercy". Verify each result shows Arabic text and an English translation snippet.

**Acceptance Scenarios**:
1. **Given** search results are displayed, **When** each verse result renders, **Then** the Arabic text is shown with a one-line translation preview below it.
2. **Given** the search uses QF semantic search, **When** results return, **Then** the translation field from the QF response is displayed.
3. **Given** the search uses local search, **When** results are from local JSON, **Then** translations are fetched on-demand from QF Content API or shown from cache.

---

### User Story 3 - Translation Language Respects App Locale (Priority: P2)

As a user who may prefer different translations, the app shows the translation matching the selected locale when available, defaulting to English Sahih International.

**Independent Test**: Change app language. Verify translation language changes if a matching QF translation is available.

**Acceptance Scenarios**:
1. **Given** the app locale is English, **When** translations are fetched, **Then** Sahih International (ID 131) is used.
2. **Given** the app locale is Arabic, **When** translations are fetched, **Then** an Arabic tafsir or translation is shown, or falls back to English with a note.

---

## Edge Cases

- What if the QF Content API is down? → Show cached translations if available, otherwise show "Translation unavailable" placeholder.
- What if translation fetch is slow? → Show Arabic text immediately, translations load asynchronously with a subtle loading indicator.
- What about very long translations? → Truncate to 2 lines with "Read more" that opens Verse Study.

## Requirements

### Functional Requirements

- **FR-001**: Surah screen MUST have a translation toggle (icon button in AppBar) that shows/hides translations below each verse. (US-1)
- **FR-002**: Translations MUST be fetched from QF Content API (`/content/v1/translations/{translationId}/by_chapter/{surahId}`) as the primary source. (US-1, QF priority)
- **FR-003**: VerseModel.fromJson MUST parse translation data when present in API responses. (US-1, US-2)
- **FR-004**: Translation toggle state MUST persist across app restarts via PrefUtils. (US-1)
- **FR-005**: Search results MUST display a one-line translation preview below Arabic text. (US-2)
- **FR-006**: Semantic search results from QF MUST use the `translation` field from the response directly. (US-2)
- **FR-007**: Translation fetching MUST be async — Arabic text renders immediately, translations appear when loaded. (US-1)
- **FR-008**: Translation data SHOULD be cached in memory per surah to avoid re-fetching on scroll/toggle. (US-1)

### Key Entities

- **QfTranslationRemoteDataSource**: Fetches chapter-level translations from QF Content API
- **TranslationCache**: In-memory map of `{surahId: Map<int, String>}` caching verse translations
- **Translation toggle**: Persisted boolean preference controlling translation visibility

## Success Criteria

- **SC-001**: Surah screen shows translation below every verse when toggle is active
- **SC-002**: Search results show translation preview for every match
- **SC-003**: Translation toggle state survives app restart
- **SC-004**: QF Content API is the primary translation source (not Quran.com)
- **SC-005**: Arabic text renders immediately; translations load async within 2 seconds

## Assumptions

- QF Content API translation endpoint returns translations grouped by chapter, matching the surah loading pattern
- Translation ID 131 (Sahih International) is the default English translation on QF
- The existing Dio instance with QfAuthInterceptor handles authentication for content API calls
- Translation text may contain HTML that needs stripping (same as tafsir)
