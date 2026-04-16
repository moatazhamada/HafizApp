# Feature Specification: Statistics Screen

**Feature Branch**: `feature/statistics-screen`  
**Created**: 2026-04-16  
**Status**: Draft  

## User Scenarios & Testing

### User Story 1 - View Reading Progress (Priority: P1)

User opens statistics screen and sees their reading streak, verses read, and bookmark/practice counts.

**Why this priority**: Core value - motivates continued reading.

**Independent Test**: Open statistics screen, verify all stats display correctly.

**Acceptance Scenarios**:

1. **Given** user has reading activity, **When** they open statistics, **Then** correct streak, verses read, and bookmark counts are shown
2. **Given** user has no activity, **When** they open statistics, **Then** encouraging empty state is shown

## Requirements

### Functional Requirements

- **FR-001**: Display reading streak (consecutive days)
- **FR-002**: Display total verses read
- **FR-003**: Display bookmarks count
- **FR-004**: Display practice verses count
- **FR-005**: Show recent activity section
- **FR-006**: Empty state when no data

## Success Criteria

- **SC-001**: Statistics load in under 1 second
- **SC-002**: All counts are accurate
