import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:skudyx/core/services/audio_foreground_service.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/composition_root.dart';
import 'core/config/app_config.dart';
import 'core/storage/app_prefs.dart';

/// The entry point of the SkudyX application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize foreground service BEFORE anything else so the
  //    top-level startCallback is registered in this isolate.
  AudioForegroundService.initialize();

  // ✅ Configure audio session for speech/microphone use.
  //    This tells iOS/Android that we need the microphone and that
  //    our audio should not be ducked or interrupted by other apps.
  //
  //    NOTE: No `const` here — the `|` operator on AVAudioSessionCategoryOptions
  //    is not allowed in const expressions (Dart only permits bool/int operands
  //    in const contexts). The configuration object is created at runtime.
  final session = await AudioSession.instance;
  await session.configure(
    AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.voiceChat,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ),
  );

  try {
    await Bootstrap.init();

    final config = AppConfig.fromEnv();
    final prefs = await AppPrefs.create();

    runApp(
      AppCompositionRoot(
        config: config,
        prefs: prefs,
        child: const SkudyXApp(),
      ),
    );
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
}
