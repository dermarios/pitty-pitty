import 'package:flutter/services.dart';
import 'audio_service.dart';

class IosLockScreenHandler {
  static const platform = MethodChannel('com.forven.pittyplayer/audio');

  static void initialize(AudioService audioService) {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          if (audioService.currentTrack != null) {
            await audioService.resume();
          }
          break;
        case 'pause':
          await audioService.pause();
          break;
        case 'next':
          await audioService.next();
          break;
        case 'previous':
          await audioService.previous();
          break;
        default:
          throw PlatformException(
            code: 'UNKNOWN_METHOD',
            message: 'Unknown method: ${call.method}',
          );
      }
    });
  }
}