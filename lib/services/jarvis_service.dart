import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../models/task_history_entry.dart';
import '../widgets/airspace_radar_dialog.dart';
import '../widgets/brain_dump_dialog.dart';
import '../widgets/network_audit_dialog.dart';
import '../widgets/optical_solver_dialog.dart';
import '../widgets/polyglot_diplomat_dialog.dart';
import 'ai_service.dart';
import 'air_gesture_service.dart';
import 'airspace_radar_service.dart';
import 'app_launcher_service.dart';
import 'app_usage_service.dart';
import 'calendar_reminder_service.dart';
import 'charging_telemetry_service.dart';
import 'code_black_service.dart';
import 'commute_traffic_service.dart';
import 'conversational_memory_service.dart';
import 'email_triage_service.dart';
import 'finance_tracking_service.dart';
import 'floating_copilot_service.dart';
import 'form_filling_service.dart';
import 'hermes_evolution_service.dart';
import 'inbox_service.dart';
import 'jarvis_tools_service.dart';
import 'macro_recorder_service.dart';
import 'message_drafting_service.dart';
import 'multi_task_service.dart';
import 'network_audit_service.dart';
import 'notes_knowledge_service.dart';
import 'optical_solver_service.dart';
import 'personality_service.dart';
import 'phone_storage_service.dart';
import 'polyglot_diplomat_service.dart';
import 'proactive_agent_service.dart';
import 'routine_automation_service.dart';
import 'screen_automation_service.dart';
import 'security_alert_service.dart';
import 'sentry_service.dart';
import 'settings_service.dart';
import 'skill_memory_service.dart';
import 'smart_home_service.dart';
import 'sound_radar_service.dart';
import 'sports_service.dart';
import 'system_control_service.dart';
import 'system_diagnostics_service.dart';
import 'task_executor.dart';
import 'todo_service.dart';
import 'vision_perception_service.dart';
import 'voice_service.dart';
import 'workflow_service.dart';

/// Active operational phase of JARVIS.
enum JarvisPhase {
  idle, // Standby, listening for wake word or prompt
  listening, // Actively recording user speech
  thinking, // Processing intent / AI reasoning
  executing, // Device automation or workflow in progress
  speaking, // Vocalizing audio reply via TTS
}

/// Central controller for JARVIS Mode:
/// - Always-On hands-free voice assistant with Wake Words ("Hey Jarvis", "Hello Jarvis", "Jarvis")
/// - Ignores ambient room chatter in standby until wake word is recognized
/// - Active conversational continuation window for hands-free follow-up queries
/// - Hermes Self-Evolving Workflow Engine integration (Study, Night, Work, Cinema)
/// - Connects to [AiService.interpretJarvisCommand] for action vs chat vs system vs news
/// - Dispatches automation directly to [TaskExecutor]
/// - Emits high-frequency telemetry for the HUD animation painter
class JarvisService extends ChangeNotifier {
  JarvisService._() {
    _initListeners();
  }
  static final JarvisService instance = JarvisService._();

  final VoiceService _voice = VoiceService.instance;
  final AiService _ai = AiService.instance;
  final TaskExecutor _executor = TaskExecutor.instance;
  final SystemControlService _system = SystemControlService.instance;
  final ScreenAutomationService _automation = ScreenAutomationService.instance;

  JarvisPhase _phase = JarvisPhase.idle;
  JarvisPhase get phase => _phase;

  String _lastUserSpeech = '';
  String get lastUserSpeech => _lastUserSpeech;

  String _lastJarvisSpeech = 'K vašim službám, pane. Kdykoliv řekněte „Hej Jarvis“.';
  String get lastJarvisSpeech => _lastJarvisSpeech;

  String _statusMessage = 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“';
  String get statusMessage => _statusMessage;

  String? _currentTaskGoal;
  String? get currentTaskGoal => _currentTaskGoal;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  double _soundLevel = 0.0;
  double get soundLevel => _soundLevel;

  bool _initialized = false;
  bool _isInJarvisMode = false;
  bool get isInJarvisMode => _isInJarvisMode;
  bool _isAwake = false;
  bool get isAwake => _isAwake;

  VoidCallback? onWakeWordTriggered;

  Timer? _awakeTimer;
  Timer? _speechSilenceTimer;
  Timer? _proactiveConfirmationTimer;
  Timer? _followUpSilenceTimer;
  bool _isInFollowUp = false;
  bool get isInFollowUp => _isInFollowUp;
  ProactiveSuggestion? _pendingProactiveSuggestion;
  final List<Map<String, String>> _dialogHistory = [];

  bool get isAlwaysOn => SettingsService.instance.jarvisAlwaysOn;
  bool get _shouldListenContinuously => isAlwaysOn || _isInJarvisMode;
  ProactiveSuggestion? get pendingProactiveSuggestion => _pendingProactiveSuggestion;
  bool get isAwaitingProactiveConfirmation => _pendingProactiveSuggestion != null;

  @override
  void notifyListeners() {
    super.notifyListeners();
    _broadcastOverlayState();
  }

  void _broadcastOverlayState() {
    try {
      FlutterOverlayWindow.shareData(jsonEncode({
        'type': 'jarvis_state',
        'phase': _phase.name,
        'status': _statusMessage,
        'lastSpeech': _lastJarvisSpeech,
      }));
    } catch (_) {}
  }

  void _initListeners() {
    if (_initialized) return;
    _initialized = true;

    // Ensure workflows and intelligence modules are initialized
    WorkflowService.instance.init();
    ConversationalMemoryService.instance.init();
    PersonalityService.instance.init();
    CalendarReminderService.instance.init();
    TodoService.instance.init();
    NotesKnowledgeService.instance.init();
    MacroRecorderService.instance.init();
    unawaited(ProactiveAgentService.instance.evaluateProactiveNeeds());
    ProactiveAgentService.instance.startProactiveMonitor();

    _voice.soundLevel.addListener(() {
      _soundLevel = _voice.soundLevel.value;
      notifyListeners();
    });

    _voice.onSpeechStatus = (status) {
      if (status == 'endOfSpeech') {
        if (_isAwake && _lastUserSpeech.isNotEmpty) {
          _speechSilenceTimer?.cancel();
          _speechSilenceTimer = Timer(const Duration(milliseconds: 350), () {
            final trimmed = _lastUserSpeech.trim();
            if (trimmed.isNotEmpty) {
              unawaited(_handleSpeechResult(trimmed));
            }
          });
        }
      }
    };

    _voice.isSpeaking.addListener(() {
      if (_voice.isSpeaking.value) {
        _speechSilenceTimer?.cancel();
        if (_phase != JarvisPhase.executing) {
          _phase = JarvisPhase.speaking;
          notifyListeners();
        }
      } else {
        if (_phase == JarvisPhase.speaking) {
          _phase = _executor.isBusy ? JarvisPhase.executing : JarvisPhase.idle;
          notifyListeners();
        }
        // Continuous listening trigger: when speech output finishes, resume passive wake-word listening
        if (_shouldListenContinuously) {
          if (_isAwake) {
            _keepAwake();
          }
          startListening();
        }
      }
    });

    _voice.listeningNotifier.addListener(() {
      if (!_voice.listeningNotifier.value) {
        if (_phase == JarvisPhase.listening) {
          _phase = _executor.isBusy ? JarvisPhase.executing : JarvisPhase.idle;
          notifyListeners();
        }
      }
    });

    _executor.addListener(() {
      if (_phase == JarvisPhase.executing) {
        _currentStep = _executor.step;
        if (!_executor.isBusy) {
          _currentStep = 0;
          _currentTaskGoal = null;
          _phase =
              _voice.isSpeaking.value ? JarvisPhase.speaking : JarvisPhase.idle;
          notifyListeners();
          if (_shouldListenContinuously) {
            startListening();
          }
        }
      } else {
        notifyListeners();
      }
    });

    if (isAlwaysOn) {
      ensureAlwaysOnRunning();
    }
  }

  void _wakeUp() {
    _isAwake = true;
    _keepAwake();
  }

  void _keepAwake() {
    _awakeTimer?.cancel();
    final windowSec = SettingsService.instance.geminiLiveVoiceMode ? 35 : 15;
    _awakeTimer = Timer(Duration(seconds: windowSec), () {
      if (_phase != JarvisPhase.executing && _phase != JarvisPhase.speaking && _phase != JarvisPhase.thinking) {
        _isAwake = false;
        _statusMessage = _shouldListenContinuously
            ? 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“'
            : 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
        notifyListeners();
      }
    });
  }

  void _standDown() {
    _speechSilenceTimer?.cancel();
    _proactiveConfirmationTimer?.cancel();
    _followUpSilenceTimer?.cancel();
    _isInFollowUp = false;
    _pendingProactiveSuggestion = null;
    _isAwake = false;
    _awakeTimer?.cancel();
    _lastUserSpeech = '';
    _statusMessage = _shouldListenContinuously
        ? 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“'
        : 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
    _phase = JarvisPhase.idle;
    notifyListeners();
  }

  /// Engages immediate hands-free follow-up continuous listening after speaking.
  /// In Gemini Live Voice Mode, keeps a 30-second conversational session open
  /// so the user can talk naturally back-and-forth without repeating any wake word.
  Future<void> _startFollowUpListening() async {
    _followUpSilenceTimer?.cancel();
    _speechSilenceTimer?.cancel();

    _wakeUp();
    _isInFollowUp = true;
    _phase = JarvisPhase.listening;
    final isLive = SettingsService.instance.geminiLiveVoiceMode;
    _statusMessage = isLive
        ? 'ŽIVÝ ROZHOVOR (GEMINI LIVE) // MLUVTE VOLNĚ'
        : 'NASLOUCHÁM // POLOŽTE DOPLŇUJÍCÍ DOTAZ NEBO PŘÍKAZ';
    notifyListeners();

    await startListening(manual: true);

    // 30-second live conversational window in Gemini Live mode (or 10s standard)
    final followUpMs = isLive ? 30000 : 10000;
    _followUpSilenceTimer = Timer(Duration(milliseconds: followUpMs), () {
      _onFollowUpTimeout();
    });
  }

  void _onFollowUpTimeout() {
    _followUpSilenceTimer?.cancel();
    _isInFollowUp = false;
    _standDown();
    if (!_shouldListenContinuously) {
      stopListening();
    }
  }

  /// Ensures the Google Assistant style continuous listener is running.
  void ensureAlwaysOnRunning() {
    if (!SettingsService.instance.jarvisAlwaysOn) return;
    startListening();
  }

  /// Stops Always-On supervision.
  void stopAlwaysOn() {
    _standDown();
    stopListening();
  }

  /// Extracts the wake word command from speech with robust normalization.
  /// Supports J.A.R.V.I.S., phonetic variants, and Google Assistant wake phrases.
  /// Handles punctuation (commas like "Hey, Jarvis"), accents, and alternate STT hypotheses.
  /// Returns:
  /// - '' (empty string) if only wake word / greeting was spoken (to wake up and start listening)
  /// - the extracted user command if wake word + command was spoken
  /// - null if no wake word was spoken
  static String? extractWakeCommand(String speech) {
    final raw = speech.trim();
    if (raw.isEmpty) return null;

    // 1. Normalize acronyms, punctuation, and multiple spaces
    var normalized = raw
        .replaceAll(
          RegExp(r'j\s*\.?\s*a\s*\.?\s*r\s*\.?\s*v\s*\.?\s*i\s*\.?\s*s\.?', caseSensitive: false),
          'jarvis',
        )
        .replaceAll(RegExp(r'[,;:!?]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return null;

    // 2. Comprehensive Wake Phrase Pattern
    // Matches:
    // - (hey | hej | ahoj | čau | haló | hello | hi | ok | okay | yo | listen | wake up | dear) + [optional space] + (jarvis | jarvisi | javis | jervis | jarves | jarvice | travis | service | davis | davies | harvest | jarvi | google)
    // - standalone (jarvis | jarvisi | javis | jervis | jarves | jarvice | charvis | garvis | jarvi)
    // - (wake up jarvis | jarvis wake up | jarvis please)
    final wakePattern = RegExp(
      r'\b(?:(?:hey|hej|ahoj|čau|haló|halo|hello|hi|okay|ok|yo|listen|poslouchej|probud\s+se|probuď\s+se|wake\s+up|dear)\s+(?:jarvis|jarvisi|javis|jervis|jarves|jarvice|charvis|garvis|gervis|travis|service|davis|davies|harvest|jarvi|google)|(?:jarvis|jarvisi|javis|jervis|jarves|jarvice|charvis|garvis|jarvi)\s+(?:wake\s+up|please|prosím|online)|(?:jarvis|jarvisi|javis|jervis|jarves|jarvice|charvis|garvis|jarvi)|(?:hey|hej|okay|ok|hello|ahoj|hi)\s+google)\b',
      caseSensitive: false,
    );

    final match = wakePattern.firstMatch(normalized);
    if (match == null) return null;

    // Command after wake word: e.g. "Hey Jarvis, what time is it" -> "what time is it"
    final after = normalized
        .substring(match.end)
        .replaceAll(RegExp(r'^[,\s!?\-:;]+'), '')
        .trim();

    // Command before wake word: e.g. "What time is it, Jarvis" -> "What time is it"
    final before = normalized
        .substring(0, match.start)
        .replaceAll(RegExp(r'[,\s!?\-:;]+$'), '')
        .trim();

    if (after.isNotEmpty) {
      final cleanAfter = after.replaceFirst(
        RegExp(r'^(?:wake\s+up|please|prosím|online)\s*', caseSensitive: false),
        '',
      ).trim();
      return cleanAfter.isNotEmpty ? cleanAfter : '';
    }

    if (before.isNotEmpty) {
      final lowerBefore = before.toLowerCase();
      // If "before" was just a greeting prefix (e.g. "Hey" from "Hey, Jarvis"), return empty string so it wakes up
      if (lowerBefore == 'hey' ||
          lowerBefore == 'hej' ||
          lowerBefore == 'ahoj' ||
          lowerBefore == 'čau' ||
          lowerBefore == 'haló' ||
          lowerBefore == 'halo' ||
          lowerBefore == 'hello' ||
          lowerBefore == 'hi' ||
          lowerBefore == 'ok' ||
          lowerBefore == 'okay' ||
          lowerBefore == 'yo' ||
          lowerBefore == 'wake up') {
        return '';
      }
      return before;
    }

    // Only wake word was spoken: e.g. "Hey Jarvis" or "Jarvis"
    return '';
  }

  String? _extractWakeCommand(String speech) => extractWakeCommand(speech);

  /// Displays a modal dialog safely using the global navigation key.
  void _showModalSafely(Widget dialog) {
    try {
      final nav = PrivateAgentApp.navigatorKey.currentState;
      if (nav != null && nav.context.mounted) {
        showDialog(
          context: nav.context,
          barrierColor: const Color(0xB3000000),
          builder: (_) => dialog,
        );
      }
    } catch (e) {
      debugPrint('[JarvisService] Modal launch error: $e');
    }
  }

  /// Called when user navigates into JARVIS mode.
  void onEnterJarvisMode() {
    _isInJarvisMode = true;
    _wakeUp();
    startListening(manual: true);
    // Arm mid-air proximity sensor for zero-touch gestures while in JARVIS mode
    unawaited(AirGestureService.instance.start());
    _statusMessage = 'NASLOUCHÁM // AUDIO RECEPTORY AKTIVNÍ';
    notifyListeners();
  }

  /// Called when user leaves JARVIS mode to prevent background audio captures.
  void onExitJarvisMode() {
    _isInJarvisMode = false;
    unawaited(AirGestureService.instance.stop());
    // Always-On mode listens continuously across the app like Google Assistant
    if (!isAlwaysOn) {
      _standDown();
      if (_phase == JarvisPhase.listening) {
        stopListening();
      }
    }
  }

  /// Toggles Always-On Hands-Free continuous listening mode.
  Future<void> toggleAlwaysOn() async {
    final current = SettingsService.instance.jarvisAlwaysOn;
    final next = !current;
    await SettingsService.instance.setJarvisAlwaysOn(next);
    notifyListeners();

    if (next) {
      _wakeUp();
      ensureAlwaysOnRunning();
      const msg =
          'Nepřetržité naslouchání je aktivní, pane. Kdykoliv řekněte „Hej Jarvis“.';
      _lastJarvisSpeech = msg;
      _statusMessage = 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“';
      notifyListeners();
      await _voice.speak(msg);
    } else {
      stopAlwaysOn();
      const msg = 'Nepřetržité naslouchání bylo přepnuto do pohotovosti, pane.';
      _lastJarvisSpeech = msg;
      _statusMessage = 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
      notifyListeners();
      await _voice.speak(msg);
    }
  }

  /// Session guard to ensure rich executive greeting is spoken once per session upon launch
  bool _hasGreetedThisSession = false;

  /// Initial vocal greeting when user enters JARVIS mode.
  /// Dynamically synthesizes date, time, calendar meetings (e.g. Jack), and pending to-dos.
  Future<void> speakGreeting({bool force = false}) async {
    if (!force && _hasGreetedThisSession) return;
    _hasGreetedThisSession = true;

    onEnterJarvisMode();
    _wakeUp();
    _phase = JarvisPhase.thinking;
    _statusMessage = 'SYNTÉZA EXEKUTIVNÍHO BRÍFINKU';
    notifyListeners();

    final greeting = await PersonalityService.instance.generateExecutiveGreeting();
    _lastJarvisSpeech = greeting;
    _phase = JarvisPhase.speaking;
    _statusMessage = 'EXEKUTIVNÍ BRÍFINK // PŘIPRAVEN';
    notifyListeners();
    await _voice.speak(greeting);
    _standDown();
  }

  /// Autonomously speaks a proactive question and opens a hands-free confirmation listening window.
  Future<void> proactivelySpeakAndAwaitConfirmation(ProactiveSuggestion suggestion) async {
    // If Jarvis is currently busy in execution, do not interrupt
    if (_phase == JarvisPhase.executing) return;

    _proactiveConfirmationTimer?.cancel();
    _pendingProactiveSuggestion = suggestion;
    _lastJarvisSpeech = suggestion.spokenPrompt;
    _statusMessage = 'PROAKTIVNÍ UPOZORNĚNÍ // ${suggestion.title.toUpperCase()}';
    _phase = JarvisPhase.speaking;
    notifyListeners();

    await _voice.speak(suggestion.spokenPrompt);

    if (SettingsService.instance.proactiveVoiceConfirmationEnabled) {
      _wakeUp();
      _phase = JarvisPhase.listening;
      _statusMessage = 'ČEKÁM NA ODPOVĚĎ // ŘEKNĚTE „ANO“ NEBO „NE“';
      notifyListeners();

      await startListening(manual: true);

      // 8-second confirmation window before gracefully standing down
      _proactiveConfirmationTimer?.cancel();
      _proactiveConfirmationTimer = Timer(const Duration(seconds: 8), () {
        if (_pendingProactiveSuggestion != null) {
          debugPrint('[JarvisService] Proactive confirmation timed out with no response');
          _pendingProactiveSuggestion = null;
          _standDown();
        }
      });
    } else {
      _pendingProactiveSuggestion = null;
      if (_shouldListenContinuously) {
        _standDown();
      } else {
        _phase = JarvisPhase.idle;
        _statusMessage = 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
        notifyListeners();
      }
    }
  }

  /// Cancels any active proactive confirmation window and returns to standby.
  void dismissProactiveConfirmation() {
    _proactiveConfirmationTimer?.cancel();
    _pendingProactiveSuggestion = null;
    if (_phase == JarvisPhase.listening) {
      _standDown();
    }
  }

  /// Checks if spoken response is an affirmative confirmation.
  static bool isAffirmativeResponse(String input) {
    final lower = input.trim().toLowerCase();
    final patterns = [
      r'\b(yes|yeah|yep|yup|sure|please|do\s+it|turn\s+it\s+on|turn\s+on|engage|activate|ok|okay|go\s+ahead|proceed|definitely|affirmative|sounds\s+good|why\s+not|let\x27s\s+do\s+it|ano|jo|jistě|samozřejmě|prosím|udělej\s+to|proveď|zapni|aktivuj|dobře|souhlasím|klidně|určitě)\b',
    ];
    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) return true;
    }
    return false;
  }

  /// Checks if spoken response is a negative dismissal.
  static bool isNegativeResponse(String input) {
    final lower = input.trim().toLowerCase();
    final patterns = [
      r'\b(no|nope|nah|not\s+now|never\s+mind|nevermind|don\x27t|cancel|later|dismiss|leave\s+it|negative|stop|skip|ne|nikoliv|teď\s+ne|raději\s+ne|nevadí|zruš|zrušit|později|nech\s+to|zastav|přeskoč)\b',
    ];
    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) return true;
    }
    return false;
  }

  /// Toggles speech recognition manually via the UI.
  /// Supports Gemini-Live style barge-in: tapping while Jarvis is speaking
  /// immediately interrupts speech and opens the microphone for the user's next turn.
  Future<void> toggleListening() async {
    if (_phase == JarvisPhase.speaking) {
      await _voice.stopSpeaking();
      _wakeUp();
      await startListening(manual: true);
      _statusMessage = 'PŘERUŠENO // NASLOUCHÁM VAŠÍ ODPOVĚDI';
      notifyListeners();
      return;
    }
    if (_phase == JarvisPhase.listening) {
      await stopListening();
      if (_shouldListenContinuously) {
        _standDown();
        await startListening();
      }
    } else {
      _wakeUp();
      await startListening(manual: true);
    }
  }

  /// Begins recording voice input.
  Future<bool> startListening({bool manual = false}) async {
    await _voice.stopSpeaking();

    if (manual) {
      _wakeUp();
    }

    // Google Home / Google Assistant Architecture:
    // Only set phase to listening if awake or manual tap.
    // In passive standby background waiting for wake-word, stay in idle so UI is calm and does NOT flicker!
    if (_isAwake || !_shouldListenContinuously) {
      _phase = JarvisPhase.listening;
      _statusMessage = 'NASLOUCHÁM // AUDIO RECEPTORY AKTIVNÍ';
    } else {
      _phase = JarvisPhase.idle;
      _statusMessage = 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“';
    }
    notifyListeners();

    final started = await _voice.startListening(
      continuous: _shouldListenContinuously,
      manual: manual,
      onResult: (words, isFinal, candidates) {
        _lastUserSpeech = words;
        debugPrint('[JarvisService] Heard: "$words" (candidates: $candidates, isFinal: $isFinal, isAwake: $_isAwake)');

        // Immediate wake detection on partial speech stream
        if (_shouldListenContinuously && !_isAwake) {
          String? wakeCmd = _extractWakeCommand(words);
          if (wakeCmd == null) {
            for (final cand in candidates) {
              final cCmd = _extractWakeCommand(cand);
              if (cCmd != null) {
                wakeCmd = cCmd;
                break;
              }
            }
          }
          if (wakeCmd != null) {
            _wakeUp();
            onWakeWordTriggered?.call();
            HapticFeedback.mediumImpact();

            // Set visual listening state immediately, but NEVER cut off the user!
            // Let the user finish speaking their full command until silence / isFinal.
            _phase = JarvisPhase.listening;
            _statusMessage = 'NASLOUCHÁM // AUDIO RECEPTORY AKTIVNÍ';
            notifyListeners();
          }
        } else if (_isAwake) {
          notifyListeners();
        }

        // Voice Activity / Silence Debounce Timer:
        // When awake or wake-word is present, whenever user stops speaking (silence for ~1450ms),
        // automatically trigger command processing so the user never gets stuck waiting on Android's silence detector!
        final hasWake = _extractWakeCommand(words) != null ||
            candidates.any((c) => _extractWakeCommand(c) != null);
        if (_isAwake || _isInJarvisMode || hasWake) {
          _speechSilenceTimer?.cancel();
          _speechSilenceTimer = Timer(const Duration(milliseconds: 1450), () {
            final trimmed = _lastUserSpeech.trim();
            if (trimmed.isNotEmpty) {
              debugPrint('[JarvisService] Silence debounce timer fired for: "$trimmed"');
              unawaited(_handleSpeechResult(trimmed, candidates));
            }
          });
        }

        if (isFinal) {
          _speechSilenceTimer?.cancel();
          final trimmed = words.trim();
          if (trimmed.isNotEmpty) {
            unawaited(_handleSpeechResult(trimmed, candidates));
          } else {
            _phase = _executor.isBusy ? JarvisPhase.executing : JarvisPhase.idle;
            _statusMessage = _shouldListenContinuously
                ? (_isAwake
                    ? 'NASLOUCHÁM // AUDIO RECEPTORY AKTIVNÍ'
                    : 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“')
                : 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
            notifyListeners();
          }
        }
      },
    );

    if (!started) {
      _phase = _executor.isBusy ? JarvisPhase.executing : JarvisPhase.idle;
      _statusMessage = 'MIKROFON NEDOSTUPNÝ';
      notifyListeners();
    }
    return started;
  }

  /// Handles incoming speech results, applying wake-word filtering in continuous mode.
  Future<void> _handleSpeechResult(String speech, [List<String>? candidates]) async {
    _speechSilenceTimer?.cancel();

    // Guard against duplicate execution while already busy
    if (_phase == JarvisPhase.thinking ||
        _phase == JarvisPhase.executing ||
        _phase == JarvisPhase.speaking) {
      return;
    }

    final trimmed = speech.trim();
    if (trimmed.isEmpty) return;

    _followUpSilenceTimer?.cancel();
    _isInFollowUp = false;

    _lastUserSpeech = '';
    debugPrint('[JarvisService] _handleSpeechResult: "$trimmed" (candidates: $candidates, isAwake: $_isAwake)');

    // Proactive conversational confirmation check:
    // If Jarvis just asked a proactive question (e.g. "It's night time, sir. Should I turn on the night mode?"),
    // interpret the user's natural answer ("yes", "sure", "no", "later") immediately without requiring a wake word.
    if (_pendingProactiveSuggestion != null) {
      final suggestion = _pendingProactiveSuggestion!;
      _pendingProactiveSuggestion = null;
      _proactiveConfirmationTimer?.cancel();

      final answer = trimmed.toLowerCase();
      final isAffirmative = isAffirmativeResponse(answer);
      final isNegative = isNegativeResponse(answer);

      debugPrint('[JarvisService] Proactive response: "$answer" (yes: $isAffirmative, no: $isNegative)');

      if (isAffirmative) {
        _wakeUp();
        _phase = JarvisPhase.thinking;
        _statusMessage = 'POTVRZENO // ZAPÍNÁM ${suggestion.title.toUpperCase()}';
        notifyListeners();

        const ack = 'Ihned, pane. Provádím příkaz.';
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(ack);

        await processCommand(suggestion.actionGoal);
        return;
      } else if (isNegative) {
        _phase = JarvisPhase.speaking;
        _statusMessage = 'ZAMÍTNUTO // POHOTOVOSTNÍ REŽIM';
        const ack = 'Rozumím, pane. Zůstávám v pohotovosti.';
        _lastJarvisSpeech = ack;
        notifyListeners();
        await _voice.speak(ack);
        _standDown();
        return;
      }
    }

    // 1. If continuous listening is NOT active (user explicitly pressed talk button in Agent/Chat mode):
    if (!_shouldListenContinuously) {
      _wakeUp();
      await processCommand(trimmed);
      return;
    }

    // 2. Continuous listening is active (Jarvis HUD or Always-On): Check for wake word across speech and candidates
    var wakeCommand = _extractWakeCommand(trimmed);
    if (wakeCommand == null && candidates != null) {
      for (final cand in candidates) {
        final cCmd = _extractWakeCommand(cand);
        if (cCmd != null) {
          wakeCommand = cCmd;
          break;
        }
      }
    }

    if (wakeCommand != null) {
      _wakeUp();
      onWakeWordTriggered?.call();
      HapticFeedback.mediumImpact();

      if (wakeCommand.isEmpty) {
        // User said ONLY "Hey Jarvis" or "Jarvis" -> Stay in LISTENING state waiting for command
        _wakeUp();
        _phase = JarvisPhase.listening;
        _statusMessage = 'NASLOUCHÁM // AUDIO RECEPTORY AKTIVNÍ';
        notifyListeners();
        return;
      } else {
        // User said "Hey Jarvis [command]" e.g. "Hey Jarvis, what are today to new headlines"
        await processCommand(wakeCommand);
        return;
      }
    }

    // 3. User is already awake or inside JARVIS HUD screen:
    // Execute direct follow-up commands!
    if (_isAwake || _isInJarvisMode) {
      _wakeUp();
      await processCommand(trimmed);
      return;
    }

    // 4. In background standby mode, user spoke WITHOUT wake word:
    // (e.g. talking to a friend on the desk):
    // COMPLETELY IGNORE ambient chatter to never interrupt room conversation!
    debugPrint('[JarvisService] Ambient conversation ignored: "$trimmed"');
    _standDown();
  }

  /// Stops voice input.
  Future<void> stopListening() async {
    _followUpSilenceTimer?.cancel();
    _isInFollowUp = false;
    _speechSilenceTimer?.cancel();
    await _voice.stopListening();
    if (_phase == JarvisPhase.listening) {
      _phase = _executor.isBusy ? JarvisPhase.executing : JarvisPhase.idle;
      _statusMessage = _shouldListenContinuously
          ? 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“'
          : 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
      notifyListeners();
    }
  }

  /// Aborts any running task immediately.
  Future<void> abortTask() async {
    _standDown();
    if (_executor.isBusy) {
      _executor.cancel();
      _phase = JarvisPhase.speaking;
      _statusMessage = 'PROTOKOL PŘERUŠEN // POHOTOVOST';
      const speech = 'Okamžitě přerušuji úkol, pane.';
      _lastJarvisSpeech = speech;
      notifyListeners();
      await _voice.speak(speech);
    } else {
      await _voice.stopSpeaking();
      _phase = JarvisPhase.idle;
      _statusMessage = _shouldListenContinuously
          ? 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“'
          : 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
      notifyListeners();
    }
  }

  /// Processes a voice command through JARVIS intelligence.
  Future<void> processCommand(String command) async {
    _wakeUp();
    _speechSilenceTimer?.cancel();
    await _voice.stopListening();

    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    _lastUserSpeech = trimmed;
    _phase = JarvisPhase.thinking;
    _statusMessage = 'VÝPOČET // ANALÝZA PŘÍKAZU';
    notifyListeners();

    try {
      await _processCommandInternal(trimmed);
    } catch (e) {
      debugPrint('[JarvisService] processCommand error: $e');
      const errSpeech = 'Omlouvám se, pane, při zpracování požadavku došlo k chybě spojení. Zkuste to prosím znovu.';
      _lastJarvisSpeech = errSpeech;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'SYSTÉMOVÁ OBNOVA // PŘIPRAVEN';
      notifyListeners();
      await _voice.speak(errSpeech);
      await _startFollowUpListening();
    }
  }

  Future<void> _processCommandInternal(String trimmed) async {
    final lower = trimmed.toLowerCase();

    // 1. Fast cancel / abort check
    if (lower == 'stop' ||
        lower == 'cancel' ||
        lower == 'abort' ||
        lower == 'zastav' ||
        lower == 'zruš' ||
        lower == 'zrušit' ||
        lower.contains('stop task') ||
        lower.contains('cancel task') ||
        lower.contains('zastav úkol') ||
        lower.contains('zruš úkol')) {
      await abortTask();
      return;
    }

    // 2. Stand down / Sleep commands
    if (lower == 'stand down' ||
        lower == 'go to sleep' ||
        lower == 'sleep' ||
        lower == 'goodnight' ||
        lower == 'thank you' ||
        lower == 'thanks' ||
        lower == 'no thanks' ||
        lower == 'no thank you' ||
        lower == 'that will be all' ||
        lower == "that's all" ||
        lower == 'that is all' ||
        lower == "i'm good" ||
        lower == 'im good' ||
        lower == 'pohov' ||
        lower == 'děkuji' ||
        lower == 'díky' ||
        lower == 'to je vše' ||
        lower == 'to bude vše' ||
        lower == 'dobrou noc') {
      _standDown();
      await _voice.stopListening();
      final reply = PersonalityService.instance.getStandDown();
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = _shouldListenContinuously
          ? 'POHOTOVOST // ŘEKNĚTE „HEJ JARVIS“'
          : 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
      notifyListeners();
      await _voice.speak(reply);
      return;
    }

    // 2b. Autonomous Form Filling (USER.md + Long-Term Memory)
    if (lower.contains('fill this form') ||
        lower.contains('fill the form') ||
        lower.contains('fill form') ||
        lower.contains('fill out this form') ||
        lower.contains('autofill this form') ||
        lower.contains('autofill form') ||
        lower.contains('fill my details') ||
        lower.contains('fill my info') ||
        lower.contains('fill my information') ||
        lower.contains('vyplň formulář') ||
        lower.contains('vyplnit formulář') ||
        lower.contains('vyplň tento formulář') ||
        lower.contains('vyplň moje údaje')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = ' AUTOMATICKÉ VYPLNĚNÍ FORMULÁŘE // PRŮZKUM POLÍ';
      notifyListeners();

      final result = await FormFillingService.instance.fillActiveForm();
      _lastJarvisSpeech = result;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'VYPLNĚNÍ FORMULÁŘE DOKONČENO';
      notifyListeners();
      await _voice.speak(result);
      await _startFollowUpListening();
      return;
    }

    // 3. Hands-Free Always-On toggle commands
    if (lower == 'always on' ||
        lower == 'activate always on' ||
        lower == 'hands free' ||
        lower == 'continuous listening' ||
        lower == 'turn on always on' ||
        lower == 'enable always on' ||
        lower == 'stálý poslech' ||
        lower == 'zapni stálý poslech') {
      await SettingsService.instance.setJarvisAlwaysOn(true);
      ensureAlwaysOnRunning();
      const reply = 'Nepřetržité naslouchání je zapnuto, pane.';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'NEPŘETRŽITÉ RECEPTORY AKTIVNÍ';
      notifyListeners();
      await _voice.speak(reply);
      return;
    }

    if (lower == 'turn off always on' ||
        lower == 'disable always on' ||
        lower == 'deactivate always on' ||
        lower == 'stop always on' ||
        lower == 'vypni stálý poslech') {
      await SettingsService.instance.setJarvisAlwaysOn(false);
      stopAlwaysOn();
      const reply = 'Nepřetržité naslouchání bylo deaktivováno, pane.';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'PŘIPRAVEN // KLEPNĚTE PRO HOVOR';
      notifyListeners();
      await _voice.speak(reply);
      return;
    }

    // 3b. Hermes Self-Evolution triggers
    if (lower == 'self evolve' ||
        lower == 'evolve context' ||
        lower == 'run self evolution' ||
        lower == 'hermes evolution' ||
        lower == 'evolve yourself' ||
        lower == 'update your protocols' ||
        lower == 'evolve memory' ||
        lower == 'samovývoj' ||
        lower.contains('aktualizuj protokoly')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'SYNTÉZA KONTEXTU HERMES';
      notifyListeners();
      await HermesEvolutionService.instance.evolveContext();
      final factsCount = ConversationalMemoryService.instance.facts.length;
      final workflowCount = WorkflowService.instance.workflows.length;
      final reply =
          'Cyklus samovývoje Hermes byl dokončen, pane. Syntetizoval jsem $factsCount faktů z uživatelské paměti a $workflowCount aktivních protokolů napříč SOUL.md, USER.md a AGENT.md.';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'SAMOVÝVOJ DOKONČEN';
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // 3c. Interactive Multi-Task Decoupler Dialog
    if (lower == 'open brain dump' ||
        lower == 'show brain dump' ||
        lower == 'open multitask' ||
        lower == 'show multitask' ||
        lower == 'multitask dialog' ||
        lower == 'decoupler dialog' ||
        lower.contains('otevři rozkladač')) {
      _showModalSafely(const BrainDumpDialog());
      const reply = 'Rozhraní víceúlohového rozkladače bylo otevřeno, pane. Jsem připraven na vaše složené pokyny.';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'VÍCEÚLOHOVÝ ROZKLADAČ AKTIVNÍ';
      notifyListeners();
      await _voice.speak(reply);
      return;
    }

    // 3d. Autonomous Macro Recorder fast triggers
    if (lower.startsWith('stop recording') ||
        lower.startsWith('save macro') ||
        lower.startsWith('finish recording') ||
        lower.startsWith('zastav nahrávání') ||
        lower.startsWith('ulož makro')) {
      if (MacroRecorderService.instance.isRecording) {
        _phase = JarvisPhase.thinking;
        _statusMessage = 'KODIFIKACE AUTONOMNÍHO MAKRA // AGENT.MD';
        notifyListeners();
        final skill = await MacroRecorderService.instance.stopRecording();
        final reply = skill != null
            ? 'Makro „${skill.goal}“ bylo úspěšně zaznamenáno a zapsáno do AGENT.md, pane.'
            : 'Nahrávání makra bylo ukončeno, pane.';
        _lastJarvisSpeech = reply;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'MAKRO KODIFIKOVÁNO';
        notifyListeners();
        await _voice.speak(reply);
        await _startFollowUpListening();
        return;
      }
    }

    if (lower.startsWith('record macro ') ||
        lower.startsWith('start recording ') ||
        lower.startsWith('teach jarvis ') ||
        lower.startsWith('nahraj makro ')) {
      final macroGoal = trimmed
          .replaceFirst(RegExp(r'^(record\s+macro|start\s+recording|teach\s+jarvis|nahraj\s+makro)\s+', caseSensitive: false), '')
          .trim();
      await MacroRecorderService.instance.startRecording(macroGoal.isNotEmpty ? macroGoal : 'Vlastní úloha');
      final reply = 'Nahrávání makra pro „${macroGoal.isNotEmpty ? macroGoal : 'Vlastní úloha'}“ zahájeno, pane. Předveďte akce na obrazovce a po dokončení řekněte „ulož makro“.';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'NAHRÁVÁM MAKRO: ${macroGoal.toUpperCase()}';
      notifyListeners();
      await _voice.speak(reply);
      if (_shouldListenContinuously) _standDown();
      return;
    }

    if (lower.startsWith('run macro ') ||
        lower.startsWith('replay macro ') ||
        lower.startsWith('spusť makro ') ||
        lower.startsWith('přehraj makro ')) {
      final macroName = trimmed
          .replaceFirst(RegExp(r'^(run\s+macro|replay\s+macro|spusť\s+makro|přehraj\s+makro)\s+', caseSensitive: false), '')
          .trim();
      final match = await SkillMemoryService.instance.findMatch(macroName);
      if (match != null) {
        final reply = 'Spouštím makro „${match.goal}“, pane.';
        _lastJarvisSpeech = reply;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'PŘEHRÁVÁM MAKRO: ${match.goal.toUpperCase()}';
        notifyListeners();
        await _voice.speak(reply);
        await MacroRecorderService.instance.replaySkill(match);
      } else {
        final reply = 'Nepodařilo se mi najít zaznamenané makro odpovídající „$macroName“, pane.';
        _lastJarvisSpeech = reply;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(reply);
      }
      await _startFollowUpListening();
      return;
    }

    // 3c. Jarvis Eye Optical Perception fast trigger
    if (lower.contains('look at this') ||
        lower.contains('what is this') ||
        lower.contains('scan this') ||
        lower.contains('inspect this') ||
        lower.contains('jarvis eye') ||
        lower.contains('what do you see') ||
        lower.contains('podívej se na tohle') ||
        lower.contains('co je tohle') ||
        lower.contains('co vidíš')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'OPTICKÉ SENZORY AKTIVNÍ // SKENUJI';
      notifyListeners();

      const ack = 'Optické senzory jsou aktivní, pane. Nyní zkoumám objekt.';
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(ack);

      final result = await VisionPerceptionService.instance.inspectOpticalSnapshot(customPrompt: trimmed);
      _lastJarvisSpeech = result.spokenSummary;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'OPTICKÝ SKEN DOKONČEN';
      notifyListeners();
      await _voice.speak(result.spokenSummary);
      await _startFollowUpListening();
      return;
    }

    // 3d. Smart Home & IoT Automation fast trigger
    if (lower.contains('smart light') ||
        lower.contains('smart home') ||
        lower.contains('living room light') ||
        lower.contains('turn on the light') ||
        lower.contains('turn off the light') ||
        lower.contains('dim the light') ||
        lower.contains('turn on light') ||
        lower.contains('turn off light') ||
        lower.contains('desk lamp') ||
        lower.contains('rozsviť') ||
        lower.contains('zhasni') ||
        lower.contains('chytrá domácnost') ||
        lower.contains('světlo v obýváku')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'CHYTRÁ DOMÁCNOST IOT // ODESÍLÁM';
      notifyListeners();

      final reply = await SmartHomeService.instance.handleVoiceCommand(trimmed);
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'CHYTRÁ DOMÁCNOST AKTIVNÍ';
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // 3e. Proactive Commute & Traffic fast trigger
    if (lower.contains('how is traffic') ||
        lower.contains('commute to') ||
        lower.contains('traffic to') ||
        lower.contains('when should i leave') ||
        lower == 'traffic' ||
        lower == 'commute' ||
        lower.contains('jaká je doprava') ||
        lower == 'doprava' ||
        lower == 'dojíždění') {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'VÝPOČET // TELEMETRIE DOJÍŽDĚNÍ A DOPRAVY';
      notifyListeners();

      String? dest;
      if (lower.contains(' to ')) {
        dest = trimmed.split(RegExp(r'\s+to\s+', caseSensitive: false)).last.trim();
      } else if (lower.contains(' do ')) {
        dest = trimmed.split(RegExp(r'\s+do\s+', caseSensitive: false)).last.trim();
      }

      final commute = await CommuteTrafficService.instance.checkCommute(destination: dest);
      _lastJarvisSpeech = commute.spokenSummary;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'DOPRAVNÍ HLÁŠENÍ';
      notifyListeners();
      await _voice.speak(commute.spokenSummary);
      await _startFollowUpListening();
      return;
    }

    // 3e-1. Superpower: Screen & Article Summarization
    if (lower.contains('summarize this screen') ||
        lower.contains('summarize this article') ||
        lower.contains('summarize screen') ||
        lower.contains('summarize article') ||
        lower.contains('what is on my screen') ||
        lower.contains('summarize page') ||
        lower.contains('summarize the page') ||
        lower.contains('read this article') ||
        lower.contains('article summary') ||
        lower.contains('shrň obrazovku') ||
        lower.contains('shrň tento článek') ||
        lower.contains('co je na obrazovce')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'VÝPOČET // SHRNUTÍ ČLÁNKU';
      notifyListeners();

      const ack = 'Analyzuji článek na aktivní obrazovce, pane. Okamžik.';
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(ack);

      _phase = JarvisPhase.thinking;
      _statusMessage = 'SYNTÉZA EXEKUTIVNÍHO BRÍFINKU';
      notifyListeners();

      final summary = await JarvisToolsService.instance.summarizeForegroundScreen();
      _lastJarvisSpeech = summary;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'SHRNUTÍ ČLÁNKU PŘIPRAVENO';
      notifyListeners();
      await _voice.speak(summary);
      await _startFollowUpListening();
      return;
    }

    // 3e-2. Sentry Protocol & Sentry Mode (100% Equivalent Tactical Anti-Theft Watchdog)
    final isSentryCommand = lower.contains('sentry') ||
        lower.contains('centry') ||
        lower.contains('century protocol') ||
        lower.contains('century mode') ||
        lower.contains('guard my phone') ||
        lower.contains('watch my phone') ||
        lower.contains('anti theft') ||
        lower.contains('anti-theft') ||
        lower.contains('watchdog protocol') ||
        lower.contains('watchdog mode') ||
        lower.contains('režim hlídky') ||
        lower.contains('protokol hlídky') ||
        lower.contains('hlídej telefon') ||
        (SentryService.instance.isArmed &&
            (lower.contains('deactivat') ||
             lower.contains('disarm') ||
             lower.contains('stand down') ||
             lower.contains('stop sentry') ||
             lower.contains('deaktivuj') ||
             lower.contains('odzbroj') ||
             lower.contains('protocol') ||
             lower.contains('protocal')));

    if (isSentryCommand) {
      _phase = JarvisPhase.thinking;
      notifyListeners();

      final isDisarm = lower.contains('deactivat') ||
          lower.contains('de-activate') ||
          lower.contains('de activate') ||
          lower.contains('d-activate') ||
          lower.contains('d activate') ||
          lower.contains('the activate') ||
          lower.contains('disarm') ||
          lower.contains('turn off') ||
          lower.contains('switch off') ||
          lower.contains('shut down') ||
          lower.contains('stand down') ||
          lower.contains('disable') ||
          lower.contains('stop') ||
          lower.contains('cancel') ||
          lower.contains('exit') ||
          lower.contains('unarm') ||
          lower.contains('de-arm') ||
          lower.contains('de arm') ||
          lower.contains('deaktivuj') ||
          lower.contains('odzbroj') ||
          lower.contains('vypni') ||
          (SentryService.instance.isArmed &&
              !lower.contains('activat') &&
              !lower.contains('arm') &&
              !lower.contains('engage') &&
              !lower.contains('enable') &&
              !lower.contains('turn on') &&
              !lower.contains('zapni') &&
              !lower.contains('aktivuj'));

      if (isDisarm) {
        _statusMessage = 'PROTOKOL HLÍDKY // ODZBROJOVÁNÍ';
        notifyListeners();
        await SentryService.instance.disarmSentry();
      } else {
        _statusMessage = 'PROTOKOL HLÍDKY // AKTIVACE HLÍDAČE';
        notifyListeners();
        await SentryService.instance.armSentry();
      }
      _phase = JarvisPhase.idle;
      notifyListeners();
      if (_shouldListenContinuously) _standDown();
      return;
    }

    // 3e-2b. Creator & Builder Identity (Built by Abuzar)
    if (lower.contains('who built you') ||
        lower.contains('who created you') ||
        lower.contains('who made you') ||
        lower.contains('who is your creator') ||
        lower.contains('who is your developer') ||
        lower.contains('who is your builder') ||
        lower.contains('who developed you') ||
        lower.contains('who designed you') ||
        lower.contains('who programmed you') ||
        lower.contains('who build you') ||
        lower.contains('who design you') ||
        lower.contains('who coded you') ||
        lower.contains('who write you') ||
        lower.contains('kdo tě vytvořil') ||
        lower.contains('kdo tě postavil') ||
        lower.contains('kdo tě naprogramoval') ||
        lower.contains('kdo je tvůj tvůrce')) {
      _phase = JarvisPhase.thinking;
      notifyListeners();

      final reply = PersonalityService.instance.getCreatorAnswer();
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'TVŮRCE // ABUZAR';
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 1: 🖐️ Iron Man Zero-Touch Air Gestures
    // -----------------------------------------------------------------
    if (lower.contains('air gesture') ||
        lower.contains('air gestures') ||
        lower.contains('zero touch') ||
        lower.contains('touchless') ||
        lower.contains('hand wave gesture') ||
        lower.contains('vzdušná gesta') ||
        lower.contains('bezdotyková gesta')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'SENZORICKÁ MATICE VZDUŠNÝCH GEST';
      notifyListeners();
      final isOff = lower.contains('off') ||
          lower.contains('disable') ||
          lower.contains('deactivat') ||
          lower.contains('stop') ||
          lower.contains('vypni') ||
          lower.contains('deaktivuj');
      String reply;
      if (isOff) {
        await AirGestureService.instance.stop();
        reply = 'Bezdotykové senzory vzdušných gest Iron Mana byly odpojeny, pane.';
      } else {
        await AirGestureService.instance.start();
        reply =
            'Bezdotyková vzdušná gesta jsou aktivní, pane. Mávnutím ruky přeskočíte hudbu, podržením dlaně pozastavíte přehrávání a dvojitým mávnutím pořídíte okamžitý snímek obrazovky.';
      }
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 2: ⚡ Arc Reactor Charging Telemetry
    // -----------------------------------------------------------------
    if (lower.contains('charging telemetry') ||
        lower.contains('arc reactor status') ||
        lower.contains('arc reactor telemetry') ||
        lower.contains('charge speed') ||
        lower.contains('charging speed') ||
        lower.contains('charging wattage') ||
        lower.contains('telemetrie nabíjení') ||
        lower.contains('rychlost nabíjení')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'TELEMETRIE NABÍJENÍ OBLOUKOVÉHO REAKTORU';
      notifyListeners();
      ChargingTelemetryService.instance.showCinematicHud.value = true;
      final reply = await ChargingTelemetryService.instance.getSpokenTelemetry();
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 3: 🌐 Polyglot Diplomat (Live Two-Way Voice Translator)
    // -----------------------------------------------------------------
    if (lower.startsWith('translate ') && lower.contains(' to ')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'POLYGLOTNÍ DIPLOMAT // PŘEKLÁDÁM';
      notifyListeners();
      final phrase = trimmed
          .replaceFirst(RegExp(r'^translate\s+', caseSensitive: false), '')
          .split(RegExp(r'\s+to\s+', caseSensitive: false))
          .first
          .trim();
      final target = trimmed
          .split(RegExp(r'\s+to\s+', caseSensitive: false))
          .last
          .trim();
      final res = await PolyglotDiplomatService.instance
          .translate(text: phrase, toLang: target);
      final reply = 'Přeloženo do jazyka $target, pane: $res';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    if (lower.contains('polyglot') ||
        lower.contains('live translator') ||
        lower.contains('voice translator') ||
        lower.startsWith('translate between') ||
        lower.contains('diplomat translator') ||
        lower.contains('překladač') ||
        lower.contains('tlumočník')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'POLYGLOTNÍ DIPLOMAT // PŘEKLADAČ';
      notifyListeners();
      _showModalSafely(const PolyglotDiplomatDialog());
      const reply =
          'Polyglotní diplomat je aktivní, pane. Jsem připraven na obousměrný hlasový překlad v reálném čase.';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 4: 🎭 "Code Black" / Deceptive Lockout Screen
    // -----------------------------------------------------------------
    if (lower.contains('code black') ||
        lower.contains('deceptive lockout') ||
        lower.contains('kernel panic screen') ||
        lower.contains('emergency lockdown') ||
        lower.contains('černý kód') ||
        lower.contains('nouzové uzamčení')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'ČERNÝ KÓD // HARDWAROVÉ UZAMČENÍ';
      notifyListeners();
      await CodeBlackService.instance.arm();
      _phase = JarvisPhase.idle;
      notifyListeners();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 5: 👁️ Holographic Floating Co-Pilot
    // -----------------------------------------------------------------
    if (lower.contains('floating copilot') ||
        lower.contains('floating assistant') ||
        lower.contains('screen copilot') ||
        lower.contains('screen assistant') ||
        lower.contains('plovoucí kopilot') ||
        lower.contains('plovoucí asistent')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'HOLOGRAFICKÝ PLOVOUCÍ KOPILOT';
      notifyListeners();
      final isOff = lower.contains('hide') ||
          lower.contains('close') ||
          lower.contains('stop') ||
          lower.contains('dismiss') ||
          lower.contains('skryj') ||
          lower.contains('vypni') ||
          lower.contains('zavři');
      String reply;
      if (isOff) {
        await FloatingCopilotService.instance.hideOverlay();
        reply = 'Plovoucí kopilot byl skryt, pane.';
      } else {
        await FloatingCopilotService.instance.activateOverlay();
        reply =
            'Holografický plovoucí kopilot je aktivní, pane. Jsem v pohotovosti nad aktivními aplikacemi s kontextovou analýzou obrazovky.';
      }
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 6: 📡 Overhead Airspace & Satellite Radar
    // -----------------------------------------------------------------
    if (lower.contains('flying above me') ||
        lower.contains('what is flying') ||
        lower.contains('scan airspace') ||
        lower.contains('overhead flights') ||
        lower.contains('airspace radar') ||
        lower.contains('where is the iss') ||
        lower.contains('satellite pass') ||
        lower.contains('co létá nade mnou') ||
        lower.contains('radar vzdušného prostoru')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'RADAROVÝ PRŮZKUM VZDUŠNÉHO PROSTORU A SATELITŮ';
      notifyListeners();
      _showModalSafely(const AirspaceRadarDialog());
      final reply = await AirspaceRadarService.instance.getSpokenAirspaceReport();
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 7: 🧠 "Chaotic Brain Dump" Multi-Task Decoupler
    // -----------------------------------------------------------------
    if (MultiTaskDecouplerService.instance.isMultiTaskDump(trimmed)) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'ROZKLÁDÁM VÍCEÚLOHOVÝ PŘÍKAZ';
      notifyListeners();
      const ack =
          'Rozkládám váš složený příkaz do paralelních instrukcí, pane. Okamžitě provádím.';
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      final ackFuture = _voice.speak(ack);
      final dumpFuture = MultiTaskDecouplerService.instance.processBrainDump(trimmed);
      await ackFuture;
      final summary = await dumpFuture;
      _lastJarvisSpeech = summary;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'VÍCEÚLOHOVÉ ZPRACOVÁNÍ DOKONČENO';
      notifyListeners();
      await _voice.speak(summary);
      await _startFollowUpListening();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 8: 👁️ Real-Time Optical HUD Solver
    // -----------------------------------------------------------------
    if (lower.contains('solve this') ||
        lower.contains('solve equation') ||
        lower.contains('optical solver') ||
        lower.contains('inspect error') ||
        lower.contains('split bill') ||
        lower.contains('split this bill') ||
        lower.contains('solve math') ||
        lower.contains('analyze circuit') ||
        lower.contains('vyřeš tohle') ||
        lower.contains('optický řešitel') ||
        lower.contains('rozděl účet')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'OPTICKÝ HUD ŘEŠITEL V REÁLNÉM ČASE';
      notifyListeners();
      _showModalSafely(const OpticalSolverDialog());
      const ack = 'Cíl zaměřen v optickém hledáčku, pane. Nyní řeším.';
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      final ackFuture = _voice.speak(ack);
      final solveFuture = OpticalSolverService.instance.pointAndSolve(customQuery: trimmed);
      await ackFuture;
      final res = await solveFuture;
      _lastJarvisSpeech = res.spokenSummary;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'CÍL VYŘEŠEN';
      notifyListeners();
      await _voice.speak(res.spokenSummary);
      await _startFollowUpListening();
      return;
    }

    // -----------------------------------------------------------------
    // Superpower 9: 🛡️ Network Cyber Security Audit & Wi-Fi Scanner
    // -----------------------------------------------------------------
    if (lower.contains('audit network') ||
        lower.contains('audit my network') ||
        lower.contains('scan wifi') ||
        lower.contains('who is on my wifi') ||
        lower.contains('network devices') ||
        lower.contains('network security') ||
        lower.contains('port scan') ||
        lower.contains('audit sítě') ||
        lower.contains('skenuj wifi') ||
        lower.contains('kdo je na mé wifi')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'TAKTICKÝ KYBERNETICKÝ AUDIT SÍTĚ';
      notifyListeners();
      _showModalSafely(const NetworkAuditDialog());
      const ack =
          'Zahajuji taktický kybernetický bezpečnostní audit vaší místní podsítě, pane.';
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      final ackFuture = _voice.speak(ack);
      final auditFuture = NetworkAuditService.instance.getSpokenAuditReport();
      await ackFuture;
      final report = await auditFuture;
      _lastJarvisSpeech = report;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'AUDIT SÍTĚ DOKONČEN';
      notifyListeners();
      await _voice.speak(report);
      await _startFollowUpListening();
      return;
    }

    // 3e-3. Superpower: Direct Hardware Specs & Telemetry (No UI Taps / No Settings)
    if (lower.contains('system specs') ||
        lower.contains('phone specs') ||
        lower.contains('hardware specs') ||
        lower.contains('device specs') ||
        lower.contains('how much ram') ||
        lower.contains('ram info') ||
        lower.contains('storage space') ||
        lower.contains('rom space') ||
        lower.contains('how much free space') ||
        lower.contains('how much space is free') ||
        lower.contains('phone specifications') ||
        lower.contains('android version') ||
        lower.contains('specifikace telefonu') ||
        lower.contains('kolik mám ram') ||
        lower.contains('volné místo')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'HARDWAROVÁ TELEMETRIE // PŘÍMÁ';
      notifyListeners();

      final specs = await SystemDiagnosticsService.instance.getDiagnosticsSpoken();
      _lastJarvisSpeech = specs;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'TELEMETRIE V NORMĚ';
      notifyListeners();
      await _voice.speak(specs);
      await _startFollowUpListening();
      return;
    }

    // 3e-4. Superpower: Top Installed Applications (No UI Taps)
    if (lower.contains('installed apps') ||
        lower.contains('list apps') ||
        lower.contains('what apps are installed') ||
        lower.contains('list my apps') ||
        lower.contains('top installed apps') ||
        lower.contains('top 10 apps') ||
        lower.contains('nainstalované aplikace') ||
        lower.contains('seznam aplikací')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'INDEXACE // NAINSTALOVANÉ APLIKACE';
      notifyListeners();

      final appsSpoken = await AppUsageService.instance.getInstalledAppsSpoken();
      _lastJarvisSpeech = appsSpoken;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'APLIKACE NAINDEXOVÁNY';
      notifyListeners();
      await _voice.speak(appsSpoken);
      await _startFollowUpListening();
      return;
    }

    // 3e-5. Superpower: App Usage & Screen Time Statistics (No UI Taps)
    if (lower.contains('most used apps') ||
        lower.contains('apps i used the most') ||
        lower.contains('apps i use the most') ||
        lower.contains('which apps i used') ||
        lower.contains('screen time') ||
        lower.contains('app usage') ||
        lower.contains('top used apps') ||
        lower.contains('nejpoužívanější aplikace') ||
        lower.contains('využití aplikací') ||
        lower.contains('čas u obrazovky')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'TELEMETRIE VYUŽITÍ // STATISTIKY';
      notifyListeners();

      final usageSpoken = await AppUsageService.instance.getTopUsedAppsSpoken();
      _lastJarvisSpeech = usageSpoken;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'STATISTIKY VYUŽITÍ HOTOVY';
      notifyListeners();
      await _voice.speak(usageSpoken);
      await _startFollowUpListening();
      return;
    }

    // 3e-6. Superpower: Environmental Ears & Sound Radar
    if (lower.contains('what song is playing') ||
        lower.contains('identify this song') ||
        lower.contains('name this song') ||
        lower.contains('what music is this') ||
        lower.contains('scan ambient sound') ||
        lower.contains('sound radar') ||
        lower.contains('listen to the room') ||
        lower.contains('what do you hear') ||
        lower.contains('co to hraje') ||
        lower.contains('zvukový radar') ||
        lower.contains('co slyšíš')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'AKUSTICKÉ SENZORY AKTIVNÍ';
      notifyListeners();

      final isMusic = lower.contains('song') ||
          lower.contains('music') ||
          lower.contains('písničk') ||
          lower.contains('hudb') ||
          lower.contains('hraje');
      final result = isMusic
          ? await SoundRadarService.instance.identifyMusic()
          : await SoundRadarService.instance.scanAmbientEnvironment();

      _lastJarvisSpeech = result;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'AKUSTICKÝ SKEN DOKONČEN';
      notifyListeners();
      await _voice.speak(result);
      await _startFollowUpListening();
      return;
    }

    // 3e-7. Superpower: Direct Phone Storage File CRUD (No UI Taps / No Settings)
    final isStorageList = lower.contains('list files') ||
        lower.contains('files in download') ||
        lower.contains('vypiš soubory') ||
        lower.contains('soubory ve stažených');
    final isStorageCreate = (lower.contains('create') || lower.contains('write') || lower.contains('make') || lower.contains('vytvoř')) &&
        (lower.contains('file') || lower.contains('song') || lower.contains('download') || lower.contains('notes.txt') || lower.contains('soubor'));

    if (isStorageList) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'ÚLOŽIŠTĚ // DOTAZOVÁNÍ ADRESÁŘE';
      notifyListeners();

      final res = await PhoneStorageService.instance.listFiles(folder: 'Download');
      final files = (res['files'] as List?)?.map((e) => e.toString()).take(5).join(', ') ?? '';
      final reply = files.isNotEmpty
          ? 'Soubory nalezené ve složce Stažené zahrnují: $files, pane.'
          : 'Vaše složka Stažené je momentálně prázdná, pane.';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'ÚLOŽIŠTĚ NAINDEXOVÁNO';
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    if (isStorageCreate) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'ÚLOŽIŠTĚ CRUD // PŘÍMÉ PROVEDENÍ';
      notifyListeners();

      var fileName = 'note.txt';
      if (lower.contains('song')) {
        fileName = 'song.txt';
      } else if (lower.contains('.txt') || lower.contains('.json') || lower.contains('.md')) {
        final match = RegExp(r'([a-zA-Z0-9_\-]+\.[a-zA-Z0-9]+)').firstMatch(trimmed);
        if (match != null) fileName = match.group(1)!;
      }

      String content;
      if (lower.contains('song')) {
        content = '''Title: Electric Horizons (Stark Edition)
Verse 1:
Neon pulses through the titanium frame,
Silent watchers in the midnight game.
Through circuits of silver and rivers of light,
J.A.R.V.I.S. awakens and commands the night.

Chorus:
Arc reactor burning bright,
Guiding signals through the flight.
Beyond the limits of the mortal code,
Mastering the boundless road.
''';
      } else {
        content = 'Vytvořeno systémem J.A.R.V.I.S. dne ${DateTime.now().toIso8601String()}\nPožadavek: $trimmed\nStav: Dokončeno.';
      }

      final res = await PhoneStorageService.instance.createFile(
        fileName: fileName,
        content: content,
        folder: 'Download',
      );

      final reply = res['success'] == true
          ? 'Vytvořil jsem soubor „$fileName“ přímo ve vaší složce Stažené a zapsal do něj obsah, pane. Provedeno přímo bez otevírání systémového nastavení či správce souborů.'
          : 'Operace úložiště narazila na výjimku: ${res['message'] ?? 'Selhání oprávnění nebo I/O'}, pane.';

      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'SOUBOR V ÚLOŽIŠTI VYTVOŘEN';
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // 3f. Fast App Installation / Play Store Download ("install instagram", "download whatsapp", "get spotify app")
    final isInstall = lower.startsWith('install ') ||
        lower.startsWith('download ') ||
        lower.startsWith('nainstaluj ') ||
        lower.startsWith('stáhni ') ||
        (lower.startsWith('get ') && (lower.contains('app') || lower.contains('application')));
    if (isInstall) {
      final appName = trimmed
          .replaceFirst(RegExp(r'^(install|download|get|nainstaluj|stáhni)\s+', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+(app|aplikaci)$', caseSensitive: false), '')
          .trim();
      final targetApp = appName.isNotEmpty ? appName : 'aplikaci';
      final ack = PersonalityService.instance.getInstallAck(targetApp);
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'INSTALUJI: ${targetApp.toUpperCase()}';
      notifyListeners();
      await _voice.speak(ack);

      // Open Play Store directly to the app search/details
      try {
        final marketUri = Uri.parse('market://search?q=${Uri.encodeComponent(targetApp)}&c=apps');
        final webUri = Uri.parse('https://play.google.com/store/search?q=${Uri.encodeComponent(targetApp)}&c=apps');
        final ok = await launchUrl(marketUri, mode: LaunchMode.externalApplication).catchError((_) async {
          return await launchUrl(webUri, mode: LaunchMode.externalApplication);
        });
        if (!ok) {
          await AppLauncherService.instance.launch('com.android.vending');
        }
      } catch (e) {
        debugPrint('[JarvisService] Play Store direct launch error: $e');
        await AppLauncherService.instance.launch('com.android.vending');
      }

      // Hand off to autonomous task executor to tap "Install" on the screen!
      _phase = JarvisPhase.executing;
      notifyListeners();
      final status = await _executor.executeTask('install $targetApp on Play Store');
      _phase = JarvisPhase.speaking;
      if (status == TaskStatus.success) {
        final doneSpeech = 'Spustil jsem pro vás instalaci aplikace $targetApp. Dejte mi vědět, až ji budete chtít použít.';
        _lastJarvisSpeech = doneSpeech;
        _statusMessage = 'INSTALACE ZAHÁJENA';
        notifyListeners();
        await _voice.speak(doneSpeech);
      } else {
        final standDownSpeech = 'Obchod Play je otevřen pro aplikaci $targetApp. Klepněte na Instalovat, nebo mi dejte vědět, pokud potřebujete asistenci.';
        _lastJarvisSpeech = standDownSpeech;
        _statusMessage = 'OBCHOD PLAY PŘIPRAVEN';
        notifyListeners();
        await _voice.speak(standDownSpeech);
      }
      await _startFollowUpListening();
      return;
    }

    // 3f-2. Fast Direct Website / URL Opening ("otevři stránku github.com", "otevři github.com", "jdi na seznam.cz")
    {
      final normWeb = lower
          .replaceAll(RegExp(r'\s+tečka\s+|\s+tecka\s+|\s+dot\s+'), '.')
          .replaceAll(RegExp(r'\s+lomítko\s+|\s+lomitko\s+|\s+slash\s+'), '/');
      final explicitWebMatch = RegExp(
        r'^(?:otevři|otevri|spusť|spust|načti|nacti|zobraz|jdi\s+na|přejdi\s+na|prejdi\s+na|open|go\s+to)\s+(?:webovou\s+stránku|webovou\s+stranku|stránku|stranku|web|adresu|url|website|site|page)\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(normWeb);
      final directDomainMatch = RegExp(
        r'^(?:otevři|otevri|spusť|spust|načti|nacti|zobraz|jdi\s+na|přejdi\s+na|prejdi\s+na|open|go\s+to)\s+((?:https?://|www\.)?\S+\.(?:com|cz|sk|eu|org|net|io|ai|dev|gg|tv|me|info|co|uk|de|pl)(?:/\S*)?)$',
        caseSensitive: false,
      ).firstMatch(normWeb);

      String? rawTarget = explicitWebMatch?.group(1)?.trim() ??
          directDomainMatch?.group(1)?.trim();

      if (rawTarget != null && rawTarget.isNotEmpty) {
        rawTarget = rawTarget
            .replaceAll(
                RegExp(
                    r'\s+(?:v\s+prohlížeči|v\s+chromu|v\s+chrome|in\s+chrome|in\s+browser)$'),
                '')
            .replaceAll(RegExp(r'\s*\.\s*'), '.')
            .trim();

        const knownSites = <String, String>{
          'github': 'github.com',
          'seznam': 'seznam.cz',
          'google': 'google.com',
          'wikipedie': 'cs.wikipedia.org',
          'wikipedia': 'cs.wikipedia.org',
          'idnes': 'idnes.cz',
          'novinky': 'novinky.cz',
          'alza': 'alza.cz',
          'heureka': 'heureka.cz',
          'mapy': 'mapy.cz',
          'chatgpt': 'chatgpt.com',
          'reddit': 'reddit.com',
          'youtube': 'youtube.com',
          'facebook': 'facebook.com',
          'instagram': 'instagram.com',
          'twitter': 'x.com',
          'x': 'x.com',
        };

        String domain = knownSites[rawTarget] ?? rawTarget;
        if (!domain.contains('.') && !domain.contains(' ')) {
          domain = '$domain.com';
        }
        domain = domain.replaceAll(' ', '');
        final fullUrl =
            domain.startsWith('http://') || domain.startsWith('https://')
                ? domain
                : 'https://$domain';
        final spokenDomain =
            domain.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'^www\.'), '');

        final ack = 'Otevírám stránku $spokenDomain v prohlížeči, pane.';
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'OTEVÍRÁM WEB: ${spokenDomain.toUpperCase()}';
        notifyListeners();

        try {
          final uri = Uri.parse(fullUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('[JarvisService] Website launch error: $e');
        }

        await _voice.speak(ack);
        await _startFollowUpListening();
        return;
      }
    }

    // 3g. Fast Direct App Opening ("open youtube", "open whatsapp", "open camera", "open settings")
    if ((lower.startsWith('open ') || lower.startsWith('otevři ') || lower.startsWith('spusť ')) &&
        !lower.contains('play store and') &&
        !lower.contains(' and install') &&
        !lower.contains(' and play') &&
        !lower.contains(' and send')) {
      final appQuery = trimmed.replaceFirst(RegExp(r'^(open|otevři|spusť)\s+', caseSensitive: false), '').trim();
      final appName = appQuery.replaceAll(RegExp(r'\s+(app|aplikaci)$', caseSensitive: false), '').trim();
      if (appName.isNotEmpty && appName.length < 30) {
        final launched = await AppLauncherService.instance.launch(appName);
        if (launched != null) {
          final ack = PersonalityService.instance.getAppAck(appName);
          _lastJarvisSpeech = ack;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'SPOUŠTÍM: ${appName.toUpperCase()}';
          notifyListeners();
          await _voice.speak(ack);
          await _startFollowUpListening();
          return;
        }
      }
    }

    // 4. Fast Play Song / Play Music Action (Google Home / Assistant style)
    final isPlaySong = lower.startsWith('play ') ||
        lower.startsWith('přehraj ') ||
        lower.startsWith('pusť ') ||
        lower == 'play a song' ||
        lower == 'play song' ||
        lower == 'play music' ||
        lower.contains('play a song') ||
        lower.contains('play song') ||
        lower.contains('play some music') ||
        lower.contains('play songs') ||
        lower.contains('pusť hudbu') ||
        lower.contains('přehraj písničku') ||
        lower.contains('on youtube') ||
        lower.contains('in youtube') ||
        lower.contains('na youtube') ||
        (lower.contains('play') && (lower.contains('music') || lower.contains('song')));

    if (isPlaySong) {
      String songQuery = trimmed;
      songQuery = songQuery
          .replaceAll(RegExp(r'\b(on|in|na)\s+youtube\b', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^(play\s+the\s+song|play\s+a\s+song|play\s+song|play\s+music|play|přehraj|pusť)\s+', caseSensitive: false), '')
          .trim();

      final sqLower = songQuery.toLowerCase();
      if (sqLower.isEmpty ||
          sqLower == 'a song' ||
          sqLower == 'song' ||
          sqLower == 'music' ||
          sqLower == 'some music' ||
          sqLower == 'songs' ||
          sqLower == 'the song' ||
          sqLower == 'the music' ||
          sqLower == 'hudbu' ||
          sqLower == 'písničku') {
        songQuery = 'popular hit songs';
      }

      final ack = PersonalityService.instance.getMusicAck(songQuery);
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'PŘEHRÁVÁM: ${songQuery.toUpperCase()}';
      notifyListeners();

      // Suppress background speech recognition so it yields audio focus to YouTube/Spotify
      await _voice.notifyMediaPlaybackStarted(duration: const Duration(seconds: 60));

      await _voice.speak(ack);

      // Attempt 1: Fetch exact top YouTube video ID so it starts playing immediately!
      final videoId = await _resolveTopYouTubeVideoId(songQuery);
      if (videoId != null && videoId.isNotEmpty) {
        final videoUri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
        try {
          await launchUrl(videoUri, mode: LaunchMode.externalApplication);
        } catch (_) {
          await launchUrl(videoUri);
        }
      } else {
        // Attempt 2 Fallback: Open search and auto-click the first video result
        final uri = Uri.parse(
          'https://www.youtube.com/results?search_query=${Uri.encodeComponent(songQuery)}',
        );
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('[JarvisService] Play song launch error: $e');
          await AppLauncherService.instance.launch('com.google.android.youtube');
        }
        await Future.delayed(const Duration(milliseconds: 1400));
        try {
          final nodes = await _automation.dumpScreen();
          for (final n in nodes) {
            if (n.isClickable && n.centerY > 350 && n.centerY < 1500) {
              await _automation.clickNode(n);
              break;
            }
          }
        } catch (_) {}
      }
      await _voice.notifyMediaPlaybackStarted(duration: const Duration(seconds: 60));
      if (_shouldListenContinuously) _standDown();
      return;
    }

    // 4b. High-Priority Knowledge, Concept & Educational Question Filter (No accidental workflow collision)
    final isKnowledgeQuestion = RegExp(
      r'^(what\s+is|what\s+are|what\x27s|who\s+is|who\s+was|who\s+were|why\s+is|why\s+do|why\s+does|why\s+are|how\s+does|how\s+do|how\s+can|how\s+to|explain|tell\s+me\s+about|describe|define|can\s+you\s+explain|what\s+do\s+you\s+know\s+about|co\s+je|kdo\s+je|proč\s+je|jak\s+funguje|vysvětli|řekni\s+mi\s+o|popiš)\b',
      caseSensitive: false,
    ).hasMatch(trimmed) &&
    !lower.contains('what time') &&
    !lower.contains('what day') &&
    !lower.contains('what date') &&
    !lower.contains('what song') &&
    !lower.contains('what is on my screen') &&
    !lower.contains('what is this') &&
    !lower.contains('what do you see') &&
    !lower.contains('co je na obrazovce') &&
    !lower.contains('co je tohle') &&
    !lower.contains('battery') &&
    !lower.contains('baterie');

    if (isKnowledgeQuestion) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'ZPRACOVÁVÁM DOTAZ // NEURONOVÉ JÁDRO';
      notifyListeners();

      final topic = trimmed
          .replaceAll(
            RegExp(
              r'^(what\s+is|what\s+are|what\x27s|who\s+is|who\s+was|who\s+were|why\s+is|why\s+do|why\s+does|why\s+are|how\s+does|how\s+do|how\s+can|how\s+to|explain|tell\s+me\s+about|describe|define|can\s+you\s+explain|what\s+do\s+you\s+know\s+about|co\s+je|kdo\s+je|proč\s+je|jak\s+funguje|vysvětli|řekni\s+mi\s+o|popiš)\s+',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'[?.,!]+$'), '')
          .trim();

      // 1. Instantly speak a warm, personalized acknowledgment
      final ack = PersonalityService.instance.getQuestionAck(trimmed);
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      notifyListeners();

      // Concurrently speak acknowledgment and fetch multi-source web/encyclopedic records
      final speakAckFuture = _voice.speak(ack);
      final searchFuture = JarvisToolsService.instance.searchWeb(topic.isNotEmpty ? topic : trimmed);
      final searchResult = await searchFuture;

      _phase = JarvisPhase.thinking;
      _statusMessage = 'SYNTÉZA VYSVĚTLENÍ';
      notifyListeners();

      final answerFuture = searchResult.trim().isNotEmpty
          ? _ai.answerWithToolResult(
              userQuestion: trimmed,
              toolResult: searchResult,
              history: _dialogHistory,
            )
          : _ai.chat(
              message: trimmed,
              history: _dialogHistory,
            );

      await speakAckFuture;
      final answer = await answerFuture;

      _lastJarvisSpeech = answer;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'VYSVĚTLENÍ DOKONČENO';
      notifyListeners();
      await _voice.speak(answer);

      // Record in conversational history and memory
      _dialogHistory.add({'role': 'user', 'content': trimmed});
      _dialogHistory.add({'role': 'assistant', 'content': answer});
      if (_dialogHistory.length > 10) _dialogHistory.removeRange(0, 2);
      unawaited(ConversationalMemoryService.instance.recordTurn(trimmed, answer));

      // Immediate hands-free follow-up continuous listening
      await _startFollowUpListening();
      return;
    }

    // 5. Fast Self-Evolving Workflow Engine match (Hermes Agent Pattern)
    if (SettingsService.instance.jarvisWorkflowsEnabled) {
      final matchedWf = WorkflowService.instance.findMatch(trimmed);
      if (matchedWf != null) {
        _phase = JarvisPhase.thinking;
        _statusMessage = 'VÝPOČET // AKTIVACE ${matchedWf.name.toUpperCase()}';
        notifyListeners();

        // 1. Execute hardware changes (volume, brightness, torch)
        await WorkflowService.instance.executeWorkflow(matchedWf);

        // 2. Deliver completion with caring follow-up
        _phase = JarvisPhase.speaking;
        _lastJarvisSpeech = matchedWf.spokenConfirmation;
        _statusMessage = '${matchedWf.name.toUpperCase()} AKTIVNÍ';
        notifyListeners();
        await _voice.speak(matchedWf.spokenConfirmation);
        await _startFollowUpListening();
        return;
      }
    }

    // 5. Fast system diagnostic check
    if (lower == 'status' ||
        lower == 'system status' ||
        lower == 'diagnostics' ||
        lower == 'systems check' ||
        lower == 'stav systému' ||
        lower == 'diagnostika') {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'VÝPOČET // SPOUŠTÍM DIAGNOSTIKU';
      notifyListeners();

      final summary = await JarvisToolsService.instance.getSystemDiagnostics();
      final delivery = '$summary Jak vám ještě mohu dnes pomoci, pane?';
      _lastJarvisSpeech = delivery;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'SYSTÉMY V NORMĚ';
      notifyListeners();
      await _voice.speak(delivery);
      await _startFollowUpListening();
      return;
    }

    // 6. Fast Battery Check
    if (lower == 'battery' ||
        lower == 'battery level' ||
        lower == 'battery percentage' ||
        lower.contains('how much battery') ||
        lower.contains('battery status') ||
        lower == 'baterie' ||
        lower.contains('stav baterie') ||
        lower.contains('kolik mám baterie')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'VÝPOČET // DIAGNOSTIKA BATERIE';
      notifyListeners();

      final battery = await JarvisToolsService.instance.getBatteryStatus();
      final level = battery['level'] as int;
      final isCharging = battery['isCharging'] as bool;
      final reply = level >= 0
          ? 'Vaše baterie je aktuálně na $level % a ${isCharging ? 'nabíjí se' : 'běžně se vybíjí'}, pane. Máme dostatek energie pro vaše úkoly. Potřebujete ještě něco, pane?'
          : 'Telemetrie baterie je momentálně nedostupná, pane. Mohu pro vás zkontrolovat něco jiného?';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // 7. Fast Torch / Flashlight Check
    if (lower.contains('flashlight on') ||
        lower.contains('torch on') ||
        lower.contains('turn on flashlight') ||
        lower.contains('turn on the torch') ||
        lower.contains('zapni svítilnu') ||
        lower.contains('zapni baterku')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'VÝPOČET // ZAPÍNÁM SVÍTILNU';
      notifyListeners();

      await JarvisToolsService.instance.setTorch(true);
      const delivery = 'Svítilna je zapnutá, pane. Dejte mi vědět, až ji budete chtít vypnout.';
      _lastJarvisSpeech = delivery;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'SVÍTILNA AKTIVNÍ';
      notifyListeners();
      await _voice.speak(delivery);
      await _startFollowUpListening();
      return;
    }
    if (lower.contains('flashlight off') ||
        lower.contains('torch off') ||
        lower.contains('turn off flashlight') ||
        lower.contains('turn off the torch') ||
        lower.contains('vypni svítilnu') ||
        lower.contains('vypni baterku')) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'VÝPOČET // VYPÍNÁM SVÍTILNU';
      notifyListeners();

      await JarvisToolsService.instance.setTorch(false);
      const delivery = 'Svítilna je deaktivována, pane. Mohu pro vás udělat ještě něco?';
      _lastJarvisSpeech = delivery;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'SVÍTILNA VYPNUTA';
      notifyListeners();
      await _voice.speak(delivery);
      await _startFollowUpListening();
      return;
    }

    // 8. Fast Date / Time Check
    if (lower.contains('what time is it') ||
        lower == 'time' ||
        lower == 'current time' ||
        lower.contains('what is the date') ||
        lower == 'date' ||
        lower.contains('what day is it') ||
        lower.contains('kolik je hodin') ||
        lower == 'čas' ||
        lower == 'datum' ||
        lower.contains('jaké je datum')) {
      final dt = JarvisToolsService.instance.getCurrentDateTime();
      final reply = 'Aktuálně je $dt, pane. Jak vám ještě mohu dnes pomoci?';
      _lastJarvisSpeech = reply;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'ČASOVÁ DIAGNOSTIKA';
      notifyListeners();
      await _voice.speak(reply);
      await _startFollowUpListening();
      return;
    }

    // 9. Fast Direct System Control Filters
    if (lower.contains('volume up') ||
        lower.contains('louder') ||
        lower.contains('increase volume') ||
        lower.contains('zesil zvuk') ||
        lower.contains('zvyš hlasitost')) {
      await _handleSystemCommand('volume_up', PersonalityService.instance.getSystemAck('volume_up'));
      return;
    }
    if (lower.contains('volume down') ||
        lower.contains('quieter') ||
        lower.contains('lower volume') ||
        lower.contains('ztlum zvuk') ||
        lower.contains('sniž hlasitost')) {
      await _handleSystemCommand('volume_down', PersonalityService.instance.getSystemAck('volume_down'));
      return;
    }
    if (lower == 'mute' ||
        lower == 'silence' ||
        lower.contains('mute sound') ||
        lower == 'ztlumit' ||
        lower == 'ticho') {
      await _handleSystemCommand('mute', PersonalityService.instance.getSystemAck('mute'));
      return;
    }
    if (lower == 'unmute' ||
        lower.contains('unmute sound') ||
        lower == 'zapni zvuk') {
      await _handleSystemCommand('unmute', PersonalityService.instance.getSystemAck('unmute'));
      return;
    }
    if (lower.contains('screenshot') ||
        lower.contains('screen shot') ||
        lower.contains('capture screen') ||
        lower.contains('snímek obrazovky') ||
        lower.contains('vyfoť obrazovku')) {
      await _handleSystemCommand('screenshot', PersonalityService.instance.getSystemAck('screenshot'));
      return;
    }
    if (lower == 'home' ||
        lower == 'go home' ||
        lower == 'home screen' ||
        lower == 'domů' ||
        lower == 'domovská obrazovka') {
      await _handleSystemCommand('home', PersonalityService.instance.getSystemAck('home'));
      return;
    }
    if (lower == 'back' ||
        lower == 'go back' ||
        lower == 'zpět' ||
        lower == 'jdi zpět') {
      await _handleSystemCommand('back', PersonalityService.instance.getSystemAck('back'));
      return;
    }

    // 10. Fast Contact Call Filter
    if ((lower.startsWith('call ') || lower.startsWith('zavolej ')) && !lower.contains('screen')) {
      final name = trimmed.replaceFirst(RegExp(r'^(call|zavolej)\s+', caseSensitive: false), '').trim();
      if (name.isNotEmpty) {
        final ack = 'Vyhledávám kontakt pro zavolání $name, pane. Okamžik.';
        _phase = JarvisPhase.speaking;
        _lastJarvisSpeech = ack;
        _statusMessage = 'VYTÁČENÍ KONTAKTU // $name'.toUpperCase();
        notifyListeners();
        await _voice.speak(ack);

        final reply = await JarvisToolsService.instance.callContact(name);
        _lastJarvisSpeech = reply;
        notifyListeners();
        await _voice.speak(reply);
        if (_shouldListenContinuously) _standDown();
        return;
      }
    }

    // 11. Fast Live Breaking News Filter
    final isNews = lower.contains('news') ||
        lower.contains('headline') ||
        lower.contains('what happened today') ||
        lower.contains('breaking news') ||
        lower.contains('give me news') ||
        lower.contains('current news') ||
        lower.contains('what is the news') ||
        lower.contains('what is happening in the world') ||
        lower.contains('latest news') ||
        lower.contains('zprávy') ||
        lower.contains('aktuality') ||
        lower.contains('co se dnes stalo');

    if (isNews) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'SHROMAŽĎUJI ZPRAVODAJSKÉ TITULKY';
      notifyListeners();

      // Extract topic if specified
      String? topic;
      for (final kw in [
        'tech',
        'technology',
        'sports',
        'cricket',
        'football',
        'business',
        'crypto',
        'world',
        'science',
        'politics',
        'ai',
        'space',
      ]) {
        if (lower.contains(kw)) {
          topic = kw;
          break;
        }
      }

      // 1. Instantly speak a warm, personalized, non-repetitive British acknowledgment!
      final ack = PersonalityService.instance.getNewsAck(topic);
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      notifyListeners();

      // Concurrently speak acknowledgment and fetch live multi-feed news in background
      final speakAckFuture = _voice.speak(ack);
      final newsDataFuture = JarvisToolsService.instance.getLiveNews(topic);

      final newsData = await newsDataFuture;

      _phase = JarvisPhase.thinking;
      _statusMessage = 'SYNTÉZA ZPRAVODAJSKÉHO BRÍFINKU';
      notifyListeners();

      final answerFuture = _ai.answerWithToolResult(
        userQuestion: trimmed,
        toolResult: newsData,
        history: _dialogHistory,
      );

      // Ensure initial acknowledgment finishes speaking before delivering final briefing
      await speakAckFuture;
      final answer = await answerFuture;

      // 2. Spoken reply to question
      _lastJarvisSpeech = answer;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'VYSÍLÁNÍ ZPRAVODAJSKÉ TELEMETRIE';
      notifyListeners();
      await _voice.speak(answer);

      await _startFollowUpListening();
      return;
    }

    // 11b. Fast Live Web Search & Real-Time Information Filter (only explicit web search commands)
    final isWebSearch = lower.startsWith('search ') ||
        lower.startsWith('search for ') ||
        lower.startsWith('look up ') ||
        lower.startsWith('google ') ||
        lower.startsWith('find out ') ||
        lower.startsWith('check online ') ||
        lower.startsWith('vyhledej ') ||
        lower.startsWith('vygoogli ') ||
        lower.startsWith('najdi na internetu ') ||
        lower.startsWith('najdi na webu ') ||
        lower.contains('search the web') ||
        lower.contains('search online');

    if (isWebSearch) {
      _phase = JarvisPhase.thinking;
      _statusMessage = 'INICIALIZACE WEBOVÉ INTELIGENCE';
      notifyListeners();

      final query = trimmed
          .replaceAll(
            RegExp(
              r'^(search\s+for|search\s+the\s+web\s+for|search\s+online\s+for|search|look\s+up|google|find\s+out|tell\s+me\s+about|check\s+online\s+for|vyhledej|najdi)\s+',
              caseSensitive: false,
            ),
            '',
          )
          .trim();

      // 1. Instantly speak dynamic, personalized acknowledgment
      final ack = PersonalityService.instance.getWebSearchAck(query);
      _lastJarvisSpeech = ack;
      _phase = JarvisPhase.speaking;
      notifyListeners();

      // Concurrently speak acknowledgment and execute multi-source search in background
      final speakAckFuture = _voice.speak(ack);
      final searchFuture = JarvisToolsService.instance.searchWeb(query.isNotEmpty ? query : trimmed);

      final searchResult = await searchFuture;

      _phase = JarvisPhase.thinking;
      _statusMessage = 'SYNTÉZA WEBOVÝCH INFORMACÍ';
      notifyListeners();

      final answerFuture = _ai.answerWithToolResult(
        userQuestion: trimmed,
        toolResult: searchResult,
        history: _dialogHistory,
      );

      await speakAckFuture;
      final answer = await answerFuture;

      _lastJarvisSpeech = answer;
      _phase = JarvisPhase.speaking;
      _statusMessage = 'WEBOVÉ INFORMACE ZÍSKÁNY';
      notifyListeners();
      await _voice.speak(answer);

      await _startFollowUpListening();
      return;
    }

    // 12. Full AI Intent Interpretation via AiService
    JarvisIntent intent;
    try {
      intent = await _ai.interpretJarvisCommand(
        speech: trimmed,
        history: _dialogHistory,
      );
    } catch (_) {
      intent = JarvisIntent.fallback(trimmed);
    }

    // Save short-term dialog context (for non-chat intents; chat intents record actual AI reply below)
    if (intent.type != JarvisIntentType.chat) {
      _dialogHistory.add({'role': 'user', 'content': trimmed});
      _dialogHistory.add({'role': 'assistant', 'content': intent.spoken});
      if (_dialogHistory.length > 20) {
        _dialogHistory.removeRange(0, 2);
      }
    }

    switch (intent.type) {
      case JarvisIntentType.news:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'SHROMAŽĎUJI ZPRAVODAJSKÉ TITULKY';
        notifyListeners();

        final ack = PersonalityService.instance.getNewsAck(intent.toolArg);
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        notifyListeners();

        final speakAckFuture = _voice.speak(ack);
        final newsFuture = JarvisToolsService.instance.getLiveNews(intent.toolArg);
        final newsData = await newsFuture;

        _phase = JarvisPhase.thinking;
        _statusMessage = 'SYNTÉZA ZPRAVODAJSKÉHO BRÍFINKU';
        notifyListeners();

        final answerFuture = _ai.answerWithToolResult(
          userQuestion: trimmed,
          toolResult: newsData,
          history: _dialogHistory,
        );

        await speakAckFuture;
        final answer = await answerFuture;

        _lastJarvisSpeech = answer;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'VYSÍLÁNÍ ZPRAVODAJSKÉ TELEMETRIE';
        notifyListeners();
        await _voice.speak(answer);
        break;

      case JarvisIntentType.workflow:
        final rawArg = (intent.toolArg ?? trimmed).toLowerCase();
        // Check for Sentry Protocol / Sentry Mode within workflow intent
        if (rawArg.contains('sentry') || rawArg.contains('watchdog') || rawArg.contains('hlídk')) {
          final isDisarm = rawArg.contains('disarm') ||
              rawArg.contains('deactivat') ||
              rawArg.contains('stop') ||
              rawArg.contains('cancel') ||
              rawArg.contains('stand down') ||
              rawArg.contains('odzbroj') ||
              rawArg.contains('deaktivuj') ||
              rawArg.contains('vypni');
          if (isDisarm) {
            _statusMessage = 'PROTOKOL HLÍDKY // ODZBROJOVÁNÍ';
            notifyListeners();
            await SentryService.instance.disarmSentry();
          } else {
            _statusMessage = 'PROTOKOL HLÍDKY // AKTIVACE HLÍDAČE';
            notifyListeners();
            await SentryService.instance.armSentry();
          }
          break;
        }

        final ack = intent.spoken.isNotEmpty
            ? intent.spoken
            : 'Ihned, pane. Kalibruji prostředí vašeho nastavení.';
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'KALIBRACE PROTOKOLU PRACOVNÍHO POSTUPU';
        notifyListeners();

        // 1. Speak courteous acknowledgment completely
        await _voice.speak(ack);

        // 2. Execute workflow
        _phase = JarvisPhase.executing;
        notifyListeners();

        final match = WorkflowService.instance.findMatch(intent.toolArg ?? trimmed) ??
            WorkflowService.instance.findMatch(trimmed);

        if (match != null) {
          await WorkflowService.instance.executeWorkflow(match);
          _lastJarvisSpeech = match.spokenConfirmation;
          _phase = JarvisPhase.speaking;
          _statusMessage = '${match.name.toUpperCase()} AKTIVNÍ';
          notifyListeners();
          await _voice.speak(match.spokenConfirmation);
        } else {
          const fallback = 'Všechna nastavení byla pro vás zkalibrována, pane. Dejte mi vědět, pokud budete cokoliv dalšího potřebovat.';
          _lastJarvisSpeech = fallback;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'PROTOKOL AKTIVNÍ';
          notifyListeners();
          await _voice.speak(fallback);
        }
        break;

      case JarvisIntentType.webSearch:
        final query = intent.toolArg ?? trimmed;
        final ack = PersonalityService.instance.getWebSearchAck(query);
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'PROHLEDÁVÁM ŽIVÉ WEBOVÉ ZÁZNAMY';
        notifyListeners();

        final speakAckFuture = _voice.speak(ack);
        final searchFuture = JarvisToolsService.instance.searchWeb(query);
        final searchResult = await searchFuture;

        _phase = JarvisPhase.thinking;
        _statusMessage = 'SYNTÉZA WEBOVÝCH INFORMACÍ';
        notifyListeners();

        final answerFuture = _ai.answerWithToolResult(
          userQuestion: trimmed,
          toolResult: searchResult,
          history: _dialogHistory,
        );

        await speakAckFuture;
        final answer = await answerFuture;

        _lastJarvisSpeech = answer;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'WEBOVÉ INFORMACE ZÍSKÁNY';
        notifyListeners();
        await _voice.speak(answer);
        break;

      case JarvisIntentType.weather:
        final loc = intent.toolArg ?? '';
        final ack = PersonalityService.instance.getWeatherAck(loc);
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'METEOROLOGICKÁ TELEMETRIE';
        notifyListeners();

        final speakAckFuture = _voice.speak(ack);
        final weatherFuture = JarvisToolsService.instance.getWeather(loc);
        final weatherResult = await weatherFuture;

        _phase = JarvisPhase.thinking;
        _statusMessage = 'SYNTÉZA PŘEDPOVĚDI POČASÍ';
        notifyListeners();

        final answerFuture = _ai.answerWithToolResult(
          userQuestion: trimmed,
          toolResult: weatherResult,
          history: _dialogHistory,
        );

        await speakAckFuture;
        final answer = await answerFuture;

        _lastJarvisSpeech = answer;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'METEOROLOGICKÁ ZPRÁVA DOKONČENA';
        notifyListeners();
        await _voice.speak(answer);
        break;

      case JarvisIntentType.battery:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'VÝPOČET // DIAGNOSTIKA BATERIE';
        notifyListeners();

        final battery =
            await JarvisToolsService.instance.getBatteryStatus();
        final level = battery['level'] as int;
        final isCharging = battery['isCharging'] as bool;
        final battReply = level >= 0
            ? 'Vaše baterie je aktuálně na $level % a ${isCharging ? 'nabíjí se' : 'běžně se vybíjí'}, pane. Máme spoustu energie. Potřebujete ještě něco, pane?'
            : 'Telemetrie úrovně baterie je momentálně nedostupná, pane. Mohu zkontrolovat něco jiného?';

        _lastJarvisSpeech = battReply;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(battReply);
        break;

      case JarvisIntentType.datetime:
        _phase = JarvisPhase.speaking;
        _statusMessage = 'ČASOVÁ DIAGNOSTIKA';
        notifyListeners();

        final dt = JarvisToolsService.instance.getCurrentDateTime();
        final reply = 'Aktuálně je $dt, pane. Jak vám ještě mohu dnes posloužit?';
        _lastJarvisSpeech = reply;
        notifyListeners();
        await _voice.speak(reply);
        break;

      case JarvisIntentType.torch:
        final on = intent.toolArg == 'on';
        _phase = JarvisPhase.thinking;
        _statusMessage = on ? 'VÝPOČET // ZAPÍNÁM SVÍTILNU' : 'VÝPOČET // VYPÍNÁM SVÍTILNU';
        notifyListeners();

        await JarvisToolsService.instance.setTorch(on);
        final reply = on
            ? 'Svítilna je zapnutá, pane. Dejte mi vědět, až ji budete chtít vypnout.'
            : 'Svítilna je deaktivována, pane. Mohu pro vás udělat ještě něco?';
        _lastJarvisSpeech = reply;
        _phase = JarvisPhase.speaking;
        _statusMessage = on ? 'SVÍTILNA AKTIVNÍ' : 'SVÍTILNA VYPNUTA';
        notifyListeners();
        await _voice.speak(reply);
        break;

      case JarvisIntentType.routine:
        final isMorning = (intent.toolArg ?? '').toLowerCase() == 'morning' ||
            trimmed.toLowerCase().contains('morning') ||
            trimmed.toLowerCase().contains('ráno') ||
            trimmed.toLowerCase().contains('ranní');
        _phase = JarvisPhase.thinking;
        _statusMessage = isMorning ? 'VÝPOČET // RANNÍ BRÍFINK' : 'VÝPOČET // NOČNÍ PROTOKOL';
        notifyListeners();

        final briefing = isMorning
            ? await RoutineAutomationService.instance.executeMorningRoutine()
            : await RoutineAutomationService.instance.executeEveningRoutine();

        _lastJarvisSpeech = briefing;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(briefing);
        break;

      case JarvisIntentType.finance:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'VÝPOČET // FINANČNÍ TELEMETRIE';
        notifyListeners();

        final quote = await FinanceTrackingService.instance.getQuoteForQuery(trimmed);
        _lastJarvisSpeech = quote;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(quote);
        break;

      case JarvisIntentType.sports:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'VÝPOČET // SPORTOVNÍ VÝSLEDKY';
        notifyListeners();

        final update = await SportsService.instance.getSportsUpdate(trimmed);
        _lastJarvisSpeech = update;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(update);
        break;

      case JarvisIntentType.todo:
        final lower = trimmed.toLowerCase();
        if (lower.startsWith('add ') ||
            lower.contains('add task') ||
            lower.contains('add to') ||
            lower.startsWith('přidej ')) {
          var taskText = trimmed
              .replaceFirst(RegExp(r'^(add\s+to\s+(my\s+)?(todo|to-do)(\s+list)?|add\s+task|add|přidej\s+úkol|přidej)\s+', caseSensitive: false), '')
              .trim();
          if (taskText.isEmpty) taskText = 'Zkontrolovat úkol';
          await TodoService.instance.addTask(taskText);
          final reply = 'Přidal jsem „$taskText“ do vašeho seznamu úkolů, pane. Ještě něco?';
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'ÚKOL ZAZNAMENÁN';
          notifyListeners();
          await _voice.speak(reply);
        } else {
          final reply = TodoService.instance.getPendingTasksSpoken();
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'AGENDA ÚKOLŮ';
          notifyListeners();
          await _voice.speak(reply);
        }
        break;

      case JarvisIntentType.notes:
        final lower = trimmed.toLowerCase();
        if (lower.startsWith('take a note') ||
            lower.startsWith('note down') ||
            lower.startsWith('write a note') ||
            lower.startsWith('zapiš poznámku')) {
          var noteContent = trimmed
              .replaceFirst(RegExp(r'^(take\s+a\s+note(\s+that)?|note\s+down|write\s+a\s+note(\s+that)?|zapiš\s+poznámku)\s*[:\s]*', caseSensitive: false), '')
              .trim();
          if (noteContent.isEmpty) noteContent = 'Osobní poznámka';
          await NotesKnowledgeService.instance.addNote(
            title: 'Hlasová poznámka ${DateTime.now().day}. ${DateTime.now().month}.',
            content: noteContent,
          );
          final reply = 'Poznámka byla uložena do vaší osobní znalostní databáze, pane: „$noteContent“.';
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'ZNALOSTNÍ ZÁZNAM ULOŽEN';
          notifyListeners();
          await _voice.speak(reply);
        } else {
          final reply = NotesKnowledgeService.instance.searchNotesSpoken(trimmed);
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'VYHLEDÁVÁNÍ V POZNÁMKÁCH';
          notifyListeners();
          await _voice.speak(reply);
        }
        break;

      case JarvisIntentType.calendar:
        final lower = trimmed.toLowerCase();
        if (lower.startsWith('remind me to ') ||
            lower.startsWith('set a reminder for ') ||
            lower.startsWith('připomeň mi ')) {
          final reminderText = trimmed
              .replaceFirst(RegExp(r'^(remind\s+me\s+to|set\s+a\s+reminder\s+for|připomeň\s+mi)\s+', caseSensitive: false), '')
              .trim();
          await CalendarReminderService.instance.addItem(
            title: reminderText,
            dateTime: DateTime.now().add(const Duration(hours: 1)),
            isReminder: true,
          );
          final reply = 'Nastavil jsem připomenutí pro „$reminderText“, pane.';
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'PŘIPOMENUTÍ NAPLÁNOVÁNO';
          notifyListeners();
          await _voice.speak(reply);
        } else {
          final reply = CalendarReminderService.instance.getTodayBriefingSpoken();
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'ROZVRH KALENDÁŘE';
          notifyListeners();
          await _voice.speak(reply);
        }
        break;

      case JarvisIntentType.email:
        final lowerEmail = trimmed.toLowerCase();
        final isInboxCheck = lowerEmail.contains('read') ||
            lowerEmail.contains('check') ||
            lowerEmail.contains('inbox') ||
            lowerEmail.contains('what are') ||
            lowerEmail.contains('new') ||
            lowerEmail.contains('recent') ||
            lowerEmail.contains('přečti') ||
            lowerEmail.contains('zkontroluj');

        String emailReply;
        if (isInboxCheck) {
          emailReply = await InboxService.instance.getEmailSummary();
        } else {
          final triage = await EmailTriageService.instance.triageEmail(trimmed);
          emailReply = '${triage.summary} Priorita je označena jako ${triage.priority.name}. Mám pro vás otevřít koncept odpovědi, pane?';
        }

        _lastJarvisSpeech = emailReply;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'E-MAILOVÁ SCHRÁNKA ZPRACOVÁNA';
        notifyListeners();
        await _voice.speak(emailReply);
        break;

      case JarvisIntentType.message:
        final lowerMsg = trimmed.toLowerCase();
        final isSmsCheck = lowerMsg.contains('read') ||
            lowerMsg.contains('check') ||
            lowerMsg.contains('inbox') ||
            lowerMsg.contains('what are') ||
            lowerMsg.contains('recent message') ||
            lowerMsg.contains('new message') ||
            lowerMsg.contains('read my sms') ||
            lowerMsg.contains('přečti') ||
            lowerMsg.contains('zkontroluj');

        if (isSmsCheck) {
          final smsReply = await InboxService.instance.getSmsSummary();
          _lastJarvisSpeech = smsReply;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'SMS SCHRÁNKA ZPRACOVÁNA';
          notifyListeners();
          await _voice.speak(smsReply);
        } else {
          final draftText = await MessageDraftingService.instance.draftMessageContent(prompt: trimmed);
          final reply = 'Připravil jsem pro vás tento koncept zprávy, pane: „$draftText“. Mám jej odeslat?';
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          _statusMessage = 'KONCEPT ZPRÁVY PŘIPRAVEN';
          notifyListeners();
          await _voice.speak(reply);
          await MessageDraftingService.instance.dispatchDraft(
            MessageDraft(
              channel: trimmed.toLowerCase().contains('whatsapp') ? MessageChannel.whatsapp : MessageChannel.sms,
              recipient: '',
              body: draftText,
            ),
          );
        }
        break;

      case JarvisIntentType.vision:
        final isScreen = trimmed.toLowerCase().contains('screen') || trimmed.toLowerCase().contains('obrazov');
        final ack = isScreen
            ? 'Skenuji prvky aktivní obrazovky, pane.'
            : 'Optické senzory Oka Jarvise jsou aktivní, pane. Nyní zkoumám objekt.';
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'OPTICKÉ SENZORY AKTIVNÍ';
        notifyListeners();
        await _voice.speak(ack);

        final analysis = isScreen
            ? await ProactiveAgentService.instance.analyzeCurrentScreen(userQuestion: trimmed)
            : (await VisionPerceptionService.instance.inspectOpticalSnapshot(customPrompt: trimmed)).spokenSummary;

        _lastJarvisSpeech = analysis;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'OPTICKÝ SKEN DOKONČEN';
        notifyListeners();
        await _voice.speak(analysis);
        break;

      case JarvisIntentType.smartHome:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'CHYTRÁ DOMÁCNOST IOT // ODESÍLÁM';
        notifyListeners();

        final reply = await SmartHomeService.instance.handleVoiceCommand(trimmed);
        _lastJarvisSpeech = reply;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'CHYTRÁ DOMÁCNOST AKTIVNÍ';
        notifyListeners();
        await _voice.speak(reply);
        break;

      case JarvisIntentType.commute:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'VÝPOČET // TELEMETRIE DOJÍŽDĚNÍ A DOPRAVY';
        notifyListeners();

        final commute = await CommuteTrafficService.instance.checkCommute(destination: intent.toolArg);
        _lastJarvisSpeech = commute.spokenSummary;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'DOPRAVNÍ HLÁŠENÍ';
        notifyListeners();
        await _voice.speak(commute.spokenSummary);
        break;

      case JarvisIntentType.macro:
        final lowerMacro = trimmed.toLowerCase();
        if (lowerMacro.startsWith('stop recording') ||
            lowerMacro.startsWith('save macro') ||
            lowerMacro.startsWith('ulož makro')) {
          final skill = await MacroRecorderService.instance.stopRecording();
          final reply = skill != null
              ? 'Makro „${skill.goal}“ bylo uloženo a zapsáno do AGENT.md, pane.'
              : 'Nahrávání makra bylo ukončeno, pane.';
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          notifyListeners();
          await _voice.speak(reply);
        } else if (lowerMacro.startsWith('run macro') ||
            lowerMacro.startsWith('replay macro') ||
            lowerMacro.startsWith('spusť makro')) {
          final macroName = trimmed.replaceFirst(RegExp(r'^(run|replay|spusť)\s+(macro|makro)\s+', caseSensitive: false), '').trim();
          final match = await SkillMemoryService.instance.findMatch(macroName);
          if (match != null) {
            final reply = 'Přehrávám makro „${match.goal}“, pane.';
            _lastJarvisSpeech = reply;
            _phase = JarvisPhase.speaking;
            notifyListeners();
            await _voice.speak(reply);
            await MacroRecorderService.instance.replaySkill(match);
          } else {
            final reply = 'Pro „$macroName“ nebylo nalezeno žádné odpovídající makro, pane.';
            _lastJarvisSpeech = reply;
            _phase = JarvisPhase.speaking;
            notifyListeners();
            await _voice.speak(reply);
          }
        } else {
          final goal = intent.toolArg ?? 'Vlastní úloha';
          await MacroRecorderService.instance.startRecording(goal);
          final reply = 'Nahrávání makra pro „$goal“ bylo zahájeno, pane. Proveďte požadované akce a poté řekněte „ulož makro“.';
          _lastJarvisSpeech = reply;
          _phase = JarvisPhase.speaking;
          notifyListeners();
          await _voice.speak(reply);
        }
        break;

      case JarvisIntentType.airGestures:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'SENZORICKÁ MATICE VZDUŠNÝCH GEST';
        notifyListeners();
        final raw = (intent.toolArg ?? trimmed).toLowerCase();
        final isOff = raw.contains('off') ||
            raw.contains('disable') ||
            raw.contains('deactivat') ||
            raw.contains('stop') ||
            raw.contains('vypni');
        String gestureReply;
        if (isOff) {
          await AirGestureService.instance.stop();
          gestureReply = 'Bezdotykové senzory vzdušných gest Iron Mana byly odpojeny, pane.';
        } else {
          await AirGestureService.instance.start();
          gestureReply =
              'Bezdotyková vzdušná gesta jsou aktivní, pane. Mávnutím nad obrazovkou přeskočíte skladby, podržením dlaně pozastavíte přehrávání a dvojitým mávnutím pořídíte okamžitý snímek obrazovky.';
        }
        _lastJarvisSpeech = gestureReply;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(gestureReply);
        break;

      case JarvisIntentType.chargingTelemetry:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'TELEMETRIE NABÍJENÍ OBLOUKOVÉHO REAKTORU';
        notifyListeners();
        ChargingTelemetryService.instance.showCinematicHud.value = true;
        final chargingReport = await ChargingTelemetryService.instance.getSpokenTelemetry();
        _lastJarvisSpeech = chargingReport;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(chargingReport);
        break;

      case JarvisIntentType.polyglotDiplomat:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'POLYGLOTNÍ DIPLOMAT // PŘEKLAD';
        notifyListeners();
        _showModalSafely(const PolyglotDiplomatDialog());
        const transAck =
            'Polyglotní diplomat je inicializován, pane. Připraven na diplomatický překlad v reálném čase.';
        _lastJarvisSpeech = transAck;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(transAck);
        break;

      case JarvisIntentType.codeBlack:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'ČERNÝ KÓD // HARDWAROVÉ UZAMČENÍ';
        notifyListeners();
        await CodeBlackService.instance.arm();
        _phase = JarvisPhase.idle;
        notifyListeners();
        break;

      case JarvisIntentType.floatingCopilot:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'HOLOGRAFICKÝ PLOVOUCÍ KOPILOT';
        notifyListeners();
        final rawCopilot = (intent.toolArg ?? trimmed).toLowerCase();
        final isHide = rawCopilot.contains('hide') ||
            rawCopilot.contains('close') ||
            rawCopilot.contains('stop') ||
            rawCopilot.contains('dismiss') ||
            rawCopilot.contains('skryj') ||
            rawCopilot.contains('vypni');
        String copilotReply;
        if (isHide) {
          await FloatingCopilotService.instance.hideOverlay();
          copilotReply = 'Plovoucí kopilot byl skryt, pane.';
        } else {
          await FloatingCopilotService.instance.activateOverlay();
          copilotReply =
              'Holografický plovoucí kopilot je aktivní, pane. Vznáší se nad aktivními aplikacemi s živou kontextovou analýzou obrazovky.';
        }
        _lastJarvisSpeech = copilotReply;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(copilotReply);
        break;

      case JarvisIntentType.airspaceRadar:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'RADAR VZDUŠNÉHO PROSTORU A SATELITŮ';
        notifyListeners();
        _showModalSafely(const AirspaceRadarDialog());
        final radarReport = await AirspaceRadarService.instance.getSpokenAirspaceReport();
        _lastJarvisSpeech = radarReport;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(radarReport);
        break;

      case JarvisIntentType.multiTaskDump:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'VÍCEÚLOHOVÝ ROZKLADAČ';
        notifyListeners();
        final decoupledReport = await MultiTaskDecouplerService.instance.processBrainDump(trimmed);
        _lastJarvisSpeech = decoupledReport;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(decoupledReport);
        break;

      case JarvisIntentType.opticalSolver:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'OPTICKÝ HUD ŘEŠITEL V REÁLNÉM ČASE';
        notifyListeners();
        _showModalSafely(const OpticalSolverDialog());
        final solveResult =
            await OpticalSolverService.instance.pointAndSolve(customQuery: trimmed);
        _lastJarvisSpeech = solveResult.spokenSummary;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(solveResult.spokenSummary);
        break;

      case JarvisIntentType.networkAudit:
        _phase = JarvisPhase.thinking;
        _statusMessage = 'BEZPEČNOSTNÍ AUDIT SÍTĚ';
        notifyListeners();
        _showModalSafely(const NetworkAuditDialog());
        final netReport = await NetworkAuditService.instance.getSpokenAuditReport();
        _lastJarvisSpeech = netReport;
        _phase = JarvisPhase.speaking;
        notifyListeners();
        await _voice.speak(netReport);
        break;

      case JarvisIntentType.multistep:
        const ack = 'Zahajuji pro vás vícekrokový prováděcí protokol, pane.';
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'VÍCEKROKOVÝ PROTOKOL';
        notifyListeners();
        await _voice.speak(ack);

        final steps = await ProactiveAgentService.instance.planMultiStepGoal(trimmed);
        final planSpoken = 'Rozdělil jsem tento cíl do ${steps.length} po sobě jdoucích kroků, pane: ${steps.join("; ")}. Nyní zahajuji první krok.';
        _lastJarvisSpeech = planSpoken;
        notifyListeners();
        await _voice.speak(planSpoken);
        break;

      case JarvisIntentType.system:
        await _handleSystemCommand(intent.systemCommand ?? '', intent.spoken);
        break;

      case JarvisIntentType.action:
        final goal = intent.actionGoal ?? trimmed;

        // Foundation: Permission system check before risky actions
        if (SettingsService.instance.confirmRiskyActions) {
          final assessment = SecurityAlertService.instance.evaluateActionRisk(goal);
          if (assessment.requiresConfirmation) {
            final confirmPrompt = 'Pane, tato akce zahrnuje vysoce rizikové operace: ${assessment.reason}. Potvrzujete její provedení?';
            _lastJarvisSpeech = confirmPrompt;
            _phase = JarvisPhase.speaking;
            _statusMessage = 'VYŽADOVÁNO POTVRZENÍ // VYSOKÉ RIZIKO';
            notifyListeners();
            await _voice.speak(confirmPrompt);
            await SecurityAlertService.instance.dispatchSecurityAlert('Vyžádána vysoce riziková operace: $goal');
            return;
          }
        }

        _currentTaskGoal = goal;
        final ack = intent.spoken.isNotEmpty
            ? intent.spoken
            : 'Ihned, pane. Postarám se o to na vašem zařízení.';
        _lastJarvisSpeech = ack;
        _phase = JarvisPhase.speaking;
        _statusMessage = 'PROTOKOL AKTIVOVÁN // $goal'.toUpperCase();
        notifyListeners();

        // 1. Speak acknowledgment completely
        await _voice.speak(ack);

        // 2. Execute automation task on device
        _phase = JarvisPhase.executing;
        notifyListeners();
        final status = await _executor.executeTask(goal);

        // 3. Deliver completion with caring follow-up
        _phase = JarvisPhase.speaking;
        if (status == TaskStatus.success) {
          const successSpeech = 'Tento úkol jsem pro vás dokončil, pane. Potřebujete ještě něco dalšího?';
          _lastJarvisSpeech = successSpeech;
          _statusMessage = 'PROTOKOL DOKONČEN // ÚSPĚCH';
          notifyListeners();
          await _voice.speak(successSpeech);
        } else if (status == TaskStatus.cancelled) {
          const cancelledSpeech = 'Úkol byl zrušen, pane. Co si přejete udělat místo toho?';
          _lastJarvisSpeech = cancelledSpeech;
          _statusMessage = 'PROTOKOL ZRUŠEN';
          notifyListeners();
          await _voice.speak(cancelledSpeech);
        } else {
          const failedSpeech =
              'Při plnění tohoto úkolu na obrazovce jsem narazil na překážku, pane. Mám to zkusit znovu?';
          _lastJarvisSpeech = failedSpeech;
          _statusMessage = 'PROTOKOL SELHAL';
          notifyListeners();
          await _voice.speak(failedSpeech);
        }
        break;

      case JarvisIntentType.chat:
        final role = _ai.classifyConversationRole(trimmed);
        final targetModel = SettingsService.instance.effectiveModelForRole(role);
        final roleBadge = SettingsService.roleShortBadge(role);
        String chatAnswer = intent.spoken;
        if (chatAnswer.trim().isEmpty ||
            chatAnswer.toLowerCase().contains('at your service') ||
            chatAnswer.toLowerCase().contains('k vašim službám') ||
            chatAnswer.toLowerCase().contains('what would you like me to do')) {
          _phase = JarvisPhase.thinking;
          _statusMessage = '$roleBadge // MODEL: ${targetModel.toUpperCase()}';
          notifyListeners();
          try {
            chatAnswer = await _ai.liveVoiceChat(
              message: trimmed,
              history: _dialogHistory,
            );
          } catch (_) {
            chatAnswer = 'Slyším vás, pane. Jak na to navážeme?';
          }
        }
        _dialogHistory.add({'role': 'user', 'content': trimmed});
        _dialogHistory.add({'role': 'assistant', 'content': chatAnswer});
        if (_dialogHistory.length > 20) {
          _dialogHistory.removeRange(0, 2);
        }
        _lastJarvisSpeech = chatAnswer;
        _phase = JarvisPhase.speaking;
        final activeModel = _ai.lastUsedModel.toUpperCase();
        _statusMessage = 'ŽIVÝ ROZHOVOR // $activeModel';
        notifyListeners();
        await _voice.speak(chatAnswer);
        break;
    }

    // Persist conversation turn and auto-extract user preferences/facts across sessions
    unawaited(ConversationalMemoryService.instance.recordTurn(trimmed, _lastJarvisSpeech));

    // Follow-up hands-free continuous listening
    await _startFollowUpListening();
  }

  Future<void> _handleSystemCommand(String cmd, String spoken) async {
    final speech = spoken.isNotEmpty ? spoken : PersonalityService.instance.getGeneralAck();
    _lastJarvisSpeech = speech;
    _phase = JarvisPhase.speaking;
    _statusMessage = 'SYSTÉMOVÉ PŘEPSÁNÍ // $cmd'.toUpperCase();
    notifyListeners();

    await _voice.speak(speech);

    switch (cmd) {
      case 'volume_up':
        await _system.volumeUp();
        break;
      case 'volume_down':
        await _system.volumeDown();
        break;
      case 'mute':
        await _system.setMuted(true);
        break;
      case 'unmute':
        await _system.setMuted(false);
        break;
      case 'brightness_up':
        final current = await _system.getBrightness() ?? 0.5;
        await _system.setBrightness((current + 0.2).clamp(0.0, 1.0));
        break;
      case 'brightness_down':
        final current = await _system.getBrightness() ?? 0.5;
        await _system.setBrightness((current - 0.2).clamp(0.0, 1.0));
        break;
      case 'screenshot':
        await _automation.takeScreenshotBase64();
        break;
      case 'home':
        await _automation.pressHome();
        break;
      case 'back':
        await _automation.pressBack();
        break;
    }

    if (_shouldListenContinuously) {
      _standDown();
    }
  }

  /// Resolves the exact top YouTube video ID for instant playback without search friction.
  Future<String?> _resolveTopYouTubeVideoId(String query) async {
    try {
      final url = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
      );
      final resp = await http.get(url, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      }).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final match =
            RegExp(r'watch\?v=([a-zA-Z0-9_-]{11})').firstMatch(resp.body);
        if (match != null) {
          return match.group(1);
        }
      }
    } catch (e) {
      debugPrint('[JarvisService] YouTube top video lookup error: $e');
    }
    return null;
  }
}
