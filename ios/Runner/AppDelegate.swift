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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(
        .playback,
        mode: .default,
        options: [.duckOthers, .defaultToSpeaker]
      )
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      // Silently fail if audio session configuration fails
    }
  }
}
