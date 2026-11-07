import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'voice_service.dart';

/// ⚡ Arc Reactor Charging Telemetry Service
///
/// Monitors power cell coupling, real-time charging wattage, thermal stability,
/// voltage, and battery percentage. Automatically triggers holographic Arc Reactor
/// HUD visuals and vocal Stark telemetry upon charger connection.
class ChargingTelemetryService extends ChangeNotifier {
  ChargingTelemetryService._();

  static final ChargingTelemetryService instance = ChargingTelemetryService._();
  static const MethodChannel _channel = MethodChannel('com.privateagent/accessibility');

  bool _isCharging = false;
  int _batteryLevel = -1;
  int _voltageMv = 0;
  double _temperatureC = 0.0;
  int _currentMa = 0;
  double _wattage = 0.0;
  String _chargeType = 'Interní jádro';
  DateTime? _lastCoupledTime;
  bool _voiceAnnouncements = true;

  final ValueNotifier<bool> showCinematicHud = ValueNotifier<bool>(false);

  bool get isCharging => _isCharging;
  int get batteryLevel => _batteryLevel;
  int get voltageMv => _voltageMv;
  double get temperatureC => _temperatureC;
  int get currentMa => _currentMa;
  double get wattage => _wattage;
  String get chargeType => _chargeType;
  DateTime? get lastCoupledTime => _lastCoupledTime;
  bool get voiceAnnouncements => _voiceAnnouncements;

  set voiceAnnouncements(bool val) {
    _voiceAnnouncements = val;
    notifyListeners();
  }

  /// Handles native charging events dispatched by [NativeBridgeService].
  Future<void> handleNativeCall(MethodCall call) async {
    if (call.method == 'onPowerConnected') {
      final args = call.arguments;
      if (args is Map) {
        _applyTelemetryMap(args, connected: true, announce: true);
      }
    } else if (call.method == 'onPowerDisconnected') {
      final args = call.arguments;
      if (args is Map) {
        _applyTelemetryMap(args, connected: false, announce: true);
      }
    }
  }

  void _applyTelemetryMap(Map data, {required bool connected, bool announce = false}) {
    _isCharging = connected;
    _batteryLevel = (data['batteryLevel'] as num?)?.toInt() ?? _batteryLevel;
    _voltageMv = (data['voltageMv'] as num?)?.toInt() ?? 4100;
    _temperatureC = (data['temperatureC'] as num?)?.toDouble() ?? 30.0;
    _currentMa = (data['currentMa'] as num?)?.toInt() ?? 2500;
    _chargeType = (data['chargeType'] ?? (connected ? 'Síťové napájení AC' : 'Interní obloukové jádro')).toString();
    _wattage = (data['wattage'] as num?)?.toDouble() ?? (_voltageMv / 1000.0 * 2.5);

    if (connected) {
      _lastCoupledTime ??= DateTime.now();
      if (announce) {
        _lastCoupledTime = DateTime.now();
        showCinematicHud.value = true;
        if (_voiceAnnouncements) {
          final wattStr = _wattage > 0 ? '${_wattage.toStringAsFixed(1)} wattů' : 'nominální úrovni';
          final tempStr = _temperatureC > 0 ? ', teplota jádra je ${_temperatureC.toStringAsFixed(1)} °C' : '';
          unawaited(VoiceService.instance.speak(
            'Obloukový reaktor připojen, pane. Příjem energie aktivní na $wattStr. Energetické články jsou na $_batteryLevel procentech$tempStr.',
          ));
        }
      }
    } else {
      if (announce && _voiceAnnouncements) {
        unawaited(VoiceService.instance.speak(
          'Obloukový reaktor odpojen, pane. Systém běží na interní rezervy s $_batteryLevel procenty energie.',
        ));
      }
    }
    notifyListeners();
  }

  /// Pulls instantaneous telemetry snapshot from native hardware.
  Future<Map<String, dynamic>> queryTelemetry() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getChargingTelemetry');
      if (res != null) {
        _applyTelemetryMap(res, connected: res['isCharging'] == true, announce: false);
        return res;
      }
    } catch (_) {}

    return {
      'isCharging': _isCharging,
      'batteryLevel': _batteryLevel,
      'voltageMv': _voltageMv,
      'temperatureC': _temperatureC,
      'currentMa': _currentMa,
      'chargeType': _chargeType,
      'wattage': _wattage,
    };
  }

  /// Returns articulate spoken telemetry diagnostic.
  Future<String> getSpokenTelemetry() async {
    final t = await queryTelemetry();
    final lvl = t['batteryLevel'] ?? 85;
    final chg = t['isCharging'] == true;
    final watt = (t['wattage'] as num?)?.toDouble() ?? 18.0;
    final temp = (t['temperatureC'] as num?)?.toDouble() ?? 31.0;
    final type = t['chargeType'] ?? 'Turbínový zdroj';

    if (chg) {
      return 'Telemetrie obloukového reaktoru, pane: Připojeno ke zdroji $type. Tok energie je ${watt.toStringAsFixed(1)} wattů. Aktuální kapacita jádra činí $lvl % při stabilní teplotě ${temp.toStringAsFixed(1)} °C.';
    } else {
      return 'Jádro obloukového reaktoru pracuje na interní úložiště na $lvl %, pane. Teplota je stabilní na ${temp.toStringAsFixed(1)} °C. Není detekována žádná externí nabíjecí síť.';
    }
  }
}

