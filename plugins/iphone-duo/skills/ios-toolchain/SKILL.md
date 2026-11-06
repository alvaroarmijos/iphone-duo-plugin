---
name: ios-toolchain
description: iPhone Duo step 4/8. Builds the Flutter iOS app with the iOS 27.1 SDK (Xcode 27.1) locally and in CI so it fills the iPhone Duo inner display instead of being letterboxed; aligns pods to iOS 15, removes UIRequiresFullScreen, checks the launch screen scales, documents the requirement. Use as part of iphone-duo:adopt or alone to "build with Xcode 27.1 / fix letterboxing on iPhone Duo".
---

# Step 4 — Build with the iOS 27.1 SDK

**Why:** without the iOS 27.1 SDK the app runs letterboxed on the inner display, and none of steps 5–8 are visible. Xcode 27.1 also rejects deployment targets below iOS 15.

**Reads from the profile:** `xcode.*`, `ios.deployment_target`, `ios.podfile_forced_target`, `ios.requires_full_screen`, `ios.flavors`. CI recipes: `references/ci-xcode-pins.md`.

## Scope

In: Xcode version in every CI config; Podfile `platform :ios` and forced `IPHONEOS_DEPLOYMENT_TARGET`; Runner deployment target if below 15; removing `UIRequiresFullScreen`; launch screen scaling; README requirement.
Out: Flutter upgrade and UIScene (steps 1–3); hinge detection (step 7); layouts (step 5); Android.

## Implement

1. **Local build first.** Check `xcodebuild -version`. If it's not the required version, stop and ask the developer to install it (`xcodes install 27.1` or the App Store) and select it (`sudo xcode-select -s /Applications/Xcode-27.1.app`). Then build every flavor without signing: `<flutter> build ios --no-codesign [--flavor <f> -t <entrypoint>]`. Plugin pods that fail to compile → update that pod/plugin in its own commit, or stop and report.
2. **Deployment targets.** `ios/Podfile`: `platform :ios, '15.0'` (or higher if already higher). If `post_install` forces `IPHONEOS_DEPLOYMENT_TARGET` below 15, raise it to `'15.0'`. Raise `IPHONEOS_DEPLOYMENT_TARGET` in `project.pbxproj` (all configurations) if below 15. Run `pod install` (`cd ios && pod install --repo-update` if needed) and confirm no deployment-target warnings. Flutter's own pods still declare 13.0, so force them in `post_install`:

   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       target.build_configurations.each do |config|
         config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
       end
     end
   end
   ```
3. **Simulator `lipo` error.** If the simulator build dies in `debug_unpack_ios` with "does not contain architectures arm64 x86_64", Xcode 27.1's `lipo` is rejecting Flutter's two-slice call. Add `ARCHS = arm64` to `ios/Flutter/Debug.xcconfig`, tell the developer it breaks debug builds on Intel Macs / x86_64 simulators, and note it in the README. Skip this if the build works.
4. **Full screen.** Remove `UIRequiresFullScreen` from every `Info.plist` (it is deprecated and blocks Split View). Ask before also widening `UISupportedInterfaceOrientations` if the profile's orientation policy is `unlock`.
5. **CI.** Set the Xcode version explicitly (never `latest`) in every config from the profile, using the recipes in `references/ci-xcode-pins.md`. Ask the developer to run the development pipeline and report the result.
6. **Launch screen.** Open `ios/Runner/Base.lproj/LaunchScreen.storyboard`: images must use constraints (center/aspect-fit), not fixed frames or sizes. Fix if needed. Check on the iPhone Duo simulator, outer and inner display.
7. **README.** Add the Xcode requirement to the setup section.

## Verify

- [ ] Every CI config pins the required Xcode version.
- [ ] CI development build is green (developer confirms).
- [ ] Local `<flutter> build ios --no-codesign` succeeds for every flavor with the required Xcode.
- [ ] `ios/Podfile` targets ≥ iOS 15 and its `post_install` forces nothing lower; `pod install` and the build show no deployment-target warnings.
- [ ] `grep -rn UIRequiresFullScreen ios/` returns nothing.
- [ ] On the iPhone Duo simulator, inner display, the app reaches all four edges (no black bars).
- [ ] The launch screen is undistorted on the outer and inner displays.
- [ ] The README states the Xcode requirement (and the `ARCHS = arm64` caveat, if applied).

## Decisions (defaults)

- The required Xcode locally and in CI, pinned explicitly.
- iOS 15 minimum: Xcode 27.1 needs it, and pods forced to 13 warn or fail.
- Remove `UIRequiresFullScreen`.
- Validate on the iPhone Duo simulator when there's no device.

## Risks

| Risk | Mitigation |
|---|---|
| A pod doesn't compile with the new SDK | Found in the local build before touching CI; update that pod separately. |
| Raising the pod target breaks a pod that assumed 13 | `pod install` + build catch it; update the pod. |
| CI image for that Xcode changes or disappears | Pin the exact version, not `latest`. |
| Dropping iOS 13/14 users | Tell the developer; check analytics for the share of users below 15 before merging. |
