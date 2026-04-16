# Feature Specification: Auto-Scroll in Surah Screen

**Feature Branch**: `feature/auto-scroll`  
**Created**: 2026-04-16  
**Status**: Draft  

## User Scenarios & Testing

### User Story 1 - Hands-Free Reading (Priority: P1)

User enables auto-scroll and the surah text scrolls automatically at a comfortable speed.

**Why this priority**: Core value - enables hands-free Quran reading.

**Independent Test**: Open a surah, toggle auto-scroll, verify smooth scrolling at configurable speed.

**Acceptance Scenarios**:

1. **Given** user is reading a surah, **When** they tap auto-scroll button, **Then** text begins scrolling smoothly
2. **Given** auto-scroll is active, **When** user taps screen, **Then** scrolling pauses
3. **Given** auto-scroll is active, **When** user changes speed to fast, **Then** scroll speed increases

## Requirements

### Functional Requirements

- **FR-001**: Toggle auto-scroll on/off from app bar
- **FR-002**: Configurable speed (slow/normal/fast)
- **FR-003**: Tap to pause/resume
- **FR-004**: Speed preference persisted
- **FR-005**: Must not conflict with manual scrolling

## Success Criteria

- **SC-001**: Smooth scrolling at 60fps
- **SC-002**: Speed change takes effect within 1 second
