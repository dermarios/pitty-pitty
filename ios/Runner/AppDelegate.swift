import Flutter
import UIKit
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
  static var audioChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Configure AVAudioSession for background playback with lock screen controls
    configureAudioSession()

    // Setup Flutter channel for lock screen commands
    setupAudioChannel()

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

  private func setupAudioChannel() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      guard let self = self,
            let controller = self.window?.rootViewController as? FlutterViewController else {
        return
      }

      AppDelegate.audioChannel = FlutterMethodChannel(
        name: "com.forven.pittyplayer/audio",
        binaryMessenger: controller.binaryMessenger
      )

      let lockScreenManager = LockScreenManager.shared
      lockScreenManager.setAudioChannel(AppDelegate.audioChannel)
      lockScreenManager.setupRemoteCommands()
    }
  }
}

// MARK: - LockScreenManager
class LockScreenManager {
  static let shared = LockScreenManager()

  private let commandCenter = MPRemoteCommandCenter.shared()
  private var audioChannel: FlutterMethodChannel?

  private init() {}

  func setAudioChannel(_ channel: FlutterMethodChannel?) {
    self.audioChannel = channel
  }

  func setupRemoteCommands() {
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true

    commandCenter.playCommand.addTarget { [weak self] _ in
      print("[LockScreen] Play button tapped")
      self?.audioChannel?.invokeMethod("play", arguments: nil)
      return .success
    }

    commandCenter.pauseCommand.addTarget { [weak self] _ in
      print("[LockScreen] Pause button tapped")
      self?.audioChannel?.invokeMethod("pause", arguments: nil)
      return .success
    }

    commandCenter.nextTrackCommand.addTarget { [weak self] _ in
      print("[LockScreen] Next button tapped")
      self?.audioChannel?.invokeMethod("next", arguments: nil)
      return .success
    }

    commandCenter.previousTrackCommand.addTarget { [weak self] _ in
      print("[LockScreen] Previous button tapped")
      self?.audioChannel?.invokeMethod("previous", arguments: nil)
      return .success
    }
  }

  func updateNowPlaying(
    title: String,
    artist: String,
    duration: Double,
    imageData: Data? = nil,
    elapsedTime: Double = 0
  ) {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    nowPlayingInfo[MPMediaItemPropertyArtist] = artist
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Pitty Player"

    if duration > 0 {
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    }

    if elapsedTime > 0 || !nowPlayingInfo.keys.contains(MPNowPlayingInfoPropertyElapsedPlaybackTime) {
      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
    }

    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

    if let imageData = imageData, let image = UIImage(data: imageData) {
      let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
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
