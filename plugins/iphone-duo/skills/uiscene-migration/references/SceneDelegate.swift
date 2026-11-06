import Flutter
import UIKit

/// Scene delegate for the single app scene.
///
/// Optional (https://docs.flutter.dev/release/breaking-changes/uiscenedelegate):
/// create it only when there is scene work to do (moved UI life cycle logic,
/// FlutterViewController setup, step 2 workarounds). Otherwise the manifest
/// names FlutterSceneDelegate directly.
///
/// FlutterSceneDelegate is available from Flutter 3.38 (UIScene is the default
/// from 3.41). Register it in Info.plist as $(PRODUCT_MODULE_NAME).SceneDelegate.
/// Every override calls super so Flutter and its plugins receive every event.
class SceneDelegate: FlutterSceneDelegate {

  // Example: setup that needs the FlutterViewController once the window exists.
  // Cold-start URLs, user activities and shortcut items also arrive here,
  // in connectionOptions.
  //
  // override func scene(
  //   _ scene: UIScene,
  //   willConnectTo session: UISceneSession,
  //   options connectionOptions: UIScene.ConnectionOptions
  // ) {
  //   super.scene(scene, willConnectTo: session, options: connectionOptions)
  //   if let controller = window?.rootViewController as? FlutterViewController {
  //     // e.g. SharedAssets.initialize(controller)
  //   }
  // }

  // Example: UI life cycle logic moved from the AppDelegate
  // (applicationDidBecomeActive -> sceneDidBecomeActive, and so on).
  //
  // override func sceneDidBecomeActive(_ scene: UIScene) {
  //   super.sceneDidBecomeActive(scene)
  //   // former applicationDidBecomeActive logic
  // }
  //
  // override func sceneDidEnterBackground(_ scene: UIScene) {
  //   super.sceneDidEnterBackground(scene)
  //   // former applicationDidEnterBackground logic
  // }

  // Example: forward URLs to a plugin that has no scene support (step 2 workaround).
  //
  // override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  //   super.scene(scene, openURLContexts: URLContexts)
  //   for context in URLContexts { SomeSdk.handle(context.url) }
  // }
}

// AppDelegate (Swift), as in the official guide. Objective-C: references/AppDelegate.md.
//
// @main
// @objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     // Only work that needs no window or controller, plus APIs Apple requires
//     // before launch finishes (UNUserNotificationCenter delegate, BGTaskScheduler).
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
//
//   func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
//     GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
//
//     let channel = FlutterMethodChannel(
//       name: "com.example/channel",
//       binaryMessenger: engineBridge.applicationRegistrar.messenger()
//     )
//   }
// }
