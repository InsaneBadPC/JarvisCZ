import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'ai_service.dart';
import 'calendar_reminder_service.dart';
import 'commute_traffic_service.dart';
import 'conversational_memory_service.dart';
import 'jarvis_service.dart';
import 'jarvis_tools_service.dart';
import 'screen_automation_service.dart';
import 'settings_service.dart';
import 'todo_service.dart';

class ProactiveSuggestion {
  final String id;
  final String title;
  final String description;
  final String actionGoal;
  final String spokenPrompt;
  final String actionLabel;
  final DateTime timestamp;

  const ProactiveSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.actionGoal,
    required this.spokenPrompt,
    this.actionLabel = 'Provést',
    required this.timestamp,
  });
}

/// Advanced Jarvis-level intelligence:
/// - Proactive autonomous suggestions & scheduled voice prompts.
/// - Anticipates user needs based on temporal, calendar & battery context.
/// - Hands-free conversational confirmation daemon.
/// - Continuous preference learning.
/// - Multi-step agentic task planning.
/// - Vision: Screen & UI visual understanding.
class ProactiveAgentService extends ChangeNotifier {
  ProactiveAgentService._();
  static final ProactiveAgentService instance = ProactiveAgentService._();

  ProactiveSuggestion? _currentSuggestion;
  ProactiveSuggestion? get currentSuggestion => _currentSuggestion;

  Timer? _monitorTimer;
  DateTime? _lastProactiveSpokenTime;
  final Set<String> _spokenDeduplicationIds = {};

  bool get isMonitoring => _monitorTimer != null;

  /// Starts the autonomous periodic monitor daemon (runs every 45 seconds).
  void startProactiveMonitor({Duration interval = const Duration(seconds: 45)}) {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(interval, (_) {
      unawaited(checkAndTriggerProactiveAlert());
    });
  }

  /// Stops the periodic monitor daemon.
  void stopProactiveMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// Clears deduplication cache (useful for testing or day transitions).
  void clearDeduplicationHistory() {
    _spokenDeduplicationIds.clear();
    _lastProactiveSpokenTime = null;
  }

  /// Evaluates context to generate an intelligent proactive recommendation.
  /// Optional [nowOverride] allows deterministic unit testing across any hour of the day.
  Future<ProactiveSuggestion?> evaluateProactiveNeeds({DateTime? nowOverride}) async {
    final now = nowOverride ?? DateTime.now();

    // 1. Proactive Meeting Commute Departure Warning (High urgency)
    if (SettingsService.instance.proactiveCommuteEnabled) {
      try {
        final commute = await CommuteTrafficService.instance.checkUpcomingMeetingCommute();
        if (commute != null && commute.isUrgent) {
          final dedupId = 'commute_${commute.destination}';
          _currentSuggestion = ProactiveSuggestion(
            id: dedupId,
            title: 'Upozornění na odjezd: ${commute.destination}',
            description: commute.spokenSummary,
            actionGoal: 'Check traffic',
            spokenPrompt: commute.spokenSummary,
            actionLabel: 'Zobrazit trasu',
            timestamp: now,
          );
          notifyListeners();
          return _currentSuggestion;
        }
      } catch (_) {}
    }

    // 2. Upcoming Meeting / Calendar Alert (15 - 30 minutes prior)
    if (SettingsService.instance.proactiveMeetingReminders) {
      try {
        final calendarItems = CalendarReminderService.instance.items;
        final upcomingMeetings = calendarItems.where((item) {
          if (item.isCompleted) return false;
          final diff = item.dateTime.difference(now).inMinutes;
          return diff >= 0 && diff <= 30;
        }).toList();

        if (upcomingMeetings.isNotEmpty) {
          final meeting = upcomingMeetings.first;
          final timeStr = DateFormat('HH:mm').format(meeting.dateTime);
          final hasLoc = meeting.location != null && meeting.location!.trim().isNotEmpty;
          final spoken = hasLoc
              ? "Omlouvám se za vyrušení, pane. V $timeStr máte nadcházející událost ‚${meeting.title}‘ v lokalitě ${meeting.location}. Přejete si zkontrolovat dopravu a navigaci?"
              : "Omlouvám se za vyrušení, pane. V $timeStr máte naplánovanou událost ‚${meeting.title}‘. Mám pro vás připravit stručný přehled?";

          final dedupId = 'meeting_${meeting.id}';
          _currentSuggestion = ProactiveSuggestion(
            id: dedupId,
            title: 'Nadcházející schůzka: ${meeting.title}',
            description: 'Naplánováno na $timeStr${hasLoc ? ' (${meeting.location})' : ''}, pane.',
            actionGoal: hasLoc ? 'Check traffic' : 'Show calendar',
            spokenPrompt: spoken,
            actionLabel: 'Zobrazit',
            timestamp: now,
          );
          notifyListeners();
          return _currentSuggestion;
        }
      } catch (_) {}
    }

    // 3. Critical Battery check (< 20%)
    if (SettingsService.instance.proactiveBatteryAlert) {
      try {
        final battery = await JarvisToolsService.instance.getBatteryStatus();
        final level = battery['level'] as int;
        final isCharging = battery['isCharging'] as bool;
        if (level > 0 && level <= 20 && !isCharging) {
          final dedupId = 'battery_${now.year}_${now.month}_${now.day}_${level <= 10 ? '10' : '20'}';
          _currentSuggestion = ProactiveSuggestion(
            id: dedupId,
            title: 'Kritický stav baterie ($level %)',
            description: 'Zásoby energie jsou nízké, pane. Přejete si zapnout spořič baterie?',
            actionGoal: 'Turn on battery saver',
            spokenPrompt: 'Pane, zásoby energie klesly na $level procent. Mám aktivovat spořič baterie pro zachování provozu?',
            actionLabel: 'Spořič baterie',
            timestamp: now,
          );
          notifyListeners();
          return _currentSuggestion;
        }
      } catch (_) {}
    }

    // 4. Night Mode / Sleep Protocol check (Between 9 PM and 3 AM)
    if (SettingsService.instance.proactiveNightModePrompt) {
      if (now.hour >= 21 || now.hour < 3) {
        final dedupId = 'night_prompt_${now.year}_${now.month}_${now.day}';
        _currentSuggestion = ProactiveSuggestion(
          id: dedupId,
          title: 'Noční režim k dispozici',
          description: 'Je pokročilý večer, pane. Mám aktivovat noční protokol a připravit vaše prostředí ke spánku?',
          actionGoal: 'turn on night mode',
          spokenPrompt: 'Je pokročilá noční hodina, pane. Mám zapnout noční režim?',
          actionLabel: 'Zapnout',
          timestamp: now,
        );
        notifyListeners();
        return _currentSuggestion;
      }
    }

    // 5. Study & Focus Protocol check (Afternoon focus block: 2 PM - 4:59 PM)
    if (SettingsService.instance.proactiveStudyPrompt) {
      if (now.hour >= 14 && now.hour <= 16) {
        final dedupId = 'study_prompt_${now.year}_${now.month}_${now.day}';
        _currentSuggestion = ProactiveSuggestion(
          id: dedupId,
          title: 'Studijní a soustředěný režim',
          description: 'Čas na odpolední blok soustředění. Jsem připraven ztlumit rušivé vlivy a upravit jas, pane.',
          actionGoal: 'study mode',
          spokenPrompt: 'Pane, nastal čas na váš odpolední blok soustředění. Mám aktivovat studijní protokol a ztlumit rušivé elementy?',
          actionLabel: 'Aktivovat',
          timestamp: now,
        );
        notifyListeners();
        return _currentSuggestion;
      }
    }

    // 6. Pending high-priority / remaining tasks check (Evening review: 5 PM - 8:59 PM)
    if (SettingsService.instance.proactiveTaskReminderPrompt) {
      if (now.hour >= 17 && now.hour <= 20) {
        final pendingTodos = TodoService.instance.pendingItems;
        if (pendingTodos.isNotEmpty) {
          final top = pendingTodos.where((t) => t.priority == TodoPriority.high).firstOrNull ?? pendingTodos.first;
          final count = pendingTodos.length;
          final taskWord = count == 1 ? 'úkol' : (count >= 2 && count <= 4 ? 'úkoly' : 'úkolů');
          final dedupId = 'todo_prompt_${now.year}_${now.month}_${now.day}';
          _currentSuggestion = ProactiveSuggestion(
            id: dedupId,
            title: '$count nevyřízené $taskWord na programu',
            description: 'Připomínka: „${top.title}“ vyžaduje vaši pozornost, pane.',
            actionGoal: 'Show my tasks',
            spokenPrompt: "Pane, na dnešním programu vám zbývá $count $taskWord, včetně ‚${top.title}‘. Mám vám přečíst seznam nevyřízených úkolů?",
            actionLabel: 'Zobrazit úkoly',
            timestamp: now,
          );
          notifyListeners();
          return _currentSuggestion;
        }
      }
    }

    // 7. Morning Routine check (Between 7 AM and 9:59 AM)
    if (SettingsService.instance.proactiveMorningBriefingPrompt) {
      if (now.hour >= 7 && now.hour <= 9) {
        final dedupId = 'morning_prompt_${now.year}_${now.month}_${now.day}';
        _currentSuggestion = ProactiveSuggestion(
          id: dedupId,
          title: 'Ranní přehled připraven',
          description: 'Připraven přednést počasí, rozvrh a dnešní hlavní zprávy, pane.',
          actionGoal: 'Good morning',
          spokenPrompt: 'Dobré ráno, pane. Přejete si vyslechnout ranní přehled s dnešním počasím, rozvrhem a hlavními zprávami?',
          actionLabel: 'Přehled',
          timestamp: now,
        );
        notifyListeners();
        return _currentSuggestion;
      }
    }

    _currentSuggestion = null;
    notifyListeners();
    return null;
  }

  /// Evaluates triggers and autonomously vocalizes proactive prompts when appropriate.
  Future<void> checkAndTriggerProactiveAlert({bool forceSpeak = false}) async {
    final suggestion = await evaluateProactiveNeeds();
    if (suggestion == null) return;

    // Check master auto-speak preference
    if (!SettingsService.instance.jarvisAutoSpeakEnabled && !forceSpeak) {
      return;
    }

    // Deduplication check: avoid repeating the same prompt in the same cycle
    if (_spokenDeduplicationIds.contains(suggestion.id) && !forceSpeak) {
      return;
    }

    // Minimum cooldown check: at least 15 minutes between auto-spoken prompts
    if (!forceSpeak && _lastProactiveSpokenTime != null) {
      final elapsed = DateTime.now().difference(_lastProactiveSpokenTime!).inMinutes;
      if (elapsed < 15) {
        return;
      }
    }

    // Jarvis state check: only speak if system is idle (never interrupt user speech or tasks)
    if (JarvisService.instance.phase != JarvisPhase.idle && !forceSpeak) {
      return;
    }

    _spokenDeduplicationIds.add(suggestion.id);
    _lastProactiveSpokenTime = DateTime.now();

    // Trigger proactive speech and hands-free conversational confirmation window
    await JarvisService.instance.proactivelySpeakAndAwaitConfirmation(suggestion);
  }

  /// Triggers a test proactive prompt for user verification from settings or testing.
  Future<void> testProactivePrompt(String type) async {
    final now = DateTime.now();
    ProactiveSuggestion suggestion;
    switch (type.toLowerCase()) {
      case 'night':
        suggestion = ProactiveSuggestion(
          id: 'test_night_${now.millisecondsSinceEpoch}',
          title: 'Výzva nočního režimu (Test)',
          description: 'Je pokročilý večer, pane. Mám aktivovat noční protokol a připravit prostředí ke spánku?',
          actionGoal: 'turn on night mode',
          spokenPrompt: 'Je pokročilá noční hodina, pane. Mám zapnout noční režim?',
          actionLabel: 'Zapnout',
          timestamp: now,
        );
        break;
      case 'study':
        suggestion = ProactiveSuggestion(
          id: 'test_study_${now.millisecondsSinceEpoch}',
          title: 'Studijní protokol (Test)',
          description: 'Připraven ztlumit rušivé vlivy a upravit jas obrazovky, pane.',
          actionGoal: 'study mode',
          spokenPrompt: 'Pane, nastal čas na váš odpolední blok soustředění. Mám aktivovat studijní protokol a ztlumit rušivé elementy?',
          actionLabel: 'Aktivovat',
          timestamp: now,
        );
        break;
      case 'meeting':
        suggestion = ProactiveSuggestion(
          id: 'test_meeting_${now.millisecondsSinceEpoch}',
          title: 'Nadcházející schůzka: Produktová revize (Test)',
          description: 'Naplánováno na 10:30 v zasedací místnosti B.',
          actionGoal: 'show calendar',
          spokenPrompt: "Omlouvám se za vyrušení, pane. V 10:30 máte naplánovanou schůzku ‚Produktová revize‘. Přejete si připravit podklady?",
          actionLabel: 'Zobrazit',
          timestamp: now,
        );
        break;
      case 'todo':
      case 'tasks':
        suggestion = ProactiveSuggestion(
          id: 'test_todo_${now.millisecondsSinceEpoch}',
          title: '3 zbývající úkoly na programu (Test)',
          description: 'Nevyřízeno: „Dokončit klientský návrh“ a 2 další.',
          actionGoal: 'show my tasks',
          spokenPrompt: "Pane, na dnešním programu vám zbývají 3 úkoly, včetně ‚Dokončit klientský návrh‘. Mám vám přečíst seznam nevyřízených úkolů?",
          actionLabel: 'Zobrazit úkoly',
          timestamp: now,
        );
        break;
      case 'morning':
        suggestion = ProactiveSuggestion(
          id: 'test_morning_${now.millisecondsSinceEpoch}',
          title: 'Ranní přehled (Test)',
          description: 'Počasí, rozvrh a hlavní zprávy jsou připraveny, pane.',
          actionGoal: 'good morning',
          spokenPrompt: 'Dobré ráno, pane. Přejete si vyslechnout ranní přehled s dnešním počasím, rozvrhem a hlavními zprávami?',
          actionLabel: 'Přehled',
          timestamp: now,
        );
        break;
      case 'battery':
      default:
        suggestion = ProactiveSuggestion(
          id: 'test_battery_${now.millisecondsSinceEpoch}',
          title: 'Kritický stav baterie (18 %) (Test)',
          description: 'Zásoby energie jsou nízké, pane. Přejete si zapnout spořič baterie?',
          actionGoal: 'turn on battery saver',
          spokenPrompt: 'Pane, zásoby energie klesly na 18 procent. Mám aktivovat spořič baterie pro zachování provozu?',
          actionLabel: 'Spořič baterie',
          timestamp: now,
        );
        break;
    }

    _currentSuggestion = suggestion;
    notifyListeners();
    await JarvisService.instance.proactivelySpeakAndAwaitConfirmation(suggestion);
  }

  void dismissSuggestion() {
    _currentSuggestion = null;
    if (JarvisService.instance.isAwaitingProactiveConfirmation) {
      JarvisService.instance.dismissProactiveConfirmation();
    }
    notifyListeners();
  }

  /// Multi-step agentic decomposition: breaks down complex goals into actionable sub-steps.
  Future<List<String>> planMultiStepGoal(String highLevelGoal) async {
    final prompt = '''
Jsi autonomní AI náčelník štábu (J.A.R.V.I.S.).
Rozděl tento vysokoúrovňový cíl uživatele na 3 až 5 jasných, po sobě jdoucích proveditelných kroků v češtině s plnou diakritikou:
"$highLevelGoal"

Vypiš POUZE JSON pole řetězců:
["Krok 1: ...", "Krok 2: ...", "Krok 3: ..."]
''';

    try {
      final raw = await AiService.instance.chat(message: prompt);
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final decoded = jsonDecode(raw.substring(start, end + 1));
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    return [
      '1. Analyzovat požadavky pro: $highLevelGoal',
      '2. Připravit podrobný postup a jednotlivé kroky',
      '3. Naplánovat připomínky v kalendáři pro provedení',
    ];
  }

  /// Vision: Analyzes current screen UI hierarchy and captures screenshot to explain what is visible.
  Future<String> analyzeCurrentScreen({String? userQuestion}) async {
    final automation = ScreenAutomationService.instance;
    final isOnline = await automation.isServiceEnabled();
    if (!isOnline) {
      return 'Služba usnadnění přístupu pro automatizaci obrazovky je momentálně vypnutá, pane. Povolte ji prosím v Nastavení, abych mohl sledovat vaši obrazovku.';
    }

    final dump = await automation.dumpScreen();
    if (dump.isEmpty) {
      return 'Aktivní obrazovka se v tuto chvíli zdá být prázdná nebo nepřístupná, pane.';
    }

    final query = userQuestion?.trim().isNotEmpty == true
        ? userQuestion!
        : 'Popiš aktuální obrazovku a jaké možnosti akcí jsou viditelné.';

    final prompt = '''
Jsi J.A.R.V.I.S. Prohlížíš aktivní obrazovku chytrého telefonu Android uživatele.
Aktuální výpis hierarchie UI obrazovky:
$dump

Dotaz uživatele: "$query"

Vysvětli jasně a stručně v přirozené mluvené češtině s plnou diakritikou (2 až 3 věty), co je na obrazovce a co může uživatel udělat dál. Vždy oslovuj uživatele jako „pane“.
''';

    try {
      final reply = await AiService.instance.chat(message: prompt);
      return reply.trim();
    } catch (_) {
      return 'Vidím prvky na aktivní obrazovce, pane. Dejte mi vědět, jakou konkrétní akci si přejete provést.';
    }
  }

  /// Continuous learning: learns user preferences from actions taken.
  Future<void> recordObservedPreference(String preferenceKey, String value) async {
    final fact = 'User preference: $preferenceKey is "$value"';
    await ConversationalMemoryService.instance.addFact(fact, category: 'preference');
  }
}
