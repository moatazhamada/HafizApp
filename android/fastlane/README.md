fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android test

```sh
[bundle exec] fastlane android test
```

Run Flutter tests

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Build APK for testing

### android build_aab

```sh
[bundle exec] fastlane android build_aab
```

Build Android App Bundle (AAB) for Play Store

### android deploy_internal

```sh
[bundle exec] fastlane android deploy_internal
```

Deploy to Google Play Internal Testing

### android deploy_beta

```sh
[bundle exec] fastlane android deploy_beta
```

Deploy to Google Play Beta (Closed Testing)

### android deploy_production

```sh
[bundle exec] fastlane android deploy_production
```

Deploy to Google Play Production

### android promote_to_production

```sh
[bundle exec] fastlane android promote_to_production
```

Promote from Internal to Production

### android promote_beta_to_production

```sh
[bundle exec] fastlane android promote_beta_to_production
```

Promote from Beta to Production

### android bump_version

```sh
[bundle exec] fastlane android bump_version
```

Increment version code in pubspec.yaml

### android ci_internal

```sh
[bundle exec] fastlane android ci_internal
```

Full CI/CD pipeline: Test, Build, Deploy to Internal

### android ci_production

```sh
[bundle exec] fastlane android ci_production
```

Full CI/CD pipeline: Test, Build, Deploy to Production

### android deploy_firebase_app_distribution

```sh
[bundle exec] fastlane android deploy_firebase_app_distribution
```

Deploy to Firebase App Distribution for testing

### android build_prelive_apk

```sh
[bundle exec] fastlane android build_prelive_apk
```

Build APK for prelive environment

### android build_prelive_aab

```sh
[bundle exec] fastlane android build_prelive_aab
```

Build AAB for prelive environment

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
