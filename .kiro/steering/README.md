# Hafiz App - AI Assistant Steering Guide

This directory contains steering documents that guide AI assistants working on the Hafiz Quran app. These documents are automatically loaded and provide context about the project's architecture, conventions, and best practices.

## Document Overview

### Core Documents

#### [product.md](./product.md)
**What the app does and why**
- Product overview and core features
- Target platforms and user journey
- Mushaf types and their differences
- Roadmap and planned features
- Key principles (offline-first, text integrity, non-profit)

#### [tech.md](./tech.md)
**Technology stack and tools**
- Flutter version and dependencies
- Clean Architecture layers
- State management (BLoC pattern)
- Common commands (dev, test, build, deploy)
- Build configuration and asset management

#### [structure.md](./structure.md)
**Project organization**
- Directory layout and file structure
- Clean Architecture implementation
- Naming conventions (files, classes, variables)
- Dependency flow rules
- Feature organization pattern
- Import conventions

### Best Practices

#### [conventions.md](./conventions.md)
**Code style and patterns**
- BLoC patterns (events, states, naming)
- Error handling with Either<Failure, Success>
- Widget composition guidelines
- Localization workflow
- Analytics and logging patterns
- Performance optimization
- Testing requirements

#### [testing.md](./testing.md)
**Testing guidelines**
- Test structure and organization
- BLoC testing with bloc_test
- Mocking with mocktail
- Widget testing patterns
- Golden tests for visual regression
- Integration tests for user flows
- Coverage goals and priorities

### Domain-Specific

#### [firebase.md](./firebase.md)
**Firebase integration**
- Services used (Crashlytics, Analytics, Performance, Firestore)
- Crashlytics error reporting patterns
- Analytics event tracking
- Performance monitoring
- Firestore data structure
- Configuration and security rules

#### [quran-data.md](./quran-data.md)
**Quran data handling**
- Data sources (local assets, remote API)
- JSON schema and structure
- Bismillah handling rules
- Verse numbering and validation
- Generating assets from Tanzil
- Text processing and normalization
- Attribution requirements (CC BY-ND 3.0)

## Quick Reference

### When Adding a New Feature

Follow this checklist from [structure.md](./structure.md):

1. Create entity in `domain/entities/`
2. Create repository interface in `domain/repository/`
3. Create use case in `domain/usecase/`
4. Implement data source in `data/datasource/`
5. Implement repository in `data/repository/`
6. Create BLoC in `presentation/<feature>/bloc/`
7. Create screen in `presentation/<feature>/`
8. Register dependencies in `injection_container.dart`
9. Add route in `routes/app_routes.dart`
10. Write tests in `test/` mirroring the structure

### Common Patterns

#### BLoC Event/State Pattern
```dart
// Event: <Action><Feature>Event
class LoadSurahEvent extends SurahEvent {
  final String surahId;
  const LoadSurahEvent({required this.surahId});
}

// State: <Status><Feature>State
class LoadingSurahState extends SurahState {}
class SuccessSurahState extends SurahState {
  final List<Verse> verses;
  const SuccessSurahState({required this.verses});
}
```

#### Error Handling Pattern
```dart
final result = await repository.getData();
result.fold(
  (failure) => emit(FailureState(errorMessage: failure.errorMessage)),
  (data) => emit(SuccessState(data: data)),
);
```

#### Logging Pattern
```dart
Logger.error(
  'Operation failed',
  feature: 'FeatureName',
  error: e,
  stackTrace: stackTrace,
  fatal: false,
);
```

### Key Constraints

#### Quran Text Integrity
- **Never modify** Quran text - it's licensed CC BY-ND (No Derivatives)
- Always attribute Tanzil.net as source
- Verify text integrity before deployment

#### Clean Architecture Rules
- Presentation → Domain → Data (one-way dependency)
- Domain layer has no Flutter imports
- Use dependency injection (GetIt) to wire layers
- Repository interfaces in domain, implementations in data

#### Performance Guidelines
- Use `const` constructors everywhere possible
- Load Surahs lazily (on demand)
- Cache parsed data in Hive
- Use `ListView.builder` for long lists

#### Testing Requirements
- BLoCs: 100% coverage
- Use Cases: 100% coverage
- Repositories: 90% coverage
- Test all error paths

## Development Workflow

### Before Starting Work
1. Read [product.md](./product.md) to understand the feature context
2. Review [structure.md](./structure.md) for file organization
3. Check [conventions.md](./conventions.md) for code patterns

### During Development
1. Follow Clean Architecture layers
2. Use BLoC pattern for state management
3. Add localization strings for both English and Arabic
4. Log errors with `Logger` class
5. Use `const` constructors

### Before Committing
1. Run `dart format lib/ test/`
2. Run `flutter analyze` (should have no warnings)
3. Run `flutter test` (all tests should pass)
4. Write tests for new features
5. Update documentation if needed

### Deployment
- Android: Use Fastlane (`bundle exec fastlane deploy_internal`)
- Version: Update in `pubspec.yaml` (format: `major.minor.patch+build`)
- Changelog: Update `RELEASE_NOTES.md`

## Common Commands

```bash
# Development
flutter pub get
flutter run

# Testing
flutter test
flutter test --coverage

# Code Quality
flutter analyze
dart format lib/ test/

# Building
flutter build apk --release
flutter build appbundle --release

# Deployment (Android)
cd android && bundle exec fastlane deploy_internal
```

## Important Files

### Configuration
- `pubspec.yaml` - Dependencies and version
- `analysis_options.yaml` - Linter rules
- `lib/injection_container.dart` - Dependency injection setup
- `lib/core/config/api_config.dart` - API configuration

### Entry Points
- `lib/main.dart` - App entry point
- `lib/routes/app_routes.dart` - Navigation routes
- `lib/core/app_export.dart` - Common exports barrel file

### Data
- `assets/quran/uthmani/` - Quran text (114 JSON files)
- `assets/quran/mushaf_page_index.json` - Page mappings
- `lib/core/quran_index/quran_surah.dart` - Surah metadata

## Getting Help

### Documentation
- README.md - Project overview
- TECH_LEAD_REVIEW.md - Technical review notes
- test/README.md - Testing documentation
- android/fastlane/README.md - Deployment guide

### External Resources
- Flutter docs: https://flutter.dev/docs
- BLoC pattern: https://bloclibrary.dev
- Tanzil Quran: https://tanzil.net
- Quran.com API: https://api-docs.quran.com

## Notes for AI Assistants

### Always Consider
- This is a religious app - handle Quran text with utmost care
- Offline functionality is critical - don't break it
- Support both LTR (English) and RTL (Arabic) layouts
- Test on both light and dark themes
- Consider performance on low-end devices

### Never Do
- Modify Quran text without explicit instruction
- Use `print()` instead of `Logger`
- Store BuildContext in class fields
- Skip writing tests for business logic
- Hardcode strings (use localization)
- Break Clean Architecture dependency rules

### When Uncertain
- Check existing code for similar patterns
- Refer to the relevant steering document
- Follow the principle of least surprise
- Ask for clarification before making breaking changes

---

**Last Updated**: February 2026
**Maintained By**: Hafiz App Team
**License**: See LICENSE file in project root
