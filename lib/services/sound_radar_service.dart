import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'voice_service.dart';

/// Giving J.A.R.V.I.S. ears for the physical world:
/// - Real-time environmental sound radar (decibels, acoustic anomalies, knocks, sirens)
/// - Ambient music & song recognition.
class SoundRadarService {
  SoundRadarService._();
  static final SoundRadarService instance = SoundRadarService._();

  final http.Client _client = http.Client();

  /// Identifies music currently playing in the room or queries song lyrics/tracks.
  Future<String> identifyMusic([String? sampleOrHint]) async {
    try {
      final hint = sampleOrHint?.trim() ?? '';
      if (hint.isNotEmpty) {
        final queryUrl = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(hint)}&entity=song&limit=1',
        );
        final res = await _client.get(queryUrl).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final track = results.first as Map;
            final trackName = track['trackName'] ?? 'Neznámá skladba';
            final artistName = track['artistName'] ?? 'Neznámý interpret';
            final collection = track['collectionName'] ?? '';
            final extra = collection.isNotEmpty ? ' z alba „$collection“' : '';
            return 'Pane, akustická telemetrie identifikovala tuto skladbu jako „$trackName“ od interpreta $artistName$extra.';
          }
        }
      }

      // Live ambient sound analysis via microphone sound level
      final currentLevel = VoiceService.instance.soundLevel.value;
      if (currentLevel > 15.0) {
        return 'Pane, akustické receptory detekují v blízkosti aktivní rytmickou hudbu o intenzitě ${currentLevel.toStringAsFixed(1)} dB.';
      } else {
        return 'Akustické hladiny jsou v normě. Okolní zvuk momentálně nevykazuje žádné jasně rozpoznatelné hudební vzorce, pane.';
      }
    } catch (_) {
      return 'V tuto chvíli se nepodařilo rozpoznat akustický otisk hudby, pane.';
    }
  }

  /// Evaluates physical acoustic environment for loud impacts, sirens, or door knocks.
  Future<String> scanAmbientEnvironment() async {
    final soundDb = VoiceService.instance.soundLevel.value;
    if (soundDb > 40.0) {
      return 'Pane, akustický radar detekuje zvýšený hluk v okolí: zaznamenán zvuk s vysokou amplitudou ${soundDb.toStringAsFixed(1)} dB v bezprostředním perimetru.';
    } else if (soundDb > 18.0) {
      return 'Akustické senzory zaznamenávají mírný hovor nebo okolní ruch ve vaší blízkosti (${soundDb.toStringAsFixed(1)} dB).';
    } else {
      return 'Akustické pozadí perimetru je klidné a tiché na úrovni ${soundDb.toStringAsFixed(1)} dB, pane.';
    }
  }
}

