# Feature Specification: Musali Teaser Refactor

**Feature Branch**: `fix/musali-teaser-refactor`  
**Created**: 2026-04-16  
**Status**: Draft  

## User Scenarios & Testing

### User Story 1 - Clean Coming Soon Banner (Priority: P1)

After onboarding, the user sees a simple, elegant "Coming Soon" card for Musali instead of a confusing full-screen teaser.

**Why this priority**: The current teaser is confusing and hurts first impression.

**Independent Test**: Complete onboarding, observe the Musali announcement, verify it's easy to skip.

**Acceptance Scenarios**:

1. **Given** user completes onboarding, **When** Musali teaser appears, **Then** it clearly says "Coming Soon" with a simple description of what Musali is
2. **Given** user sees the teaser, **When** they tap Skip, **Then** they go directly to home screen

### Edge Cases

- User has seen teaser before (persist skip state)
- Arabic vs English layout

## Requirements

### Functional Requirements

- **FR-001**: Teaser MUST clearly explain what Musali is
- **FR-002**: Teaser MUST be skippable with one tap
- **FR-003**: Teaser MUST NOT show again after being skipped once
- **FR-004**: Teaser MUST work in both English and Arabic

## Success Criteria

- **SC-001**: Users understand what Musali is from the teaser
- **SC-002**: 100% of users can skip with one tap
