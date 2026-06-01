fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Run Flutter tests

### ios build

```sh
[bundle exec] fastlane ios build
```

Build iOS app (no signing)

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Build iOS archive and IPA

### ios deploy_testflight

```sh
[bundle exec] fastlane ios deploy_testflight
```

Upload to TestFlight (Beta)

### ios deploy_app_store

```sh
[bundle exec] fastlane ios deploy_app_store
```

Upload to App Store (Production)

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Increment version code in pubspec.yaml

### ios ci_testflight

```sh
[bundle exec] fastlane ios ci_testflight
```

Full CI/CD pipeline: Test, Build, Deploy to TestFlight

### ios ci_app_store

```sh
[bundle exec] fastlane ios ci_app_store
```

Full CI/CD pipeline: Test, Build, Deploy to App Store

### ios build_prelive

```sh
[bundle exec] fastlane ios build_prelive
```

Build iOS for prelive environment

### ios build_prelive_ipa

```sh
[bundle exec] fastlane ios build_prelive_ipa
```

Build prelive IPA

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
