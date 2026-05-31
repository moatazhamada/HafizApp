fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac setup_signing

```sh
[bundle exec] fastlane mac setup_signing
```

Create macOS App Store signing assets (installer cert + profile) via ASC API key

### mac build

```sh
[bundle exec] fastlane mac build
```

Build macOS app

### mac build_pkg

```sh
[bundle exec] fastlane mac build_pkg
```

Build and package macOS app for App Store

### mac deploy_testflight

```sh
[bundle exec] fastlane mac deploy_testflight
```

Upload macOS app to TestFlight

### mac deploy_app_store

```sh
[bundle exec] fastlane mac deploy_app_store
```

Upload macOS app to Mac App Store

### mac bump_version

```sh
[bundle exec] fastlane mac bump_version
```

Increment version code in pubspec.yaml

### mac ci_testflight

```sh
[bundle exec] fastlane mac ci_testflight
```

Full CI/CD pipeline: bump version, build, deploy to TestFlight

### mac ci_app_store

```sh
[bundle exec] fastlane mac ci_app_store
```

Full CI/CD pipeline: bump version, build, deploy to App Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
