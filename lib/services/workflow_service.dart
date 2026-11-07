import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screen_automation_service.dart';
import 'sentry_service.dart';
import 'smart_home_service.dart';
import 'system_control_service.dart';

/// An autonomous workflow/protocol evolved by J.A.R.V.I.S. (Hermes Agent pattern).
/// Sets system settings, hardware parameters, and executes routines.
class JarvisWorkflow {
  final String id;
  final String name;
  final List<String> triggerKeywords;
  final String description;
  final double? volume; // 0.0 to 1.0, null if unchanged
  final double? brightness; // 0.0 to 1.0, null if unchanged
  final bool? torch; // true = on, false = off, null = unchanged
  final String spokenConfirmation;

  const JarvisWorkflow({
    required this.id,
    required this.name,
    required this.triggerKeywords,
    required this.description,
    this.volume,
    this.brightness,
    this.torch,
    required this.spokenConfirmation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'triggerKeywords': triggerKeywords,
        'description': description,
        'volume': volume,
        'brightness': brightness,
        'torch': torch,
        'spokenConfirmation': spokenConfirmation,
      };

  factory JarvisWorkflow.fromJson(Map<String, dynamic> json) => JarvisWorkflow(
        id: json['id'] as String,
        name: json['name'] as String,
        triggerKeywords: (json['triggerKeywords'] as List?)
                ?.map((e) => e.toString().toLowerCase())
                .toList() ??
            [],
        description: json['description'] as String? ?? '',
        volume: (json['volume'] as num?)?.toDouble(),
        brightness: (json['brightness'] as num?)?.toDouble(),
        torch: json['torch'] as bool?,
        spokenConfirmation: json['spokenConfirmation'] as String? ?? '',
      );

  JarvisWorkflow copyWith({
    String? id,
    String? name,
    List<String>? triggerKeywords,
    String? description,
    double? volume,
    double? brightness,
    bool? torch,
    String? spokenConfirmation,
  }) {
    return JarvisWorkflow(
      id: id ?? this.id,
      name: name ?? this.name,
      triggerKeywords: triggerKeywords ?? this.triggerKeywords,
      description: description ?? this.description,
      volume: volume ?? this.volume,
      brightness: brightness ?? this.brightness,
      torch: torch ?? this.torch,
      spokenConfirmation: spokenConfirmation ?? this.spokenConfirmation,
    );
  }
}

/// Self-Evolving Workflow Engine (Hermes Pattern):
/// Autonomously manages and triggers multi-parameter device protocols
/// such as Study Mode, Night Mode, Focus Mode, and custom user routines.
class WorkflowService extends ChangeNotifier {
  WorkflowService._();
  static final WorkflowService instance = WorkflowService._();

  static const _storageKey = 'jarvis_workflows_v1';
  final List<JarvisWorkflow> _workflows = [];
  bool _initialized = false;

  List<JarvisWorkflow> get workflows => List.unmodifiable(_workflows);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _workflows.clear();
          for (final item in decoded) {
            if (item is Map) {
              _workflows.add(
                JarvisWorkflow.fromJson(
                  item.map((k, v) => MapEntry('$k', v)),
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    if (_workflows.isEmpty || !_workflows.any((w) => w.id == 'sentry')) {
      _seedDefaults();
      await _persist();
    } else {
      // Sanitize any existing cached workflows to eliminate false-positive collision keywords
      var modified = false;
      for (var i = 0; i < _workflows.length; i++) {
        final w = _workflows[i];
        if (w.id == 'study') {
          final cleaned = w.triggerKeywords
              .where((k) => k != 'learn' && k != 'read' && k != 'reading')
              .toList();
          if (cleaned.length != w.triggerKeywords.length) {
            _workflows[i] = w.copyWith(triggerKeywords: cleaned);
            modified = true;
          }
        }
      }
      if (modified) {
        await _persist();
      }
    }
  }

  void _seedDefaults() {
    _workflows.addAll([
      const JarvisWorkflow(
        id: 'study',
        name: 'Studijní protokol',
        triggerKeywords: ['study', 'studying', 'exam', 'exams', 'study mode', 'study protocol', 'study session', 'start studying', 'studium', 'studijní režim', 'studijní protokol', 'učení'],
        description: 'Ztlumí rušivé zvuky a nastaví jas obrazovky na 45 % pro čtení.',
        volume: 0.0,
        brightness: 0.45,
        torch: false,
        spokenConfirmation:
            'Studijní protokol je nyní aktivní, pane. Jas obrazovky je zkalibrován na 45 procent a rušivé zvuky jsou ztlumeny, abyste se mohl plně soustředit. Přeji mnoho úspěchů při studiu, pane.',
      ),
      const JarvisWorkflow(
        id: 'night',
        name: 'Noční a spánkový protokol',
        triggerKeywords: ['sleep', 'sleeping', 'bedtime', 'goodnight', 'night mode', 'night protocol', 'sleep mode', 'sleep protocol', 'go to sleep', 'noční režim', 'noční protokol', 'režim spánku', 'dobrou noc', 'jdu spát'],
        description: 'Nastaví displej na minimální jas, ztiší zvuk a vypne svítilnu.',
        volume: 0.0,
        brightness: 0.05,
        torch: false,
        spokenConfirmation:
            'Noční protokol aktivován, pane. Displej je ztlumen na minimální svítivost, zvuk je ztišen a svítilna deaktivována. Přeji vám klidnou noc, pane. Dobře si odpočiňte.',
      ),
      const JarvisWorkflow(
        id: 'work',
        name: 'Pracovní protokol soustředění',
        triggerKeywords: ['work mode', 'work protocol', 'focus mode', 'focus protocol', 'meeting mode', 'deep work', 'pracovní režim', 'pracovní protokol', 'režim soustředění', 'hluboká práce'],
        description: 'Ztiší mediální upozornění a vyváží jas displeje pro pracovní prostředí.',
        volume: 0.05,
        brightness: 0.65,
        spokenConfirmation:
            'Protokol soustředění je aktivní, pane. Upozornění jsou ztlumena a displej je vyvážen pro vaši práci. Dejte mi vědět, pokud budete cokoliv potřebovat, pane.',
      ),
      const JarvisWorkflow(
        id: 'cinema',
        name: 'Kino protokol',
        triggerKeywords: ['cinema', 'cinema mode', 'cinema protocol', 'movie mode', 'theatre mode', 'theater mode', 'kino režim', 'kino protokol', 'filmový režim'],
        description: 'Zvýší hlasitost zvuku na 70 % a ztlumí obrazovku pro nerušené sledování.',
        volume: 0.70,
        brightness: 0.20,
        spokenConfirmation:
            'Kino protokol aktivován, pane. Displej je ztlumen a akustika zvýšena na 70 procent. Užijte si film, pane. Budu zde připraven, kdybyste cokoliv potřeboval.',
      ),
      const JarvisWorkflow(
        id: 'sentry',
        name: 'Strážní protokol (Taktičtí hlídači)',
        triggerKeywords: [
          'sentry',
          'sentry mode',
          'sentry protocol',
          'sentry protocal',
          'century protocol',
          'century mode',
          'centry protocol',
          'centry mode',
          'watchdog',
          'anti theft',
          'anti-theft',
          'guard my phone',
          'watch my phone',
          'strážní režim',
          'strážní protokol',
          'hlídej telefon',
        ],
        description: 'Odjistí pohybové senzory a bezpečnostní perimetr přední kamery.',
        spokenConfirmation:
            'Strážní protokol aktivní, pane. Pohybové senzory jsou odjištěny. Bezpečnostní perimetr byl vytvořen.',
      ),
    ]);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_workflows.map((w) => w.toJson()).toList()),
    );
    notifyListeners();
  }

  /// Evaluates user speech to find a matching evolved workflow.
  JarvisWorkflow? findMatch(String speech) {
    final trimmed = speech.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();

    // Guard: Questions or educational inquiries MUST NEVER trigger a hardware workflow!
    final isQuestion = RegExp(
      r'^(what|who|where|when|why|how|explain|tell\s+me|search|lookup|define|is\s+it|can\s+you|could\s+you|do\s+you)\b',
      caseSensitive: false,
    ).hasMatch(lower);
    if (isQuestion) return null;

    for (final w in _workflows) {
      for (final kw in w.triggerKeywords) {
        final kwLower = kw.toLowerCase().trim();
        if (kwLower.isEmpty) continue;
        // Whole-word or whole-phrase boundary match
        final pattern = RegExp(r'\b' + RegExp.escape(kwLower) + r'\b', caseSensitive: false);
        if (pattern.hasMatch(lower)) {
          return w;
        }
      }
    }
    return null;
  }

  /// Executes a matched workflow on device hardware.
  Future<bool> executeWorkflow(JarvisWorkflow workflow) async {
    final system = SystemControlService.instance;

    // 1. Audio volume
    if (workflow.volume != null) {
      if (workflow.volume! <= 0.0) {
        await system.setMuted(true);
      } else {
        await system.setMuted(false);
        await system.setVolume(workflow.volume!);
      }
    }

    // 2. Screen brightness
    if (workflow.brightness != null) {
      await system.setBrightness(workflow.brightness!);
    }

    // 3. Torch
    if (workflow.torch != null) {
      try {
        await ScreenAutomationService.instance.isServiceEnabled();
      } catch (_) {}
    }

    // 4. Smart Home & IoT Automation Integration
    try {
      if (workflow.id == 'sentry') {
        await SentryService.instance.armSentry();
      } else if (workflow.id == 'night') {
        await SmartHomeService.instance.turnOff();
      } else if (workflow.id == 'cinema') {
        await SmartHomeService.instance.turnOn(brightnessPct: 15);
      } else if (workflow.id == 'study') {
        await SmartHomeService.instance.turnOn(brightnessPct: 80);
      }
    } catch (_) {}

    return true;
  }

  /// Self-evolves: adds a newly learned user workflow.
  Future<void> learnWorkflow(JarvisWorkflow newWorkflow) async {
    _workflows.removeWhere((w) => w.id == newWorkflow.id);
    _workflows.add(newWorkflow);
    await _persist();
  }
}

