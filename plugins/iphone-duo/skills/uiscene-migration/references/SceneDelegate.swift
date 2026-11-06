import Flutter
import UIKit

/// Scene delegate for the single app scene.
///
/// Subclass of FlutterSceneDelegate (Flutter >= 3.41). Start with no logic;
/// add only what step 2's audit or controller-dependent setup requires,
/// and always call super so Flutter and its plugins receive every event.
/// Check the Flutter UIScene migration guide for the pinned version's API.
class SceneDelegate: FlutterSceneDelegate {

  // Example: setup that needs the FlutterViewController once the window exists.
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

  // Example: forward URLs to a plugin that has no scene support (step 2 workaround).
  //
  // override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  //   super.scene(scene, openURLContexts: URLContexts)
  //   for context in URLContexts { SomeSdk.handle(context.url) }
  // }
}

// AppDelegate shape (Swift). Use the exact protocol and callback names from
// the migration guide of the pinned Flutter version.
//
// @main
// @objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     // SDK init that doesn't need a window or a controller stays here.
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
//
//   func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
//     GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
//     // Method channels: create them with the engine bridge's messenger.
//   }
// }
