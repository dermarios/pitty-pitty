import MediaPlayer
import UIKit

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

    // Manter tempo anterior se não foi fornecido
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