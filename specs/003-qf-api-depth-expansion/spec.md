# Feature Specification: Quran Foundation API Depth Expansion

**Feature Branch**: `003-qf-api-depth-expansion`
**Created**: 2026-04-28
**Status**: Draft
**Input**: Audit report Pillar 1 (H1, H2, H3) — QF Streak Tracking API, QF Activity & Goals API, Quran MCP semantic search integration

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Daily Reading Streak Synced to Cloud (Priority: P1)

As a user who reads Quran daily, my reading streak is automatically tracked and synced to my Quran Foundation account. When I complete khatmah reading sessions, the app reports my daily activity to the QF Streak API so my streak is preserved across devices and visible on my QF profile.

**Why this priority**: Streak tracking is the highest-impact QF API integration for hackathon judging — the local khatmah tracker already has daily reading logs, so this maps naturally to the QF Streak User API. It directly addresses a "Missing" item in the hackathon compliance matrix.

**Independent Test**: Complete a khatmah reading session, verify the QF Streak API receives the activity via network inspection, then check that the streak count is visible on the user's QF profile. Log out, log in on a different device, and confirm the streak is restored from the cloud.

**Acceptance Scenarios**:

1. **Given** the user is authenticated via QF OAuth2, **When** they complete a khatmah reading session (read at least one page), **Then** the app reports the daily activity to the QF Streak API.
2. **Given** the user has a streak of N days on their QF profile, **When** they open the app and navigate to the khatmah dashboard, **Then** the local streak display is reconciled with the cloud streak (taking the higher value).
3. **Given** the user is offline, **When** they complete a reading session, **Then** the activity is queued locally and synced to the QF Streak API when connectivity is restored.
4. **Given** the user is not authenticated, **When** they use khatmah tracking, **Then** streaks are tracked locally only (graceful degradation).

---

### User Story 2 - Memorization Goals Synced to QF Activity & Goals (Priority: P2)

As a hafiz student with memorization goals, my progress is tracked and synced to my Quran Foundation goals profile. I can set daily/weekly memorization targets, and my actual progress (verses memorized, sessions completed, SM-2 review performance) is reported to the QF Goals API.

**Why this priority**: Activity & Goals is the second missing User API integration. Combined with Streaks, it provides comprehensive coverage of the QF User API category, which judges will evaluate for "Effective Use of APIs."

**Independent Test**: Create a memorization goal (e.g., memorize 5 pages this week), complete some review sessions, and verify the QF Goals API receives activity records. Check the goal progress reflects both local and cloud data.

**Acceptance Scenarios**:

1. **Given** the user is authenticated, **When** they create or update a memorization goal, **Then** the goal is synced to the QF Goals API with target metrics and deadline.
2. **Given** the user completes a memorization session (SM-2 review), **When** the session ends, **Then** the app reports an activity record to the QF Activity API (verses reviewed, accuracy score, duration).
3. **Given** the user has existing goals on their QF profile, **When** they first open the app after login, **Then** the app fetches and displays any existing QF goals alongside local goals.
4. **Given** a sync conflict (local vs. cloud goal data), **When** reconciliation runs, **Then** the most recent data wins, with local progress preserved.

---

### User Story 3 - Semantic Quran Search via MCP (Priority: P3)

As a user searching for Quranic verses, I can perform semantic search queries in natural language (e.g., "verses about patience during hardship") and receive contextually relevant results powered by the Quran MCP service. This supplements the existing exact-text search with AI-powered understanding.

**Why this priority**: Quran MCP integration is a clear innovation differentiator highlighted by the hackathon. It transforms the app's search from brute-force text matching to intelligent semantic retrieval, which is technically impressive and uniquely valuable.

**Independent Test**: Type a natural language query like "verses about mercy" in the search screen, verify that the MCP API returns semantically relevant verses (not just exact keyword matches), and confirm results are displayed with proper Arabic text and translation.

**Acceptance Scenarios**:

1. **Given** the user is on the search screen, **When** they enter a semantic query (e.g., "verses about forgiveness"), **Then** the app sends the query to the Quran MCP API and displays semantically relevant results.
2. **Given** MCP search results are returned, **When** the user taps a result, **Then** they are navigated to the verse in context (surah view with the verse highlighted).
3. **Given** the MCP API is unavailable or returns an error, **When** a semantic search fails, **Then** the app gracefully falls back to the existing local search with a message indicating semantic search is unavailable.
4. **Given** the user enters a traditional search (Arabic text, surah name, or verse reference), **When** the query matches an exact pattern, **Then** the existing search behavior is preserved (MCP is used for natural language queries only).

---

### Edge Cases

- What happens when the QF Streak API returns a different streak count than the local tracker? → Reconcile by taking the higher streak value and backfill missing days from whichever source has data.
- What happens when the QF Goals API rate limit is hit during bulk sync? → Queue remaining requests with exponential backoff and retry on next app launch.
- What happens when MCP returns verses outside the standard 6,236 verse count (e.g., commentary references)? → Validate verse keys against the local Quran index before displaying.
- What happens when the user logs out while sync is in progress? → Cancel in-flight requests, preserve local data, and clear cloud tokens.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST report daily reading activity to the QF Streak API when the user completes a khatmah session while authenticated. (H1)
- **FR-002**: The app MUST fetch and display the user's current streak from the QF Streak API, reconciling with local streak data by taking the higher value. (H1)
- **FR-003**: The app MUST queue streak activity locally when offline and sync to the QF Streak API when connectivity is restored. (H1)
- **FR-004**: The app MUST create, update, and sync memorization goals to the QF Goals API for authenticated users. (H2)
- **FR-005**: The app MUST report memorization session activity (verses reviewed, accuracy, duration) to the QF Activity API. (H2)
- **FR-006**: The app MUST fetch existing QF goals on login and merge with local goals, preserving local progress. (H2)
- **FR-007**: The app MUST support semantic search via the Quran MCP API (`mcp.quran.ai`) for natural language queries. (H3)
- **FR-008**: The app MUST gracefully fall back to existing local search when the MCP API is unavailable. (H3)
- **FR-009**: All QF API integrations MUST use the existing OAuth2 PKCE authentication flow and token management. (H1, H2)
- **FR-010**: All QF API interactions MUST be non-blocking — local functionality continues to work regardless of API availability. (H1, H2, H3)

### Key Entities

- **StreakRecord**: Daily reading activity with date, pages/verses read, and sync status (pending/synced/failed)
- **UserGoal**: Memorization or reading goal with target metric, deadline, current progress, and cloud sync state
- **ActivityRecord**: Session-level activity with type (memorization/reading), metrics (verses, accuracy, duration), and timestamp
- **SemanticSearchResult**: MCP API response containing verse references, relevance scores, and contextual snippets

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Authenticated users see their reading streak reflected on their QF profile within 60 seconds of completing a khatmah session.
- **SC-002**: Streak data survives app reinstall and re-login (cloud streak is restored from QF API).
- **SC-003**: Memorization goals and activity records are visible in the QF user dashboard after syncing.
- **SC-004**: Semantic search returns relevant results for 90%+ of natural language queries about common Quranic topics (mercy, patience, forgiveness, etc.).
- **SC-005**: Local app functionality (reading, memorization, bookmarks) continues to work when all QF APIs are unreachable.
- **SC-006**: The app's hackathon judging score for "Effective Use of APIs" improves from the estimated 8-10 to 13-15 out of 15.

## Assumptions

- The QF Streak API and Activity/Goals API endpoints are documented and accessible with the existing QF OAuth2 tokens.
- The Quran MCP service at `mcp.quran.ai` provides a REST or WebSocket API for semantic search queries.
- The existing khatmah local data model (daily reading logs stored in Hive) can be extended with a sync-status field without a migration breaking change.
- The existing QF API interceptors handle authentication headers correctly for new endpoints (assuming TECH-04 fix from spec 005 is applied or endpoints use distinct paths).
- Semantic search results can be mapped to the existing verse key format (`surah:verse`) used throughout the app.
