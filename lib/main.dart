

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:skudyx/app/app.dart';
import 'package:skudyx/app/bootstrap.dart';
import 'package:skudyx/app/app_composition_root.dart';
import 'package:skudyx/core/config/app_config.dart';
import 'package:skudyx/core/storage/app_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Required for communication between foreground service and UI
  FlutterForegroundTask.initCommunicationPort();

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
