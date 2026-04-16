# Feature Specification: Verse Sharing & Deep Links

**Feature Branch**: `feature/verse-sharing`  
**Created**: 2026-04-16  
**Status**: Draft  

## User Scenarios & Testing

### User Story 1 - Share a Verse (Priority: P1)

User long-presses a verse, selects share, and sends it as text via any messaging app.

**Why this priority**: Core sharing - simplest and most useful.

**Independent Test**: Long-press a verse, share as text, verify clipboard/share dialog works.

**Acceptance Scenarios**:

1. **Given** user long-presses a verse, **When** they tap "Share as Text", **Then** system share dialog opens with verse text + attribution
2. **Given** user long-presses a verse, **When** they tap "Copy Text", **Then** verse text is copied and toast confirms

### User Story 2 - Deep Links (Priority: P2)

User opens app via a deep link to a specific verse.

## Requirements

### Functional Requirements

- **FR-001**: Share verse as text with surah name and attribution
- **FR-002**: Copy verse text to clipboard
- **FR-003**: Handle incoming deep links (hafiz://verse/{surahId}/{verseNum})
- **FR-004**: Share sheet accessible from verse context menu

## Success Criteria

- **SC-001**: Share completes in under 2 taps
- **SC-002**: Deep link opens correct surah/verse within 2 seconds
