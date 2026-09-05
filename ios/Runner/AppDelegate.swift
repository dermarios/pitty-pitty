import Flutter
import UIKit
import MediaPlayer
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    let mediaChannel = FlutterMethodChannel(
      name: "com.forven.pittyplayer/media",
      binaryMessenger: controller.binaryMessenger
    )

    mediaChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "updateNowPlaying" {
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String,
           let artist = args["artist"] as? String {
          var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
          nowPlayingInfo[MPMediaItemPropertyTitle] = title
          nowPlayingInfo[MPMediaItemPropertyArtist] = artist
          nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Pitty Player"
          MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
          result(nil)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Setup remote commands
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
