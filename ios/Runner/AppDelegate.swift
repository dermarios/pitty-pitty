import Flutter
import UIKit
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup now playing after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.setupNowPlayingChannel()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupNowPlayingChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.forven.pittyplayer/nowplaying",
      binaryMessenger: controller.binaryMessenger
    )

    setupRemoteCommands()

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "updateNowPlaying":
        if let args = call.arguments as? [String: Any] {
          let title = args["title"] as? String ?? ""
          let artist = args["artist"] as? String ?? ""
          let duration = args["duration"] as? Double ?? 0
          self.updateNowPlaying(title: title, artist: artist, duration: duration)
          result(nil)
        } else {
          result(nil)
        }

      case "clearNowPlaying":
        self.clearNowPlaying()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setupRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true
  }

  private func updateNowPlaying(title: String, artist: String, duration: Double = 0) {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    nowPlayingInfo[MPMediaItemPropertyArtist] = artist
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Pitty Player"

    if duration > 0 {
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    }

    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  private func clearNowPlaying() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }
}
