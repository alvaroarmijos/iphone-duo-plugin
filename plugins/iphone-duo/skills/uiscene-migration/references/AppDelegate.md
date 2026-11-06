# AppDelegate and SceneDelegate under UIScene

Copied from Flutter's official guide, https://docs.flutter.dev/release/breaking-changes/uiscenedelegate (APIs available from Flutter 3.38). If the guide changes, the guide wins.

## AppDelegate — Swift (`ios/Runner/AppDelegate.swift`)

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Method channels and platform views use the bridge's messenger.
    let batteryChannel = FlutterMethodChannel(
      name: "samples.flutter.dev/battery",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    let factory = FLNativeViewFactory(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
```

Don't access `FlutterViewController` in `application(_:didFinishLaunchingWithOptions:)`. `window?.rootViewController as! FlutterViewController` can crash.

## AppDelegate — Objective-C

```objc
// AppDelegate.h
#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface AppDelegate : FlutterAppDelegate <FlutterImplicitEngineDelegate>
@end
```

```objc
// AppDelegate.m
#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didInitializeImplicitFlutterEngine:(NSObject<FlutterImplicitEngineBridge> *)engineBridge {
  [GeneratedPluginRegistrant registerWithRegistry:engineBridge.pluginRegistry];
}

@end
```

## SceneDelegate — Objective-C (optional)

Swift: `SceneDelegate.swift` in this folder. In `Info.plist`, an Objective-C class is named `SceneDelegate` (no module prefix).

```objc
// SceneDelegate.h
#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface SceneDelegate : FlutterSceneDelegate
@end
```

```objc
// SceneDelegate.m
#import "SceneDelegate.h"

@implementation SceneDelegate
// Override scene callbacks as needed, always calling super, e.g.:
// - (void)sceneDidBecomeActive:(UIScene *)scene {
//   [super sceneDidBecomeActive:scene];
// }
@end
```

## Bespoke FlutterViewController use

If the app uses the storyboard `FlutterViewController` in `didFinishLaunching` for reasons other than platform channels, pick one:

```swift
// 1. Subclass it (set the class in Main.storyboard) and use awakeFromNib.
@objc class MyViewController: FlutterViewController {
  override func awakeFromNib() {
    super.awakeFromNib()
    doSomethingWithFlutterViewController(self)
  }
}
```

2. Do it in a custom SceneDelegate's `scene(_:willConnectTo:options:)`, after `super` (see `SceneDelegate.swift`).
