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

  private override init() {
    super.init()
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
    // Ensure AVAudioSession is active before updating
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      // Continue even if audio session activation fails
    }

    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    nowPlayingInfo[MPMediaItemPropertyArtist] = artist
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Pitty Player"

    if duration > 0 {
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    }

    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
    // IMPORTANT: Set playback rate to 1.0 to show on lock screen
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
    // IMPORTANT: Set is playing flag for iOS 16+
    if #available(iOS 16.0, *) {
      nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
    }

    if let imageData = imageData, let image = UIImage(data: imageData) {
      let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    NSLog("[LockScreen] ✓ MPNowPlayingInfoCenter updated: '%@' (rate=1.0)", title)
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
  private var lockScreenChannelSetup = false
  private weak var lockScreenChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Configure AVAudioSession immediately for lock screen support
    configureAudioSession()

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // AFTER super.application(), try to set up the channel
    // Flutter should be more ready at this point
    DispatchQueue.main.async { [weak self] in
      self?.setupLockScreenChannelImmediately()

    }

    return result
  }


  private func setupLockScreenChannelImmediately() {
    _ = getLockScreenChannel()
  }

  private func ensureLockScreenChannelReady() {
    // This is deprecated - using setupLockScreenChannelImmediately instead
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
      NSLog("[LockScreen] ✓ AVAudioSession configured successfully")
      print("[LockScreen] ✓ AVAudioSession configured successfully")
    } catch {
      NSLog("[LockScreen] ✗ AVAudioSession configuration failed: %@", error.localizedDescription)
      print("[LockScreen] ✗ AVAudioSession configuration failed: \(error)")
    }
  }

  private func getLockScreenChannel() -> FlutterMethodChannel? {
    if let channel = lockScreenChannel {
      return channel
    }

    // Try different ways to get the FlutterViewController
    var controller: FlutterViewController? = window?.rootViewController as? FlutterViewController

    if controller == nil {
      NSLog("[LockScreen] window?.rootViewController is nil, trying UIApplication.shared.windows")
      if let firstWindow = UIApplication.shared.windows.first {
        controller = firstWindow.rootViewController as? FlutterViewController
      }
    }

    guard let controller = controller else {
      NSLog("[LockScreen] ✗ Cannot create channel: no FlutterViewController available")
      NSLog("[LockScreen] window=%s, windows.count=%ld", window != nil ? "exists" : "nil", UIApplication.shared.windows.count)
      return nil
    }

    NSLog("[LockScreen] ✓ Found FlutterViewController, creating channel...")
    let channel = FlutterMethodChannel(
      name: "com.forven.pittyplayer/lockscreen",
      binaryMessenger: controller.binaryMessenger
    )

    lockScreenChannel = channel
    NSLog("[LockScreen] ✓ Lock screen channel created (lazy)")

    // Set up the handler
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      print("[LockScreen] Method called: \(call.method)")
      NSLog("[LockScreen] Method called: %@", call.method)
      switch call.method {
      case "updateNowPlaying":
        self?.handleUpdateNowPlaying(call, result: result)
      case "updatePlaybackState":
        self?.handleUpdatePlaybackState(call, result: result)
      case "updateElapsedTime":
        self?.handleUpdateElapsedTime(call, result: result)
      case "clearNowPlaying":
        LockScreenManager.shared.clearNowPlaying()
        result(nil)
      case "setCommandHandlers":
        self?.setupCommandHandlers(channel: channel)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return channel
  }

  private func setupLockScreenChannel() {
    if getLockScreenChannel() != nil {
      lockScreenChannelSetup = true
      NSLog("[LockScreen] ✓ Lock screen channel setup complete")
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
    print("[LockScreen] Setting up remote command handlers")
    NSLog("[LockScreen] Setting up remote command handlers")
    LockScreenManager.shared.setCommandHandlers(
      onPlay: { [weak self] in
        print("[LockScreen] Remote play command received")
        NSLog("[LockScreen] Remote play command received")
        self?.sendCommandToFlutter("play")
      },
      onPause: { [weak self] in
        print("[LockScreen] Remote pause command received")
        NSLog("[LockScreen] Remote pause command received")
        self?.sendCommandToFlutter("pause")
      },
      onNext: { [weak self] in
        print("[LockScreen] Remote next command received")
        NSLog("[LockScreen] Remote next command received")
        self?.sendCommandToFlutter("next")
      },
      onPrevious: { [weak self] in
        print("[LockScreen] Remote previous command received")
        NSLog("[LockScreen] Remote previous command received")
        self?.sendCommandToFlutter("previous")
      }
    )
  }

  private func sendCommandToFlutter(_ command: String) {
    guard let channel = getLockScreenChannel() else {
      NSLog("[LockScreen] ✗ Cannot send command: channel not available")
      return
    }
    DispatchQueue.main.async {
      channel.invokeMethod("onRemoteCommand", arguments: ["command": command])
    }
  }
}
