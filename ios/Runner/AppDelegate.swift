import Flutter
import UIKit

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
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.forven.pittyplayer/lockscreen",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
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
  }

  private func handleUpdateNowPlaying(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(nil)
      return
    }

    let title = args["title"] as? String ?? ""
    let artist = args["artist"] as? String ?? ""
    let duration = args["duration"] as? Double ?? 0

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
