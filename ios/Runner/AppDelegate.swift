import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Configure AVAudioSession for background playback with lock screen controls
    configureAudioSession()

    // Setup lock screen command handlers
    setupLockScreenCommands()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(
        .playback,
        mode: .default,
        options: [.duckOthers]
      )
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("Error configuring audio session: \(error)")
    }
  }

  private func setupLockScreenCommands() {
    let lockScreenManager = LockScreenManager.shared

    // Get reference to the Dart method channel for communicating with Flutter
    let controller = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(
      name: "com.forven.pittyplayer/audio",
      binaryMessenger: controller.binaryMessenger
    )

    // Register lock screen command handlers
    lockScreenManager.setCommandHandlers(
      onPlay: {
        audioChannel.invokeMethod("play", arguments: nil)
      },
      onPause: {
        audioChannel.invokeMethod("pause", arguments: nil)
      },
      onNext: {
        audioChannel.invokeMethod("next", arguments: nil)
      },
      onPrevious: {
        audioChannel.invokeMethod("previous", arguments: nil)
      }
    )
  }
}
