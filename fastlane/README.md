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

### ios build

```sh
[bundle exec] fastlane ios build
```

Compile the app without signing — a fast sanity check before a real build

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture App Store screenshots: iPhone and iPad (see Snapfile), then Apple Watch

### ios watch_screenshots

```sh
[bundle exec] fastlane ios watch_screenshots
```

Capture Apple Watch screenshots (snapshot can't drive watchOS, so this uses simctl)

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload fastlane/screenshots to App Store Connect, replacing what's there

### ios refresh_screenshots

```sh
[bundle exec] fastlane ios refresh_screenshots
```

Capture screenshots and upload them in one go

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Bump the build number, archive, and upload to TestFlight (internal testers)

### ios beta_external

```sh
[bundle exec] fastlane ios beta_external
```

Same as beta, but also distributes to the External Testers group

### ios release

```sh
[bundle exec] fastlane ios release
```

Submit the latest TestFlight build for App Store review (no new build)

### ios release_full

```sh
[bundle exec] fastlane ios release_full
```

Build a fresh version, upload it, and submit for review. Pass version:1.22 to bump.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
