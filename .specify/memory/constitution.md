<!--
SYNC IMPACT REPORT
==================
Version change: [TEMPLATE] → 1.0.0
Modified principles: N/A (initial fill from template)
Added sections:
  - Core Principles (5 principles defined)
  - Technical Standards
  - Development Workflow
  - Governance
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (Constitution Check gates align with principles below)
  - .specify/templates/spec-template.md ✅ (Requirements structure aligns with FR/SC format)
  - .specify/templates/tasks-template.md ✅ (Phase structure fits Clean Architecture layers)
Follow-up TODOs: None — all placeholders resolved.
-->

# HafizApp Constitution

## Core Principles

### I. Clean Architecture (NON-NEGOTIABLE)

The codebase MUST maintain strict separation across three layers:
- **Domain** — pure Dart, zero Flutter/framework imports; contains entities, repository interfaces, use cases.
- **Data** — implements repository interfaces; maps models to/from entities; handles API, Hive cache, and local JSON assets.
- **Presentation** — Flutter widgets + BLoC only; MUST NOT call data sources or repositories directly.

Dependencies flow inward only: Presentation → Domain ← Data. Crossing layer boundaries without going through the defined interfaces is forbidden. Every feature MUST register its dependencies in `injection_container.dart` via GetIt (`Factory` for BLoCs, `LazySingleton` for repositories and data sources).

**Rationale**: Enables independent testability of each layer, supports long-term maintainability, and enforces the separation of concerns that makes the app a learning reference for the Flutter community.

### II. Quran Text Integrity (NON-NEGOTIABLE)

The Arabic Quran text is sacred and MUST NOT be modified, generated, or derived from untrusted sources.
- Text MUST be sourced from verified Tanzil Uthmani files and bundled locally under `assets/quran/uthmani/surah_<1-114>.json`.
- Remote API (Quran.com v4) MAY only be used as a fallback when a local file is absent — never as the primary source.
- The Tanzil CC BY-ND 3.0 license MUST be respected: no text modifications; attribution MUST be included in distributed builds.
- Any tooling that regenerates asset files MUST produce byte-identical output for identical input (deterministic generation).

**Rationale**: Integrity of the Quran text is a religious and ethical obligation. Tampering, even accidental, is unacceptable.

### III. Test-Driven Development

All new business logic (use cases, repository implementations, BLoC state machines) MUST have unit tests written before or alongside the implementation.
- Tests MUST use `mocktail` for mocking and `bloc_test` for BLoC verification.
- Test structure MUST mirror `lib/` under `test/`.
- A feature is not considered complete until its BLoC events/states and use-case happy-path + error-path scenarios are covered.
- Widget tests are RECOMMENDED for non-trivial UI flows; integration tests are REQUIRED for cloud-sync and data-persistence features.

**Rationale**: The app serves as a community learning reference and ships to real users. Untested business logic introduces regressions that erode trust.

### IV. Offline-First

The app MUST be fully functional without network access for all core Quran reading and memorization features.
- Quran text is served from local JSON assets; no network call MUST be made when assets are present.
- Bookmarks and user preferences MUST be persisted locally (Hive / SharedPreferences) before any cloud sync attempt.
- Cloud sync (Firebase Firestore) is an enhancement — its failure MUST NEVER block reading or memorization flows.
- Network state MUST be checked via the core `NetworkInfo` abstraction before any remote call; `ConnectionFailure` MUST be surfaced to the user with a graceful offline message.

**Rationale**: A significant portion of users may use the app in areas with intermittent connectivity, during prayer, or in airplane mode. Offline reliability is a fundamental user expectation.

### V. Simplicity & YAGNI

Complexity MUST be justified by a concrete, present requirement. Speculative abstractions, premature generalization, and over-engineering are prohibited.
- New helper classes, utilities, or abstractions are only introduced when used in three or more distinct call sites.
- Feature flags, backwards-compatibility shims, and dead code MUST be removed, not accumulated.
- The `core/app_export.dart` barrel file MUST stay curated — only truly cross-cutting imports belong there.

**Rationale**: The codebase is also a teaching resource. Unnecessary complexity makes it harder to learn from and maintain.

## Technical Standards

- **Language/Runtime**: Flutter (Dart); minimum Flutter SDK version recorded in `pubspec.yaml`.
- **State Management**: BLoC (`flutter_bloc`). HydratedBloc for state that MUST survive app restarts (e.g., ThemeBloc). No raw `setState` in feature screens.
- **Dependency Injection**: GetIt via `injection_container.dart`. MUST NOT use service locator pattern inside domain layer.
- **Networking**: Dio with interceptors defined in `core/network/`. Response parsing errors MUST be mapped to `ServerFailure`.
- **Error Handling**: All repository methods MUST return `Either<Failure, T>` (fpdart). Raw exceptions MUST NOT propagate to BLoC or UI.
- **Localization**: All user-visible strings MUST use the `.tr` extension. New strings MUST be added to both `en_US` and `ar_EG` translation maps before merging.
- **CI/CD**: Fastlane manages Play Store deployments. GitHub Actions deploys `feature/sheikh-recitation-coach` to Internal Testing and `v*` tags to Production (requires approval). Tests and `flutter analyze` MUST pass before deployment.

## Development Workflow

- **Branching**: Feature branches named `feature/<short-description>`. PRs target `master`.
- **Code Review**: Every PR MUST be reviewed for Clean Architecture compliance (Principle I) before merge.
- **Constitution Check**: The plan template's "Constitution Check" gate MUST be completed for every new feature plan. Violations require justification in the Complexity Tracking table.
- **Deployment**: Internal releases via `bundle exec fastlane deploy_internal`; Production via `bundle exec fastlane deploy_production` after tag approval.
- **Quran Asset Updates**: Changes to `assets/quran/uthmani/` MUST use `dart run tool/generate_quran_assets.dart` from a verified Tanzil source. Manual edits to JSON files are forbidden.

## Governance

This constitution supersedes all other informal practices and conventions within the HafizApp repository. Amendments require:
1. A documented rationale explaining the change.
2. A PR that updates this file and any affected templates (`.specify/templates/`).
3. Version increment per semantic versioning rules defined below.

**Versioning policy**:
- **MAJOR**: Removal or redefinition of an existing principle; backward-incompatible governance change.
- **MINOR**: New principle or section added; materially expanded guidance.
- **PATCH**: Clarifications, wording refinements, typo fixes.

All PRs and plan reviews MUST verify compliance with Principles I–V. Complexity that violates a principle MUST be explicitly justified in the plan's Complexity Tracking table.

**Version**: 1.0.0 | **Ratified**: 2026-04-07 | **Last Amended**: 2026-04-07
