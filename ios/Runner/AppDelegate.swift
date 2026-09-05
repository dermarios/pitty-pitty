import Flutter
import UIKit
import MediaPlayer
import AVFoundation

class MediaPlayerSetup {
  static func setupRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.stopCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true

    commandCenter.playCommand.addTarget { _ in .success }
    commandCenter.pauseCommand.addTarget { _ in .success }
    commandCenter.nextTrackCommand.addTarget { _ in .success }
    commandCenter.previousTrackCommand.addTarget { _ in .success }
  }

  static func updateNowPlaying(title: String, artist: String) {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    nowPlayingInfo[MPMediaItemPropertyArtist] = artist
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Pitty Player"
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let mediaChannel = FlutterMethodChannel(
      name: "com.forven.pittyplayer/media",
      binaryMessenger: controller.binaryMessenger
    )
    mediaChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "updateNowPlaying":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String,
           let artist = args["artist"] as? String {
          MediaPlayerSetup.updateNowPlaying(title: title, artist: artist)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    MediaPlayerSetup.setupRemoteCommands()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
