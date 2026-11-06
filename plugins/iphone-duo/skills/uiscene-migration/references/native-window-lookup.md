# Finding the window and the FlutterViewController under UIScene

Under UIScene, `UIApplication.delegate.window` and `AppDelegate.window` are `nil`, and `UIApplication.shared.keyWindow`, `UIApplication.shared.windows` and `UIScreen.main` are deprecated. Resolve the window from a scene **when you need it**, never cache it at launch: the iPhone Duo moves the scene between displays.

Replacements, from Flutter's official guide (https://docs.flutter.dev/release/breaking-changes/uiscenedelegate):

| Deprecated | Replacement |
|---|---|
| `UIScreen.main` | `windowScene.screen` |
| `UIApplication.shared.keyWindow` | `windowScene.keyWindow` |
| `UIApplication.shared.windows` | `windowScene.windows` |
| `UIApplication.shared.delegate.window` | `view.window` |

## First-party plugins (Flutter 3.38+)

The guide's pattern: keep the registrar and reach the window through its `viewController`.

```swift
public class MyPlugin: NSObject, FlutterPlugin {
  weak var registrar: FlutterPluginRegistrar?

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MyPlugin(registrar: registrar)
    // ...
  }

  func someMethod() {
    let window = registrar?.viewController?.view.window
    let screen = window?.windowScene?.screen
  }
}
```

```objc
// Before:  UIViewController *root = [[[UIApplication sharedApplication] delegate] window].rootViewController;
// After:   UIWindow *window = self.registrar.viewController.view.window;
//          UIScreen *screen = window.windowScene.screen;
```

## App code without a registrar (SDK callbacks, AppDelegate)

Look up the foreground scene at call time.

### Swift

```swift
import Flutter
import UIKit

extension UIApplication {
  /// Key window of the foreground-active window scene, if any.
  var activeKeyWindow: UIWindow? {
    let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
    return (scenes.first { $0.activationState == .foregroundActive } ?? scenes.first)?
      .keyWindow
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

### Objective-C

```objc
static UIWindow *ActiveKeyWindow(void) {
  UIWindowScene *fallback = nil;
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if (![scene isKindOfClass:[UIWindowScene class]]) continue;
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    if (scene.activationState == UISceneActivationStateForegroundActive) {
      return windowScene.keyWindow;
    }
    if (fallback == nil) fallback = windowScene;
  }
  return fallback.keyWindow;
}
```

Inside a view controller that is on screen, `self.view.window` keeps working and is the simplest choice.
