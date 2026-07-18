import 'dart:html' as html;
import 'dart:js' as js;
import '../controllers/game_controller.dart';

// Keep reference to the opened spectator window
html.WindowBase? _spectatorWindow;

void setArguments(List<String> args) {}
Future<void> initializeDesktopWindow() async {}

void openSpectatorWindow(String stateJson) {
  final origin = html.window.location.origin;
  final pathname = html.window.location.pathname;
  final fullUrl = '$origin$pathname#/spectator';
  _spectatorWindow = html.window.open(fullUrl, 'Spectator Screen');
  
  // Write to localStorage as fallback
  try {
    html.window.localStorage['game_state'] = stateJson;
  } catch (e) {
    // Ignore sandbox errors
  }

  // Send state message after a short delay
  Future.delayed(const Duration(milliseconds: 500), () {
    _spectatorWindow?.postMessage(stateJson, '*');
  });
}

void initWebSync(GameController controller) {
  // 1. Spectator Window (Read-only Sync)
  if (isSpectatorUrl()) {
    // Listen for state messages from the opener (moderator)
    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is String && data != 'ready' && data != 'request_state') {
        try {
          controller.importGameStateJson(data);
        } catch (e) {
          // Ignore
        }
      }
    });

    // Notify the opener that we are ready to receive state
    html.window.opener?.postMessage('ready', '*');
    
    // Fallback: Read initial state from localStorage if available
    try {
      final initialState = html.window.localStorage['game_state'];
      if (initialState != null) {
        controller.importGameStateJson(initialState);
      }
    } catch (e) {
      // Ignore
    }
  } 
  // 2. Moderator Window (Control Sync)
  else {
    // Listen for "ready" message from spectator window and reply with current state
    html.window.onMessage.listen((event) {
      if (event.data == 'ready') {
        _spectatorWindow?.postMessage(controller.exportGameStateJson(), '*');
      }
    });

    // Listen to changes and sync them
    controller.addListener(() {
      final stateJson = controller.exportGameStateJson();
      
      // Direct message sync
      _spectatorWindow?.postMessage(stateJson, '*');

      // LocalStorage fallback sync
      try {
        html.window.localStorage['game_state'] = stateJson;
      } catch (e) {
        // Ignore
      }
    });
  }

  // Failsafe: Listen to local storage updates from other tabs
  html.window.onStorage.listen((event) {
    if (event.key == 'game_state' && event.newValue != null) {
      try {
        controller.importGameStateJson(event.newValue!);
      } catch (e) {
        // Ignore
      }
    }
  });
}

bool isSpectatorUrl() {
  final href = html.window.location.href;
  return href.contains('spectator') || href.contains('view=spectator');
}

void toggleWebFullScreen() {
  try {
    js.context.callMethod('eval', [
      '''
      (function() {
        var doc = document;
        var element = doc.documentElement;
        var isFullscreen = doc.fullscreenElement || doc.webkitFullscreenElement || doc.mozFullScreenElement || doc.msFullscreenElement;
        
        if (isFullscreen) {
          if (doc.exitFullscreen) doc.exitFullscreen();
          else if (doc.webkitExitFullscreen) doc.webkitExitFullscreen();
          else if (doc.mozCancelFullScreen) doc.mozCancelFullScreen();
          else if (doc.msExitFullscreen) doc.msExitFullscreen();
        } else {
          if (element.requestFullscreen) element.requestFullscreen();
          else if (element.webkitRequestFullscreen) element.webkitRequestFullscreen();
          else if (element.mozRequestFullScreen) element.mozRequestFullScreen();
          else if (element.msRequestFullscreen) element.msRequestFullscreen();
        }
      })()
      '''
    ]);
  } catch (e) {
    print('Fullscreen error: $e');
  }
}
