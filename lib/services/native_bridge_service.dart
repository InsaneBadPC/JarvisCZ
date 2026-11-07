import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'air_gesture_service.dart';
import 'charging_telemetry_service.dart';
import 'jarvis_service.dart';
import 'sentry_service.dart';
import 'settings_service.dart';
import 'voice_service.dart';

/// Centralized Native Bridge Dispatcher for MethodChannel callbacks.
///
/// Prevents handler collisions where multiple services overwrite
/// `setMethodCallHandler` on `'com.privateagent/accessibility'`.
class NativeBridgeService {
  NativeBridgeService._();
  static final NativeBridgeService instance = NativeBridgeService._();

  static const MethodChannel _channel =
      MethodChannel('com.privateagent/accessibility');

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_dispatchCall);
    debugPrint('[NativeBridgeService] Initialized unified method call handler.');
  }

  Future<void> _dispatchCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onAirGesture':
          await AirGestureService.instance.handleNativeCall(call);
          break;

        case 'onPowerConnected':
        case 'onPowerDisconnected':
          await ChargingTelemetryService.instance.handleNativeCall(call);
          break;

        case 'onSentryMovementDetected':
          await SentryService.instance.handleNativeCall(call);
          break;

        case 'onWidgetOpenReactorHud':
          unawaited(ChargingTelemetryService.instance.queryTelemetry());
          ChargingTelemetryService.instance.showCinematicHud.value = true;
          break;

        case 'onWidgetSpeakTelemetry':
          final report = await ChargingTelemetryService.instance.getSpokenTelemetry();
          await VoiceService.instance.speak(report);
          break;

        case 'onWidgetVoiceCommand':
          await SettingsService.instance.setAppMode(AppMode.jarvis);
          JarvisService.instance.onEnterJarvisMode();
          await VoiceService.instance.speak('Poslouchám vás, pane.');
          await JarvisService.instance.startListening(manual: true);
          break;

        default:
          debugPrint('[NativeBridgeService] Unhandled native call: ${call.method}');
      }
    } catch (e, stack) {
      debugPrint('[NativeBridgeService] Error routing ${call.method}: $e\n$stack');
    }
  }
}

