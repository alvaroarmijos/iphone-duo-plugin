# iphone-duo

Adopt iPhone Duo support in any Flutter app. Run `/iphone-duo:adopt` (or `claude --agent iphone-duo:iphone-duo-adopter`) from your app's root. The agent scans the project and asks you which screens must avoid the hinge, the content width, the CI and the critical SDKs. Then it runs eight steps, one at a time, with your approval between them: Flutter 3.41 upgrade, UIScene plugin audit, UIScene migration, iOS 27.1 toolchain, width-driven layouts, life cycle and media (camera, video, maps, audio), hinge detection and hinge avoidance.

Full documentation: see the [repository README](../../README.md).
