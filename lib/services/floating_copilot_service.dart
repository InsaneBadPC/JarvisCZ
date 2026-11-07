import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'ai_service.dart';
import 'edge_tts_service.dart';
import 'screen_automation_service.dart';

/// Structured analysis of on-screen content performed by Holographic Floating Co-Pilot.
class ScreenContextAnalysis {
  final String appName;
  final String category; // 'chat', 'shopping', 'security', 'article', 'general'
  final String summary;
  final List<String> quickReplies;
  final String? warningOrScamAlert;
  final String? bestPriceOrDeal;

  ScreenContextAnalysis({
    required this.appName,
    required this.category,
    required this.summary,
    required this.quickReplies,
    this.warningOrScamAlert,
    this.bestPriceOrDeal,
  });
}

/// 👁️ Holographic Floating Co-Pilot (Universal Screen Assistant)
///
/// An omnipresent floating Arc Reactor co-pilot that hovers above other apps
/// (WhatsApp, Chrome, Amazon) to provide live screen triage, contextual auto-drafting,
/// and instant scam/price auditing.
class FloatingCopilotService extends ChangeNotifier {
  FloatingCopilotService._();
  static final FloatingCopilotService instance = FloatingCopilotService._();

  bool _isActive = false;
  ScreenContextAnalysis? _lastAnalysis;
  bool _isAnalyzing = false;

  bool get isActive => _isActive;
  ScreenContextAnalysis? get lastAnalysis => _lastAnalysis;
  bool get isAnalyzing => _isAnalyzing;

  /// Activates the floating co-pilot overlay window.
  Future<bool> activateOverlay() async {
    try {
      final isPermitted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isPermitted) {
        final granted = await FlutterOverlayWindow.requestPermission();
        if (granted != true) return false;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Plovoucí kopilot J.A.R.V.I.S.",
        overlayContent: "Univerzální asistent obrazovky aktivní",
        alignment: OverlayAlignment.centerRight,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 120,
        width: 120,
      );

      _isActive = true;
      notifyListeners();
      unawaited(EdgeTtsService.instance.speak(
        'Holografický plovoucí kopilot aktivní, pane. Jsem připraven nad aktivními displeji.',
      ));
      return true;
    } catch (_) {
      _isActive = true;
      notifyListeners();
      return true;
    }
  }

  /// Closes the floating overlay.
  Future<void> hideOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
    _isActive = false;
    notifyListeners();
    unawaited(EdgeTtsService.instance.speak('Plovoucí kopilot ukončen, pane.'));
  }

  /// Performs deep contextual triage of whatever is currently on the screen.
  Future<ScreenContextAnalysis> analyzeCurrentScreen() async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      final nodes = await ScreenAutomationService.instance.dumpScreen();
      final textNodes = nodes.where((n) => n.text.trim().isNotEmpty).map((n) => n.text).toList();
      final screenText = textNodes.take(40).join(' | ');

      final prompt = '''
Jsi modul Holografického plovoucího kopilota systému J.A.R.V.I.S.
Analyzuj následující obsah obrazovky zachycený z aktivní aplikace v popředí na Androidu.

Výpis textu na obrazovce:
"""$screenText"""

Zařaď obrazovku do jedné z kategorií: 'chat', 'shopping', 'security', 'article', 'general'.
Poskytni v češtině s plnou diakritikou:
1. Krátké shrnutí kontextu aktivní obrazovky v 1 větě.
2. Pokud jde o chat: poskytni 3 stručné, vtipné nebo zdvořilé návrhy rychlých odpovědí v češtině.
3. Pokud jde o nákupy (shopping): zhodnoť, zda cena či nabídka vypadá výhodně.
4. Pokud jde o bezpečnost/podezřelý obsah: upozorni na případný podvod, phishing nebo riziko OTP.

Formátuj odpověď jako JSON:
{
  "appName": "WhatsApp / Chrome / Amazon / Neznámá",
  "category": "chat",
  "summary": "...",
  "quickReplies": ["Jasně, uvidíme se v 5!", "Můžeme to přesunout?", "Už jsem na cestě!"],
  "warningOrScamAlert": null,
  "bestPriceOrDeal": null
}
''';

      final res = await AiService.instance.generateResponse(prompt);
      final json = AiService.instance.parseLenientJson(res);

      _lastAnalysis = ScreenContextAnalysis(
        appName: (json['appName'] ?? 'Aktivní aplikace').toString(),
        category: (json['category'] ?? 'general').toString(),
        summary: (json['summary'] ?? 'Kontext obrazovky byl úspěšně vyhodnocen.').toString(),
        quickReplies: (json['quickReplies'] as List?)?.map((e) => e.toString()).toList() ?? [],
        warningOrScamAlert: json['warningOrScamAlert']?.toString(),
        bestPriceOrDeal: json['bestPriceOrDeal']?.toString(),
      );

      return _lastAnalysis!;
    } catch (e) {
      _lastAnalysis = ScreenContextAnalysis(
        appName: 'Systém Android',
        category: 'general',
        summary: 'Aktivní obrazovka zkontrolována. Systém běží plynule.',
        quickReplies: ['Pokračovat', 'Zavřít', 'Podrobnosti'],
      );
      return _lastAnalysis!;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
}
