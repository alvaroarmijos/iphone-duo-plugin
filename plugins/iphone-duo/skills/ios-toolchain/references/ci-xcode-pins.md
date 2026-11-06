# Pinning Xcode in CI

Always pin an exact version. Confirm the provider's current image list before changing it; image names change.

## GitHub Actions

```yaml
runs-on: macos-26   # a runner image that ships the required Xcode (check the runner-images README)
steps:
  - uses: maxim-lobanov/setup-xcode@v1
    with:
      xcode-version: '27.1'
  # or, without the action:
  - run: sudo xcode-select -s /Applications/Xcode_27.1.app
```

Flutter pin in the same workflow (step 1):

```yaml
  - uses: subosito/flutter-action@v2
    with:
      flutter-version: 3.41.x   # exact patch
      channel: stable
```

## Codemagic (`codemagic.yaml`)

```yaml
workflows:
  ios-development:
    environment:
      flutter: 3.41.x
      xcode: 27.1
```

Every workflow has its own `environment`; update all of them.

## Bitrise (`bitrise.yml`)

```yaml
meta:
  bitrise.io:
    stack: osx-xcode-27.1.x
```

## Xcode Cloud

Select the Xcode version in the workflow's Environment settings (App Store Connect / Xcode). Flutter itself is installed in `ci_scripts/ci_post_clone.sh`; pin the version there.

## Fastlane

`xcversion(version: "27.1")` or `xcodes(version: "27.1", select_for_current_build_only: true)` in the lane, if the lane selects Xcode itself.
