import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../screens/security/code_black_screen.dart';
import 'voice_service.dart';

/// 🎭 "Code Black" — Deceptive Hardware Lockout & Anti-Prying Service
///
/// Simulates a catastrophic hardware failure / military kernel panic screen
/// to prevent snooping friends or unauthorized individuals from touching the phone.
/// Can be disarmed only via a secret voice override passphrase or hidden 4-tap corner sequence.
class CodeBlackService extends ChangeNotifier {
  CodeBlackService._();
  static final CodeBlackService instance = CodeBlackService._();

  bool _isArmed = false;
  int _breachAttemptCount = 0;
  DateTime? _activatedAt;

  static const List<String> disarmPassphrases = [
    'override alpha',
    'stand down jarvis',
    'stand down',
    'abuzar protocol',
    'jarvis override',
    'alpha protocol',
    'disarm',
    'cancel lockdown',
    'stop code black',
    'emergency override',
    'abuzar',
    'unlock',
    'odjistit',
    'deaktivovat',
    'odemknout',
    'zrušit uzamčení',
    'kód černá vypnout',
    'nouzové odblokování',
    'protokol alfa',
  ];

  bool get isArmed => _isArmed;
  int get breachAttemptCount => _breachAttemptCount;
  DateTime? get activatedAt => _activatedAt;

  /// Arms Code Black deceptive lockdown and displays the panic interface.
  Future<void> arm() async {
    if (_isArmed) return;
    _isArmed = true;
    _breachAttemptCount = 0;
    _activatedAt = DateTime.now();
    notifyListeners();
    HapticFeedback.heavyImpact();

    final navState = PrivateAgentApp.navigatorKey.currentState;
    if (navState != null) {
      unawaited(navState.push(
        MaterialPageRoute(builder: (_) => const CodeBlackScreen()),
      ));
    }

    unawaited(VoiceService.instance.speak(
      'Kód Černá zahájen. Hardwarová izolace aktivována. Pro deaktivaci vyslovte Protokol Alfa nebo klepněte na nouzové odblokování.',
    ));
  }

  /// Disarms Code Black.
  Future<void> disarm() async {
    if (!_isArmed) return;
    _isArmed = false;
    _breachAttemptCount = 0;
    notifyListeners();
    HapticFeedback.mediumImpact();

    unawaited(VoiceService.instance.speak(
      'Kód Černá deaktivován. Biometrie ověřena. Vítejte zpět, pane.',
    ));
  }

  /// Increments breach counter and emits alarming haptics when intruder touches screen.
  void recordIntruderTouch() {
    _breachAttemptCount++;
    notifyListeners();
    HapticFeedback.vibrate();
  }

  /// Checks if spoken phrase contains secret disarm passphrase.
  bool checkVoiceDisarm(String spokenText) {
    final lower = spokenText.toLowerCase();
    for (final pass in disarmPassphrases) {
      if (lower.contains(pass)) {
        disarm();
        return true;
      }
    }
    return false;
  }
}
