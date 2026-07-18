import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import '../controllers/game_controller.dart';

bool get isSpectatorMode => _isSpectator;
bool _isSpectator = false;

void setArguments(List<String> args) {
  if (args.contains('--spectator')) {
    _isSpectator = true;
  }
}

void openSpectatorWindow(String stateJson) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/cultural_competition/live_state.json');
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(stateJson);

    // Launch a new instance of the Windows app with --spectator flag
    await Process.start(Platform.resolvedExecutable, ['--spectator']);
  } catch (e) {
    debugPrint('Failed to launch spectator window: $e');
  }
}

Future<void> _readLiveFile(File file, GameController controller) async {
  try {
    if (await file.exists()) {
      final content = await file.readAsString();
      controller.importGameStateJson(content);
    }
  } catch (e) {
    // Ignore lock issues
  }
}

void initWebSync(GameController controller) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/cultural_competition/live_state.json');

    // 1. Load initial state if we are in spectator mode
    if (_isSpectator && await file.exists()) {
      await _readLiveFile(file, controller);
    }

    // 2. Setup synchronization
    if (_isSpectator) {
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // A. Directory Watcher
      parentDir.watch().listen(
        (event) async {
          if (event.path.endsWith('live_state.json')) {
            await Future.delayed(const Duration(milliseconds: 50));
            await _readLiveFile(file, controller);
          }
        },
        onError: (e) {
          debugPrint('Directory watch error: $e');
        },
      );

      // B. Timer Polling Fallback (every 500ms)
      DateTime? lastReadTime;
      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        try {
          if (await file.exists()) {
            final stats = await file.stat();
            if (lastReadTime == null || stats.modified.isAfter(lastReadTime!)) {
              lastReadTime = stats.modified;
              await _readLiveFile(file, controller);
            }
          }
        } catch (e) {
          // Ignore read errors
        }
      });
    }
    // 3. For Moderator mode: write changes to the live file
    else {
      controller.addListener(() async {
        try {
          final content = controller.exportGameStateJson();
          await file.writeAsString(content);
        } catch (e) {
          // Ignore write conflicts
        }
      });
    }
  } catch (e) {
    debugPrint('Desktop sync initialization failed: $e');
  }
}

bool isSpectatorUrl() => _isSpectator;

void toggleWebFullScreen() async {
  try {
    bool isFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullScreen);

    // Give Windows OS 100ms to apply fullscreen transitions
    await Future.delayed(const Duration(milliseconds: 100));

    // Refocus and show to force OS message loop to update hit-test coordinate system
    await windowManager.focus();
    await windowManager.show();
  } catch (e) {
    debugPrint('Failed to toggle fullscreen: $e');
  }
}

Future<void> initializeDesktopWindow() async {
  try {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: const Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: _isSpectator ? 'شاشة العرض (الجمهور)' : 'لوحة التحكم (المنسق)',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (e) {
    debugPrint('Failed to initialize window manager: $e');
  }
}
