import Flutter
import UIKit
import AVFoundation
import MediaPlayer

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

    // Delay setup until window and controller are available
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self = self,
            let window = self.window,
            let controller = window.rootViewController as? FlutterViewController else {
        return
      }

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
}

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
