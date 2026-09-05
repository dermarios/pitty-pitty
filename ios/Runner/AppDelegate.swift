import Flutter
import UIKit
import MediaPlayer

// MARK: - LockScreenManager
class LockScreenManager {
  static let shared = LockScreenManager()

  private let commandCenter = MPRemoteCommandCenter.shared()
  private var onPlayCommand: (() -> Void)?
  private var onPauseCommand: (() -> Void)?
  private var onNextCommand: (() -> Void)?
  private var onPreviousCommand: (() -> Void)?

  private init() {
    setupRemoteCommands()
  }

  func setCommandHandlers(
    onPlay: @escaping () -> Void,
    onPause: @escaping () -> Void,
    onNext: @escaping () -> Void,
    onPrevious: @escaping () -> Void
  ) {
    self.onPlayCommand = onPlay
    self.onPauseCommand = onPause
    self.onNextCommand = onNext
    self.onPreviousCommand = onPrevious
  }

  private func setupRemoteCommands() {
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true

    commandCenter.playCommand.addTarget { [weak self] _ in
      self?.onPlayCommand?()
      return .success
    }

    commandCenter.pauseCommand.addTarget { [weak self] _ in
      self?.onPauseCommand?()
      return .success
    }

    commandCenter.nextTrackCommand.addTarget { [weak self] _ in
      self?.onNextCommand?()
      return .success
    }

    commandCenter.previousTrackCommand.addTarget { [weak self] _ in
      self?.onPreviousCommand?()
      return .success
    }
  }

  func updateNowPlaying(
    title: String,
    artist: String,
    duration: Double,
    imageData: Data? = nil
  ) {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    nowPlayingInfo[MPMediaItemPropertyArtist] = artist
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Pitty Player"

    if duration > 0 {
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    }

    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

    if let imageData = imageData, let image = UIImage(data: imageData) {
      let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    print("[LockScreen] ✓ MPNowPlayingInfoCenter updated with: '\(title)' [\(duration)s]")
  }

  func updatePlaybackState(isPlaying: Bool) {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  func updateElapsedTime(_ elapsedTime: Double) {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  func clearNowPlaying() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }
}

// MARK: - AppDelegate
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    setupLockScreenChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupLockScreenChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("[LockScreen] ✗ Could not get FlutterViewController")
      return
    }

    print("[LockScreen] ✓ Setting up lock screen method channel...")
    let channel = FlutterMethodChannel(
      name: "com.forven.pittyplayer/lockscreen",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      print("[LockScreen] Method called: \(call.method)")
      switch call.method {
      case "updateNowPlaying":
        print("[LockScreen] ✓ Updating now playing info")
        self?.handleUpdateNowPlaying(call, result: result)
      case "updatePlaybackState":
        print("[LockScreen] ✓ Updating playback state")
        self?.handleUpdatePlaybackState(call, result: result)
      case "updateElapsedTime":
        print("[LockScreen] ✓ Updating elapsed time")
        self?.handleUpdateElapsedTime(call, result: result)
      case "clearNowPlaying":
        print("[LockScreen] ✓ Clearing now playing")
        LockScreenManager.shared.clearNowPlaying()
        result(nil)
      case "setCommandHandlers":
        print("[LockScreen] ✓ Setting up command handlers")
        self?.setupCommandHandlers(channel: channel)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleUpdateNowPlaying(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      print("[LockScreen] ✗ Invalid arguments for updateNowPlaying")
      result(nil)
      return
    }

    let title = args["title"] as? String ?? ""
    let artist = args["artist"] as? String ?? ""
    let duration = args["duration"] as? Double ?? 0

    print("[LockScreen] → Setting now playing: '\(title)' by '\(artist)' duration: \(duration)s")

    var imageData: Data? = nil
    if let imageBase64 = args["imageBase64"] as? String {
      imageData = Data(base64Encoded: imageBase64)
    }

    LockScreenManager.shared.updateNowPlaying(
      title: title,
      artist: artist,
      duration: duration,
      imageData: imageData
    )

    print("[LockScreen] ✓ Now playing info set in MPNowPlayingInfoCenter")
    result(nil)
  }

  private func handleUpdatePlaybackState(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(nil)
      return
    }

    let isPlaying = args["isPlaying"] as? Bool ?? false
    LockScreenManager.shared.updatePlaybackState(isPlaying: isPlaying)
    result(nil)
  }

  private func handleUpdateElapsedTime(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(nil)
      return
    }

    let elapsedTime = args["elapsedTime"] as? Double ?? 0
    LockScreenManager.shared.updateElapsedTime(elapsedTime)
    result(nil)
  }

  private func setupCommandHandlers(channel: FlutterMethodChannel) {
    LockScreenManager.shared.setCommandHandlers(
      onPlay: { [weak self] in
        self?.sendCommandToFlutter("play", channel: channel)
      },
      onPause: { [weak self] in
        self?.sendCommandToFlutter("pause", channel: channel)
      },
      onNext: { [weak self] in
        self?.sendCommandToFlutter("next", channel: channel)
      },
      onPrevious: { [weak self] in
        self?.sendCommandToFlutter("previous", channel: channel)
      }
    )
  }

  private func sendCommandToFlutter(_ command: String, channel: FlutterMethodChannel) {
    DispatchQueue.main.async {
      channel.invokeMethod("onRemoteCommand", arguments: ["command": command])
    }
  }
}
