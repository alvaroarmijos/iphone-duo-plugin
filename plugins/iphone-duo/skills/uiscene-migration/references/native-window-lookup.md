# Finding the window and the FlutterViewController under UIScene

Under UIScene, `UIApplication.delegate.window`, `AppDelegate.window`, `UIApplication.shared.keyWindow` and `UIApplication.shared.windows` are `nil` or deprecated. Resolve the window from the foreground scene **when you need it**, never cache it at launch: the iPhone Duo moves the scene between displays.

## Swift

```swift
import Flutter
import UIKit

extension UIApplication {
  /// Key window of the foreground-active window scene, if any.
  var activeKeyWindow: UIWindow? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }?
      .windows.first { $0.isKeyWindow }
      // Fallback: any window scene (e.g. while the app is still inactive).
      ?? connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first { $0.isKeyWindow }
  }

  /// The app's FlutterViewController, found from the active scene's root.
  /// In a standard Flutter app the root view controller is the FlutterViewController;
  /// adapt this if the app embeds Flutter inside a native container.
  var activeFlutterViewController: FlutterViewController? {
    activeKeyWindow?.rootViewController as? FlutterViewController
  }
}
```

Usage in an SDK callback that routes a deep link:

```swift
func someSdk(_ sdk: SomeSdk, shouldOpenURL url: URL) -> Bool {
  guard let controller = UIApplication.shared.activeFlutterViewController else { return true }
  controller.pushRoute(url.path)   // or the app's own channel
  return false
}
```

## Objective-C (first-party plugins)

```objc
static UIWindow *ActiveKeyWindow(void) {
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if (scene.activationState != UISceneActivationStateForegroundActive) continue;
    if (![scene isKindOfClass:[UIWindowScene class]]) continue;
    for (UIWindow *window in ((UIWindowScene *)scene).windows) {
      if (window.isKeyWindow) return window;
    }
  }
  return nil;
}

// Before:  UIViewController *root = [[[UIApplication sharedApplication] delegate] window].rootViewController;
// After:   UIViewController *root = ActiveKeyWindow().rootViewController;
```

Inside a view controller that is on screen, `self.view.window` keeps working and is the simplest choice.

A plugin can also keep a reference to its registrar's view controller when the Flutter version exposes one (`registrar.viewController`); check the pinned version's API.
