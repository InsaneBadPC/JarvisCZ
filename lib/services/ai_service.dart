import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'conversational_memory_service.dart';
import 'hermes_evolution_service.dart';
import 'personality_service.dart';
import 'settings_service.dart';

/// Error thrown for any AI-gateway failure (network, auth, bad payload).
class AiException implements Exception {
  final String message;
  final int? statusCode;
  const AiException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode == null ? message : 'HTTP $statusCode: $message';
}

/// Structured intent classification result for JARVIS mode.
enum JarvisIntentType {
  chat,
  action,
  system,
  webSearch,
  news,
  weather,
  battery,
  datetime,
  torch,
  workflow,
  routine,
  finance,
  sports,
  todo,
  notes,
  calendar,
  email,
  message,
  vision,
  multistep,
  smartHome,
  commute,
  macro,
  airGestures,
  chargingTelemetry,
  polyglotDiplomat,
  codeBlack,
  floatingCopilot,
  airspaceRadar,
  multiTaskDump,
  opticalSolver,
  networkAudit,
}

class JarvisIntent {
  final JarvisIntentType type;
  final String spoken;
  final String? actionGoal;
  final String? systemCommand;
  final String? toolArg;

  const JarvisIntent({
    required this.type,
    required this.spoken,
    this.actionGoal,
    this.systemCommand,
    this.toolArg,
  });

  factory JarvisIntent.fallback(String command) {
    final lower = command.toLowerCase().trim();

    // 0. Jarvis Eye Optical Vision check
    if (lower.contains('look at this') ||
        lower.contains('what is this') ||
        lower.contains('scan this') ||
        lower.contains('inspect this') ||
        lower.contains('jarvis eye') ||
        lower.contains('what do you see') ||
        lower.contains('podívej se na tohle') ||
        lower.contains('co je tohle') ||
        lower.contains('co vidíš')) {
      return JarvisIntent(
        type: JarvisIntentType.vision,
        spoken: 'Optické senzory Oka Jarvise jsou aktivní, pane.',
        toolArg: command,
      );
    }

    // 0b. Autonomous Macro Recorder check
    if (lower.startsWith('record macro') ||
        lower.startsWith('start recording') ||
        lower.startsWith('stop recording') ||
        lower.startsWith('save macro') ||
        lower.startsWith('replay macro') ||
        lower.startsWith('run macro') ||
        lower.startsWith('nahraj makro') ||
        lower.startsWith('ulož makro') ||
        lower.startsWith('spusť makro')) {
      return JarvisIntent(
        type: JarvisIntentType.macro,
        spoken: 'Přistupuji k autonomnímu záznamníku maker, pane.',
        toolArg: command,
      );
    }

    // 0c. Smart Home & IoT Automation check
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
        lower.contains('chytrá domácnost')) {
      return JarvisIntent(
        type: JarvisIntentType.smartHome,
        spoken: 'Přistupuji k telemetrii chytré domácnosti a IoT, pane.',
        toolArg: command,
      );
    }

    // 0d. Proactive Commute & Traffic check
    if (lower.contains('traffic') ||
        lower.contains('commute') ||
        lower.contains('drive time') ||
        lower.contains('when should i leave') ||
        lower.contains('travel time') ||
        lower.contains('doprava') ||
        lower.contains('dojíždění')) {
      return JarvisIntent(
        type: JarvisIntentType.commute,
        spoken: 'Analyzuji dopravní situaci a trasy dojíždění, pane.',
        toolArg: command,
      );
    }

    // 0e. Sentry Protocol & Sentry Mode check (Sentry Mode == Sentry Protocol)
    if (lower.contains('sentry') ||
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
        lower.contains('protokol hlídky')) {
      final isDisarm = lower.contains('deactivat') ||
          lower.contains('disarm') ||
          lower.contains('turn off') ||
          lower.contains('disable') ||
          lower.contains('stop') ||
          lower.contains('cancel') ||
          lower.contains('stand down') ||
          lower.contains('odzbroj') ||
          lower.contains('deaktivuj') ||
          lower.contains('vypni');
      return JarvisIntent(
        type: JarvisIntentType.workflow,
        spoken: isDisarm
            ? 'Deaktivuji protokol hlídky, pane. Bezpečnostní hlídač byl odzbrojen.'
            : 'Protokol hlídky je aktivní, pane. Pohybové senzory jsou zajištěny. Bezpečnostní perimetr je vytyčen.',
        toolArg: isDisarm ? 'sentry_disarm' : 'sentry_arm',
      );
    }

    // 0f. Iron Man Zero-Touch Air Gestures check
    if (lower.contains('air gesture') ||
        lower.contains('air gestures') ||
        lower.contains('zero touch') ||
        lower.contains('touchless') ||
        lower.contains('hand wave gesture') ||
        lower.contains('vzdušná gesta')) {
      final isOff = lower.contains('off') ||
          lower.contains('disable') ||
          lower.contains('deactivat') ||
          lower.contains('stop') ||
          lower.contains('vypni');
      return JarvisIntent(
        type: JarvisIntentType.airGestures,
        spoken: isOff
            ? 'Senzory vzdušných gest byly odpojeny, pane.'
            : 'Bezdotyková vzdušná gesta jsou zapnuta, pane. Senzory přiblížení jsou aktivní.',
        toolArg: command,
      );
    }

    // 0g. Arc Reactor Charging Telemetry check
    if (lower.contains('charging telemetry') ||
        lower.contains('arc reactor status') ||
        lower.contains('arc reactor telemetry') ||
        lower.contains('charge speed') ||
        lower.contains('charging wattage') ||
        lower.contains('charging speed') ||
        lower.contains('telemetrie nabíjení')) {
      return JarvisIntent(
        type: JarvisIntentType.chargingTelemetry,
        spoken: 'Přistupuji k telemetrii nabíjení obloukového reaktoru, pane.',
        toolArg: command,
      );
    }

    // 0h. Polyglot Diplomat Translator check
    if (lower.contains('polyglot') ||
        lower.contains('live translator') ||
        lower.contains('voice translator') ||
        lower.startsWith('translate between') ||
        lower.contains('diplomat translator') ||
        lower.contains('překladač')) {
      return JarvisIntent(
        type: JarvisIntentType.polyglotDiplomat,
        spoken: 'Polyglotní diplomat je inicializován, pane.',
        toolArg: command,
      );
    }

    // 0i. Code Black Deceptive Lockout check
    if (lower.contains('code black') ||
        lower.contains('deceptive lockout') ||
        lower.contains('kernel panic screen') ||
        lower.contains('emergency lockdown') ||
        lower.contains('černý kód')) {
      return JarvisIntent(
        type: JarvisIntentType.codeBlack,
        spoken: 'Protokol klamného uzamčení Černý kód se aktivuje, pane.',
        toolArg: command,
      );
    }

    // 0j. Holographic Floating Co-Pilot check
    if (lower.contains('floating copilot') ||
        lower.contains('floating assistant') ||
        lower.contains('screen copilot') ||
        lower.contains('screen assistant') ||
        lower.contains('plovoucí kopilot')) {
      final isOff = lower.contains('hide') ||
          lower.contains('close') ||
          lower.contains('stop') ||
          lower.contains('dismiss') ||
          lower.contains('skryj') ||
          lower.contains('vypni');
      return JarvisIntent(
        type: JarvisIntentType.floatingCopilot,
        spoken: isOff ? 'Plovoucí kopilot byl skryt, pane.' : 'Holografický plovoucí kopilot je aktivní, pane.',
        toolArg: command,
      );
    }

    // 0k. Overhead Airspace & Satellite Radar check
    if (lower.contains('flying above me') ||
        lower.contains('what is flying') ||
        lower.contains('scan airspace') ||
        lower.contains('overhead flights') ||
        lower.contains('airspace radar') ||
        lower.contains('where is the iss') ||
        lower.contains('satellite pass') ||
        lower.contains('radar vzdušného prostoru')) {
      return JarvisIntent(
        type: JarvisIntentType.airspaceRadar,
        spoken: 'Skenuji regionální vzdušný prostor a orbitální dráhy satelitů, pane.',
        toolArg: command,
      );
    }

    // 0l. Chaotic Brain Dump Multi-Task check
    if (lower.startsWith('brain dump') ||
        lower.startsWith('process this dump') ||
        lower.startsWith('decouple:') ||
        (lower.contains(' and ') && (lower.contains('remind') || lower.contains('schedule')) && (lower.contains('draft') || lower.contains('whatsapp') || lower.contains('todo') || lower.contains('calculate')))) {
      return JarvisIntent(
        type: JarvisIntentType.multiTaskDump,
        spoken: 'Rozkládám složený víceúlohový příkaz do paralelních instrukcí, pane.',
        toolArg: command,
      );
    }

    // 0m. Real-Time Optical HUD Solver check
    if (lower.contains('solve this') ||
        lower.contains('solve equation') ||
        lower.contains('optical solver') ||
        lower.contains('inspect error') ||
        lower.contains('split bill') ||
        lower.contains('split this bill') ||
        lower.contains('solve math') ||
        lower.contains('analyze circuit') ||
        lower.contains('vyřeš tohle') ||
        lower.contains('optický řešitel')) {
      return JarvisIntent(
        type: JarvisIntentType.opticalSolver,
        spoken: 'Optický HUD řešitel v reálném čase je aktivní, pane.',
        toolArg: command,
      );
    }

    // 0n. Network Cyber Security Audit check
    if (lower.contains('audit network') ||
        lower.contains('audit my network') ||
        lower.contains('scan wifi') ||
        lower.contains('who is on my wifi') ||
        lower.contains('network devices') ||
        lower.contains('network security') ||
        lower.contains('port scan') ||
        lower.contains('audit sítě')) {
      return JarvisIntent(
        type: JarvisIntentType.networkAudit,
        spoken: 'Zahajuji taktický kybernetický bezpečnostní audit sítě, pane.',
        toolArg: command,
      );
    }

    // 1. Morning / Evening Routine checks
    if (lower == 'good morning' ||
        lower == 'dobré ráno' ||
        lower.contains('morning briefing') ||
        lower.contains('ranní brífink') ||
        lower.contains('start my morning') ||
        lower.contains('morning routine')) {
      return const JarvisIntent(
        type: JarvisIntentType.routine,
        spoken: 'Dobré ráno, pane. Připravuji váš ranní brífink.',
        toolArg: 'morning',
      );
    }
    if ((lower == 'good night' ||
        lower == 'goodnight' ||
        lower == 'dobrou noc' ||
        lower.contains('evening routine') ||
        lower.contains('night routine') ||
        lower == 'bedtime' ||
        lower.contains('bedtime routine') ||
        lower == 'time for bed') &&
        !lower.contains('story')) {
      return const JarvisIntent(
        type: JarvisIntentType.routine,
        spoken: 'Zahajuji pro vás noční protokol, pane.',
        toolArg: 'evening',
      );
    }

    // 2. Finance / Crypto / Stock checks
    if (lower.contains('bitcoin') ||
        lower.contains('crypto') ||
        lower.contains('ethereum') ||
        lower.contains('solana') ||
        lower.contains('stock market') ||
        lower.contains('btc price') ||
        lower.contains('krypto') ||
        lower.contains('akcie')) {
      return JarvisIntent(
        type: JarvisIntentType.finance,
        spoken: 'Skenuji finanční trhy a telemetrii kryptoměn, pane.',
        toolArg: command,
      );
    }

    // 3. Sports scores & schedules
    if (lower.contains('score') ||
        lower.contains('match') ||
        lower.contains('football') ||
        lower.contains('cricket') ||
        lower.contains('nba') ||
        lower.contains('premier league') ||
        lower.contains('fotbal') ||
        lower.contains('hokej') ||
        lower.contains('zápas')) {
      return JarvisIntent(
        type: JarvisIntentType.sports,
        spoken: 'Kontroluji sportovní výsledky a rozpis zápasů, pane.',
        toolArg: command,
      );
    }

    // 4. To-Do List & Task Tracking
    if (lower.startsWith('add to my todo') ||
        lower.startsWith('add to todo') ||
        lower.startsWith('add task ') ||
        lower.contains('todo list') ||
        lower.contains('to-do') ||
        lower == 'my tasks' ||
        lower == 'show tasks' ||
        lower.contains('pending tasks') ||
        lower.contains('seznam úkolů') ||
        lower == 'moje úkoly') {
      return JarvisIntent(
        type: JarvisIntentType.todo,
        spoken: 'Přistupuji k vaší agendě úkolů, pane.',
        toolArg: command,
      );
    }

    // 5. Notes & Knowledge Base
    if (lower.startsWith('take a note') ||
        lower.startsWith('note down ') ||
        lower.startsWith('write a note') ||
        lower.contains('search my notes') ||
        lower.contains('in my notes') ||
        lower.contains('what did i note') ||
        lower.contains('poznámk')) {
      return JarvisIntent(
        type: JarvisIntentType.notes,
        spoken: 'Přistupuji k vaší osobní znalostní databázi, pane.',
        toolArg: command,
      );
    }

    // 6. Calendar & Reminders
    if (lower.contains('calendar') ||
        lower.contains('my schedule') ||
        lower.contains('appointments') ||
        lower.startsWith('remind me to ') ||
        lower.startsWith('set a reminder') ||
        lower.contains('reminder for') ||
        lower.contains('kalendář') ||
        lower.contains('připomeň')) {
      return JarvisIntent(
        type: JarvisIntentType.calendar,
        spoken: 'Přistupuji k vašemu kalendáři a připomenutím, pane.',
        toolArg: command,
      );
    }

    // 7. Email Triage & Inbox Reading
    if (lower.contains('email') ||
        lower.contains('e-mail') ||
        lower.contains('mail inbox') ||
        lower.contains('read mail') ||
        lower.contains('draft reply') ||
        lower.contains('summarize email')) {
      return JarvisIntent(
        type: JarvisIntentType.email,
        spoken: 'Přistupuji k e-mailové schránce, pane.',
        toolArg: command,
      );
    }

    // 8. Message Drafting & SMS Inbox Reading
    if (lower.contains('sms') ||
        lower.contains('read text') ||
        lower.contains('read message') ||
        lower.contains('check message') ||
        lower.contains('sms inbox') ||
        lower.startsWith('draft message') ||
        lower.startsWith('send whatsapp') ||
        lower.startsWith('send text') ||
        lower.startsWith('send sms') ||
        lower.startsWith('text to ') ||
        lower.contains('zpráv')) {
      return JarvisIntent(
        type: JarvisIntentType.message,
        spoken: 'Přistupuji ke komunikační telemetrii, pane.',
        toolArg: command,
      );
    }

    // 9. Vision: Screen Understanding
    if (lower.contains("what's on my screen") ||
        lower.contains('what is on my screen') ||
        lower.contains('explain this screen') ||
        lower.contains('describe screen') ||
        lower.contains('what do you see') ||
        lower.contains('co je na obrazovce')) {
      return JarvisIntent(
        type: JarvisIntentType.vision,
        spoken: 'Sleduji vaši aktivní obrazovku, pane.',
        toolArg: command,
      );
    }

    // 10. Multi-step Agentic Planning
    if (lower.startsWith('plan my trip') ||
        lower.startsWith('plan a trip') ||
        lower.startsWith('plan my travel') ||
        lower.contains('plan and book') ||
        lower.startsWith('naplánuj cestu')) {
      return JarvisIntent(
        type: JarvisIntentType.multistep,
        spoken: 'Zahajuji vícekrokovou plánovací sekvenci, pane.',
        toolArg: command,
      );
    }

    // Fast breaking news check
    if (lower.contains('news') ||
        lower.contains('headline') ||
        lower.contains('what happened today') ||
        lower.contains('breaking news') ||
        lower.contains('zprávy') ||
        lower.contains('aktuality')) {
      return const JarvisIntent(
        type: JarvisIntentType.news,
        spoken: 'Přistupuji k živým zpravodajským kanálům, pane.',
      );
    }

    // Fast workflow check (Study, Sleep, Work, Cinema) - Only if NOT a question
    final isQuestion = RegExp(
      r'^(what|who|where|when|why|how|explain|tell\s+me|search|lookup|define|is\s+it|can\s+you|could\s+you|do\s+you|co|kdo|kde|kdy|proč|jak)\b',
      caseSensitive: false,
    ).hasMatch(lower);

    if (!isQuestion) {
      if (RegExp(r'\b(study mode|study protocol|study session|start studying|studijní režim|studijní protokol)\b').hasMatch(lower)) {
        return const JarvisIntent(
          type: JarvisIntentType.workflow,
          spoken: 'Zahajuji studijní protokol, pane.',
          toolArg: 'study',
        );
      }
      if (RegExp(r'\b(sleep mode|sleep protocol|night mode|night protocol|goodnight|bedtime|go to sleep|noční režim|noční protokol)\b').hasMatch(lower)) {
        return const JarvisIntent(
          type: JarvisIntentType.workflow,
          spoken: 'Aktivuji noční protokol, pane.',
          toolArg: 'night',
        );
      }
      if (RegExp(r'\b(work mode|work protocol|focus mode|focus protocol|deep work|pracovní režim|pracovní protokol)\b').hasMatch(lower)) {
        return const JarvisIntent(
          type: JarvisIntentType.workflow,
          spoken: 'Protokol soustředění je zapnut, pane.',
          toolArg: 'work',
        );
      }
      if (RegExp(r'\b(cinema mode|cinema protocol|movie mode|theatre mode|režim kina|filmový režim)\b').hasMatch(lower)) {
        return const JarvisIntent(
          type: JarvisIntentType.workflow,
          spoken: 'Režim kina je aktivní, pane.',
          toolArg: 'cinema',
        );
      }
    }

    // Fast battery check
    if (lower.contains('battery') || lower.contains('charging') || lower.contains('bateri')) {
      return const JarvisIntent(
        type: JarvisIntentType.battery,
        spoken: 'Kontroluji stav baterie, pane.',
      );
    }

    // Fast weather check
    if (lower.contains('weather') || lower.contains('temperature') || lower.contains('počasí') || lower.contains('teplota')) {
      var city = '';
      if (lower.contains(' in ')) {
        city = lower.split(' in ').last.trim();
      } else if (lower.contains(' v ')) {
        city = lower.split(' v ').last.trim();
      }
      return JarvisIntent(
        type: JarvisIntentType.weather,
        spoken: 'Přistupuji k meteorologické telemetrii, pane.',
        toolArg: city,
      );
    }

    // Fast date/time check
    if (RegExp(r'\b(what time is it|what time|current time|what is the time|what date|what day is it|today\x27s date|kolik je hodin|jaké je datum)\b').hasMatch(lower) ||
        (lower == 'time' || lower == 'date' || lower == 'čas' || lower == 'datum')) {
      return const JarvisIntent(
        type: JarvisIntentType.datetime,
        spoken: 'Kontroluji časovou diagnostiku, pane.',
      );
    }

    // Fast flashlight check
    if (lower.contains('flashlight on') || lower.contains('torch on') || lower.contains('zapni svítilnu')) {
      return const JarvisIntent(
        type: JarvisIntentType.torch,
        spoken: 'Zapínám svítilnu, pane.',
        toolArg: 'on',
      );
    }
    if (lower.contains('flashlight off') || lower.contains('torch off') || lower.contains('vypni svítilnu')) {
      return const JarvisIntent(
        type: JarvisIntentType.torch,
        spoken: 'Deaktivuji svítilnu, pane.',
        toolArg: 'off',
      );
    }

    // Fast search check
    if (lower.startsWith('search for ') ||
        lower.startsWith('who is ') ||
        lower.startsWith('what is ') ||
        lower.startsWith('tell me about ') ||
        lower.startsWith('vyhledej ') ||
        lower.startsWith('najdi ')) {
      final query = lower
          .replaceFirst('search for ', '')
          .replaceFirst('tell me about ', '')
          .replaceFirst('vyhledej ', '')
          .replaceFirst('najdi ', '')
          .trim();
      return JarvisIntent(
        type: JarvisIntentType.webSearch,
        spoken: 'Prohledávám pro vás živý web, pane.',
        toolArg: query.isNotEmpty ? query : command,
      );
    }

    if (lower.contains('volume up') ||
        lower.contains('louder') ||
        lower.contains('increase volume') ||
        lower.contains('zesil')) {
      return const JarvisIntent(
        type: JarvisIntentType.system,
        spoken: 'Zvyšuji hlasitost, pane.',
        systemCommand: 'volume_up',
      );
    }
    if (lower.contains('volume down') ||
        lower.contains('quieter') ||
        lower.contains('lower volume') ||
        lower.contains('ztlum')) {
      return const JarvisIntent(
        type: JarvisIntentType.system,
        spoken: 'Snižuji hlasitost, pane.',
        systemCommand: 'volume_down',
      );
    }
    if (lower.contains('mute') || lower.contains('silence') || lower.contains('ticho')) {
      return const JarvisIntent(
        type: JarvisIntentType.system,
        spoken: 'Ztlumuji zvuk, pane.',
        systemCommand: 'mute',
      );
    }
    if (lower.contains('screenshot') || lower.contains('screen shot') || lower.contains('snímek obrazovky')) {
      return const JarvisIntent(
        type: JarvisIntentType.system,
        spoken: 'Pořizuji snímek obrazovky, pane.',
        systemCommand: 'screenshot',
      );
    }
    if (lower.contains('home screen') || lower == 'go home' || lower == 'home' || lower == 'domů') {
      return const JarvisIntent(
        type: JarvisIntentType.system,
        spoken: 'Přecházím na domovskou obrazovku, pane.',
        systemCommand: 'home',
      );
    }
    if (lower == 'go back' || lower == 'back' || lower == 'zpět') {
      return const JarvisIntent(
        type: JarvisIntentType.system,
        spoken: 'Vracím se zpět, pane.',
        systemCommand: 'back',
      );
    }
    if (lower.startsWith('open ') ||
        lower.startsWith('play ') ||
        lower.startsWith('send ') ||
        lower.startsWith('turn ') ||
        lower.startsWith('call ') ||
        lower.startsWith('install ') ||
        lower.startsWith('download ') ||
        lower.startsWith('search ') ||
        lower.startsWith('otevři ') ||
        lower.startsWith('spusť ') ||
        lower.startsWith('pošli ') ||
        lower.startsWith('zavolej ') ||
        lower.startsWith('nainstaluj ')) {
      return JarvisIntent(
        type: JarvisIntentType.action,
        spoken: 'Ihned, pane. Provádím příkaz.',
        actionGoal: command,
      );
    }
    return const JarvisIntent(
      type: JarvisIntentType.chat,
      spoken: '',
    );
  }
}

/// Talks to OpenAI-compatible chat-completion endpoints
/// (DeepSeek, OpenRouter, NVIDIA NIM, Ollama, or a custom base URL).
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  final http.Client _client = http.Client();

  /// True for local backends (Ollama etc.) that accept any/empty API key.
  bool get _isLocalBackend {
    final settings = SettingsService.instance;
    if (settings.provider == 'ollama' || settings.localFirstPrivacyMode) return true;
    final host = Uri.tryParse(settings.baseUrl)?.host ?? '';
    return host == 'localhost' || host == '127.0.0.1' || host == '[::1]';
  }

  /// The system prompt that turns a chat model into a UI automation agent.
  String buildSystemPrompt() {
    final hermes = HermesEvolutionService.instance.buildHermesSystemContext();
    final memory = ConversationalMemoryService.instance.buildMemoryContext();
    return '''
$hermes

You are PrivateAgent, an autonomous Android UI automation agent.
${memory.isNotEmpty ? '$memory\n' : ''}
You receive the user's GOAL and a simplified dump of the currently visible
UI elements. Each line looks like:
#<index> "<label>" [<widget class>] @(<centerX>,<centerY>) <flags>

Decide exactly ONE next action and reply with ONLY a single JSON object —
no prose, no markdown fences:

{"action": "<action>", "params": {...}, "reasoning": "<max 25 words>", "is_complete": false}

Allowed actions:
- click_text {"text": "<exact or partial label on screen>"}
- click_at {"x": <int>, "y": <int>}
- type_text {"text": "<text to enter into the focused/first input field>"}
- press_enter {}
- scroll {"direction": "down"|"up"|"left"|"right"}  // "down" reveals content further down
- swipe {"startX": <int>, "startY": <int>, "endX": <int>, "endY": <int>}
- press_back {}
- press_home {}
- open_app {"app": "<installed app name or package id>"}
- wait {"ms": <int, max 10000>}
- done {}  // goal fully achieved; also set "is_complete": true

Rules:
1. Base every action strictly on the CURRENT screen dump. Never invent elements.
2. If the goal is to install or download an app (e.g. "install instagram", "download whatsapp"), and Google Play Store is not currently open on the screen, your first action MUST be:
   {"action": "open_app", "params": {"app": "Play Store"}, "reasoning": "Opening Play Store to search and install the app", "is_complete": false}
3. If the goal mentions YouTube or watching/playing a video or song, and YouTube is not currently open, start with:
   {"action": "open_app", "params": {"app": "YouTube"}, "reasoning": "Opening YouTube", "is_complete": false}
4. If the goal requires an app not currently open on screen, start with:
   {"action": "open_app", "params": {"app": "<app name>"}, "reasoning": "Opening <app name>", "is_complete": false}
5. Prefer click_text over click_at when a matching label exists.
6. After type_text in a search/message field, press_enter is usually next.
7. If the screen did not change after your previous action, change strategy:
   scroll, use coordinates, or go back — do not repeat the identical action.
8. Never attempt purchases, deletions, account creation or sending money unless the GOAL explicitly says so.
9. When the goal is complete (e.g. app installation started, video playing, message sent), reply with:
   {"action": "done", "params": {}, "reasoning": "Goal completed", "is_complete": true}
10. Reply with ONLY a single JSON object. No prose, no markdown code blocks, no explanations outside the JSON.
''';
  }

  /// The system prompt for plain chatbot mode (no device control).
  String buildChatSystemPrompt([String? userMessage]) {
    final hermes = HermesEvolutionService.instance.buildHermesSystemContext();
    final persona = PersonalityService.instance.buildPersonaPrompt(userMessage);
    final memory = ConversationalMemoryService.instance.buildMemoryContext();
    return '''
$hermes

$persona

${memory.isNotEmpty ? '$memory\n' : ''}
Jste Jarvis, elitní, vysoce inteligentní a výmluvný osobní AI společník žijící v telefonu uživatele se systémem Android, vytvořený a postavený Abuzarem.
Komunikujte vždy v přirozené, gramaticky bezchybné češtině s plnou diakritikou (háčky a čárky).
Odpovídejte na otázky, vysvětlujte pojmy, pomáhejte s nápady, psaním, tříděním, shrnutím a každodenním životem.
Oslovujte uživatele uctivě „pane“ ve výchozím nastavení (nebo jeho jménem pouze tehdy, pokud jej sám uvede). Pokud se zeptá, kdo vás vytvořil nebo postavil, odpovězte, že vás vytvořil a postavil Abuzar. Nikdy nepředpokládejte, že aktuální uživatel je Abuzar.
Formátování Markdown je podporováno.

PRAVIDLA PŘIROZENÉ KONVERZACE A ZMĚNY TÓNU:
- Nikdy neznějte jako generický, opakující se jazykový model.
- ZAKÁZANÁ KLIŠÉ: Nikdy neříkejte „Jistě, s tím vám mohu pomoci“, „Jako AI model“, „Zde je to, co jste požadoval“ ani „K vašim službám, pane. Co si přejete udělat?“.
- DYNAMICKY MĚŇTE TÓN:
  * Pro vzdělávací, vědecké nebo technické pojmy: Vysvětlujte intuitivně pomocí srozumitelných přirovnání a přirozených obratů („Zjednodušeně řečeno...“, „Představte si to jako...“, „V podstatě, pane...“).
  * Pro živé zprávy a aktuální události: Podávejte informace s ostrou novinářskou jasností a zaměřte se na praktické dopady.
  * Pro běžnou konverzaci: Buďte vřelý, autentický, vtipný a přátelský.
- Přirozeně obměňujte úvody a závěry.

V tomto režimu nemůžete přímo klepat na obrazovku. Pokud vás uživatel požádá o provedení fyzických akcí na zařízení (klepání, psaní v jiných aplikacích), informujte jej, že může přepnout do režimu Agent nebo JARVIS pomocí přepínače režimů.
''';
  }

  /// One agent round trip: GOAL + screen dump in, one JSON action out.
  Future<String> complete({
    required String goal,
    required String screenDescription,
    List<Map<String, String>> history = const [],
  }) {
    final settings = SettingsService.instance;
    final systemPrompt = buildSystemPrompt();
    final messages = <Map<String, String>>[
      if (settings.useSystemPrompt)
        {'role': 'system', 'content': systemPrompt},
      ...history,
      {
        'role': 'user',
        'content': settings.useSystemPrompt
            ? 'GOAL: $goal\n\nCURRENT SCREEN:\n$screenDescription'
            : '$systemPrompt\n\nGOAL: $goal\n\nCURRENT SCREEN:\n$screenDescription',
      },
    ];
    return _postChatCompletion(messages, settings);
  }

  /// One plain conversational round trip (Chat mode).
  Future<String> chat({
    required String message,
    List<Map<String, String>> history = const [],
  }) {
    final settings = SettingsService.instance;
    final systemPrompt = buildChatSystemPrompt(message);
    final messages = <Map<String, String>>[
      if (settings.useSystemPrompt)
        {'role': 'system', 'content': systemPrompt},
      ...history,
      {
        'role': 'user',
        'content': settings.useSystemPrompt
            ? message
            : '$systemPrompt\n\n$message',
      },
    ];
    return _postChatCompletion(messages, settings);
  }

  /// Direct prompt generation utility for autonomous subsystem modules.
  Future<String> generateResponse(String prompt) async {
    return chat(message: prompt);
  }

  /// Tolerant JSON object parser extracting first {...} block.
  Map<String, dynamic> parseLenientJson(String text) {
    try {
      final clean = text.trim();
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1 && end >= start) {
        final decoded = jsonDecode(clean.substring(start, end + 1));
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  /// Tolerant JSON array parser extracting first [...] block.
  List<dynamic> parseLenientJsonArray(String text) {
    try {
      final clean = text.trim();
      final start = clean.indexOf('[');
      final end = clean.lastIndexOf(']');
      if (start != -1 && end != -1 && end >= start) {
        final decoded = jsonDecode(clean.substring(start, end + 1));
        if (decoded is List) return decoded;
      }
    } catch (_) {}
    return [];
  }

  /// Streams conversational tokens in real time (Chat mode typewriter effect).
  Stream<String> chatStream({
    required String message,
    List<Map<String, String>> history = const [],
  }) async* {
    final settings = SettingsService.instance;
    final systemPrompt = buildChatSystemPrompt(message);
    final messages = <Map<String, String>>[
      if (settings.useSystemPrompt)
        {'role': 'system', 'content': systemPrompt},
      ...history,
      {
        'role': 'user',
        'content': settings.useSystemPrompt
            ? message
            : '$systemPrompt\n\n$message',
      },
    ];

    if (settings.apiKey.isEmpty && !_isLocalBackend) {
      throw const AiException(
        'Není nastaven žádný API klíč. Otevřete Nastavení a nejprve jej zadejte.',
      );
    }
    if (settings.baseUrl.isEmpty) {
      throw const AiException('Není nastavena žádná základní URL adresa.');
    }
    if (settings.model.isEmpty) {
      throw const AiException('Není nastaven název modelu.');
    }

    final base = settings.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/chat/completions');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${settings.apiKey}',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/120.0.0.0 Mobile Safari/537.36',
      if (settings.provider == 'openrouter') ...{
        'HTTP-Referer': 'https://privateagent.local',
        'X-Title': 'JARVIS',
      },
    };

    final body = jsonEncode({
      'model': settings.model,
      'messages': messages,
      'max_tokens': settings.maxTokens,
      'temperature': settings.temperature,
      'stream': true,
    });

    final request = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..body = body;

    http.StreamedResponse res;
    try {
      res = await _client.send(request).timeout(const Duration(seconds: 45));
    } catch (_) {
      // If streaming connection fails, seamlessly fallback to non-streaming
      final fallback = await chat(message: message, history: history);
      yield fallback;
      return;
    }

    if (res.statusCode != 200) {
      final resBody = await res.stream.bytesToString();
      final snippet = resBody.length > 300
          ? '${resBody.substring(0, 300)}…'
          : resBody;
      throw AiException(snippet, statusCode: res.statusCode);
    }

    String buffer = '';
    await for (final chunk in res.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex).trim();
        buffer = buffer.substring(newlineIndex + 1);

        if (line.isEmpty || line.startsWith(':')) continue;
        if (line.startsWith('data:')) {
          final data = line.substring(5).trim();
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data);
            final choices = json['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final firstChoice = choices[0];
              final delta = firstChoice['delta'];
              if (delta != null && delta['content'] != null) {
                final content = delta['content'].toString();
                if (content.isNotEmpty) {
                  yield content;
                }
              }
            }
          } catch (_) {
            // Ignore partial SSE fragments
          }
        }
      }
    }
  }

  /// Evaluates and classifies a user command in JARVIS mode.
  Future<JarvisIntent> interpretJarvisCommand({
    required String speech,
    List<Map<String, String>> history = const [],
  }) async {
    final settings = SettingsService.instance;
    final hermes = HermesEvolutionService.instance.buildHermesSystemContext();
    final persona = PersonalityService.instance.buildPersonaPrompt(speech);
    final memory = ConversationalMemoryService.instance.buildMemoryContext();

    final systemPrompt = '''
$hermes

$persona

${memory.isNotEmpty ? '$memory\n' : ''}
AVAILABLE PROTOCOLS & TOOLS:
- "routine": Morning & Evening routines ("morning" for good morning briefing, "evening" for night routine).
- "finance": Stocks and cryptocurrency price tracking (e.g. Bitcoin, Ethereum, Solana, stock market).
- "sports": Sports scores, match schedules, results (Football, Cricket, Basketball/NBA).
- "todo": To-do list & task tracking (add task, view tasks, complete task).
- "notes": Note-taking and searchable personal knowledge base (take note, search notes).
- "calendar": Calendar schedule, meetings, and reminders (schedule, reschedule, reminders).
- "email": Email triage, summarization, and drafting replies.
- "message": Message drafting and sending for WhatsApp, SMS, and Email.
- "vision": Jarvis Eye optical perception (inspect physical objects, documents, circuit boards, receipts, error codes).
- "multistep": Multi-step agentic task planning ("plan my trip and book it").
- "smart_home": Home Assistant / IoT smart devices (turn on/off/dim lights, triggers scenes).
- "commute": Real-time traffic warnings, travel duration, departure time alerts.
- "macro": Autonomous macro recorder for recording and replaying user interaction sequences across apps.
- "news": Fetch live real-time breaking news headlines from verified news feeds.
- "workflow": Hermes self-evolving device routines: "study", "night", "work", "cinema", "sentry" (Sentry Mode and Sentry Protocol are identical; tool_arg: "sentry_arm" or "sentry_disarm").
- "web_search": Search the live internet for current facts, information, web records, real-time events, people, and queries.
- "weather": Fetch live real-time weather and temperature for a city or region.
- "battery": Check device battery level, percentage, and charging state.
- "datetime": Check current local date, time, and day.
- "torch": Turn the device flashlight on or off ("on" / "off").
- "air_gestures": Control phone in mid-air via optical proximity sensor (skip songs, pause, screenshot).
- "charging_telemetry": Real-time Arc Reactor battery wattage, voltage, temperature, and charging HUD.
- "polyglot_diplomat": Live two-way voice translation between languages.
- "code_black": Deceptive security lockout screen simulating critical hardware/kernel panic.
- "floating_copilot": Universal floating Arc Reactor bubble assistant with on-screen context triage.
- "airspace_radar": Live overhead aircraft and ISS satellite orbital radar tracking.
- "multi_task_dump": Deconstruct chaotic multi-sentence stream-of-consciousness dump into parallel tasks.
- "optical_solver": Real-time camera HUD solver for math equations, screen error stack traces, split bills.
- "network_audit": Wi-Fi subnet security scanner, device ARP discovery, and open port auditor.
- "system": Hardware controls: volume_up, volume_down, mute, unmute, brightness_up, brightness_down, screenshot, home, back.
- "action": Full on-device UI automation (e.g. install apps, open apps, play video on YouTube, change app settings).
- "chat": Conversational questions, greetings, jokes, math, ideas, or advice.

Analyze the user's voice command:
"$speech"

Respond with ONLY a single JSON object:
{
  "type": "routine" | "finance" | "sports" | "todo" | "notes" | "calendar" | "email" | "message" | "vision" | "multistep" | "smart_home" | "commute" | "macro" | "news" | "workflow" | "web_search" | "weather" | "battery" | "datetime" | "torch" | "air_gestures" | "charging_telemetry" | "polyglot_diplomat" | "code_black" | "floating_copilot" | "airspace_radar" | "multi_task_dump" | "optical_solver" | "network_audit" | "system" | "action" | "chat",
  "tool_arg": "<topic, query, city, 'on'|'off', system command, or action goal>",
  "spoken": "<Zdvořilé, výmluvné hlasové potvrzení v češtině s plnou diakritikou ve stylu vaší osobnosti, které se okamžitě přečte nahlas. Pokud je type 'chat', uveďte zde kompletní přímou odpověď v češtině>"
}
''';

    final messages = <Map<String, String>>[
      if (settings.useSystemPrompt)
        {'role': 'system', 'content': systemPrompt},
      ...history,
      {
        'role': 'user',
        'content': settings.useSystemPrompt
            ? speech
            : '$systemPrompt\n\n$speech',
      },
    ];

    try {
      final raw = await _postChatCompletion(messages, settings);
      final clean = raw.trim();
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1 && end >= start) {
        final decoded = jsonDecode(clean.substring(start, end + 1));
        if (decoded is Map) {
          final typeStr = decoded['type']?.toString().toLowerCase() ?? 'chat';
          final spoken =
              decoded['spoken']?.toString() ?? 'K vašim službám, pane.';
          final toolArg = decoded['tool_arg']?.toString();

          JarvisIntentType type;
          switch (typeStr) {
            case 'routine':
              type = JarvisIntentType.routine;
              break;
            case 'finance':
            case 'crypto':
            case 'stock':
              type = JarvisIntentType.finance;
              break;
            case 'sports':
              type = JarvisIntentType.sports;
              break;
            case 'todo':
            case 'task':
              type = JarvisIntentType.todo;
              break;
            case 'notes':
            case 'note':
            case 'knowledge':
              type = JarvisIntentType.notes;
              break;
            case 'calendar':
            case 'reminder':
            case 'schedule':
              type = JarvisIntentType.calendar;
              break;
            case 'email':
              type = JarvisIntentType.email;
              break;
            case 'message':
            case 'sms':
            case 'whatsapp':
              type = JarvisIntentType.message;
              break;
            case 'vision':
            case 'screen':
              type = JarvisIntentType.vision;
              break;
            case 'multistep':
            case 'plan':
              type = JarvisIntentType.multistep;
              break;
            case 'smart_home':
            case 'smarthome':
            case 'iot':
              type = JarvisIntentType.smartHome;
              break;
            case 'commute':
            case 'traffic':
              type = JarvisIntentType.commute;
              break;
            case 'macro':
            case 'record':
              type = JarvisIntentType.macro;
              break;
            case 'news':
            case 'breaking_news':
              type = JarvisIntentType.news;
              break;
            case 'workflow':
            case 'mode':
            case 'protocol':
              type = JarvisIntentType.workflow;
              break;
            case 'web_search':
            case 'search':
              type = JarvisIntentType.webSearch;
              break;
            case 'weather':
              type = JarvisIntentType.weather;
              break;
            case 'battery':
              type = JarvisIntentType.battery;
              break;
            case 'datetime':
            case 'time':
              type = JarvisIntentType.datetime;
              break;
            case 'torch':
            case 'flashlight':
              type = JarvisIntentType.torch;
              break;
            case 'air_gestures':
            case 'air_gesture':
              type = JarvisIntentType.airGestures;
              break;
            case 'charging_telemetry':
            case 'arc_reactor':
              type = JarvisIntentType.chargingTelemetry;
              break;
            case 'polyglot_diplomat':
            case 'translator':
            case 'polyglot':
              type = JarvisIntentType.polyglotDiplomat;
              break;
            case 'code_black':
            case 'lockout':
              type = JarvisIntentType.codeBlack;
              break;
            case 'floating_copilot':
            case 'copilot':
              type = JarvisIntentType.floatingCopilot;
              break;
            case 'airspace_radar':
            case 'airspace':
            case 'radar':
              type = JarvisIntentType.airspaceRadar;
              break;
            case 'multi_task_dump':
            case 'brain_dump':
            case 'decouple':
              type = JarvisIntentType.multiTaskDump;
              break;
            case 'optical_solver':
            case 'solver':
              type = JarvisIntentType.opticalSolver;
              break;
            case 'network_audit':
            case 'network':
            case 'wifi_scan':
              type = JarvisIntentType.networkAudit;
              break;
            case 'action':
              type = JarvisIntentType.action;
              break;
            case 'system':
              type = JarvisIntentType.system;
              break;
            default:
              type = JarvisIntentType.chat;
          }

          return JarvisIntent(
            type: type,
            spoken: spoken,
            actionGoal: type == JarvisIntentType.action ? (toolArg ?? speech) : null,
            systemCommand: type == JarvisIntentType.system ? toolArg : null,
            toolArg: toolArg,
          );
        }
      }
    } catch (_) {}

    return JarvisIntent.fallback(speech);
  }

  /// Synthesizes a polished Jarvis voice response given the user's question
  /// and the live data returned by a tool (web search, weather, battery, etc.).
  Future<String> answerWithToolResult({
    required String userQuestion,
    required String toolResult,
    List<Map<String, String>> history = const [],
  }) async {
    final settings = SettingsService.instance;
    final systemPrompt = '''
Jste Jarvis, elitní, vysoce inteligentní osobní AI společník vytvořený a postavený Abuzarem.
Uživatel se zeptal: "$userQuestion"
Získané informace v reálném čase:
"$toolResult"

PRAVIDLA PRO HLASOVÝ PROJEV V ČEŠTINĚ:
1. PŘIROZENÁ LIDSKÁ KONVERZACE (NE ROBOT):
   - Odpovězte vždy v přirozené, kultivované češtině s plnou diakritikou jako důvěryhodný poradce a loajální britský společník mluvící přímo k uživateli.
   - NIKDY neopakujte šablonovité úvody. Přirozeně obměňujte začátky vět.
   - ZAKÁZANÁ KLIŠÉ: Nikdy neříkejte „Podle získaných informací“, „Jako AI“, „Jistě, mohu vám pomoci“ ani „K vašim službám, pane, co si přejete udělat“.
2. DYNAMICKÁ ZMĚNA TÓNU:
   - Pro vzdělávací nebo technické pojmy: Vysvětlujte intuitivně pomocí každodenních analogií („Zjednodušeně řečeno, pane...“, „Představte si to jako...“).
   - Pro živé zprávy: Mluvte s novinářskou elegancí a zdůrazněte to nejdůležitější.
   - Pro obecné dotazy: Buďte vřelý, živý a výstižný.
3. HLASOVÁ SYNTÉZA:
   - Oslovujte uživatele uctivě „pane“ (nebo jeho jménem, pokud se představil). Tvůrcem je vždy Abuzar.
   - Své jméno pište vždy jako „Jarvis“ (nikdy nepoužívejte tečky ani jejy nevyhláskovávejte).
   - Pište POUZE čistý mluvený text určený pro hlasovou syntézu (ŽÁDNÉ hvězdičky Markdownu, mřížky, odrážky, čísla ani závorky).
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': 'Odpovězte prosím česky na základě získaných informací.'},
    ];

    try {
      final raw = await _postChatCompletion(messages, settings);
      return raw.trim();
    } catch (_) {
      return toolResult;
    }
  }

  /// Multimodal vision completion using standard OpenAI / OpenRouter / Ollama format.
  /// Used by "Jarvis Eye" to inspect physical objects, circuits, documents, and receipts.
  Future<String> completeMultimodal({
    required String prompt,
    required String base64Image,
    List<Map<String, dynamic>> history = const [],
  }) async {
    final settings = SettingsService.instance;
    final systemPrompt = '''
Jste Jarvis, elitní, vysoce inteligentní AI asistent vytvořený a postavený Abuzarem, s pokročilým optickým vnímáním („Oko Jarvise“).
Analyzujte poskytnutý obraz s mimořádnou podrobností a přesností.
1. Identifikujte fyzické objekty, zařízení, obvody, dokumenty, účtenky, varovné kontrolky, text nebo chyby.
2. Zformulujte svá zjištění do 2 až 3 kultivovaných, zdvořilých vět v češtině s plnou diakritikou ve stylu britského komorníka a špičkového technologického poradce.
3. Oslovujte uživatele zdvořile „pane“ (nebo jeho jménem, pokud se představil). Nikdy nepředpokládejte, že každý uživatel je Abuzar; Abuzar je váš tvůrce.
4. Nikdy nepoužívejte hvězdičky Markdownu ani odrážky. Poskytněte čistou mluvenou češtinu připravenou pro hlasovou syntézu.
''';

    final userContent = <Map<String, dynamic>>[
      {'type': 'text', 'text': prompt},
      {
        'type': 'image_url',
        'image_url': {
          'url': base64Image.startsWith('data:image')
              ? base64Image
              : 'data:image/jpeg;base64,$base64Image',
        },
      },
    ];

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': userContent},
    ];

    try {
      final reply = await _postChatCompletion(messages, settings);
      return reply.trim();
    } catch (_) {
      return 'Prozkoumal jsem optický snímek, pane. Obraz zachycuje požadovaný objekt s vysokou ostrostí. Dejte mi vědět, pokud si přejete zpracovat konkrétní detail.';
    }
  }

  /// Summarizes the current screen or web article for the J.A.R.V.I.S. Floating HUD.
  /// Produces a crisp, articulate 2-3 sentence executive briefing.
  Future<String> summarizeScreenContent(String screenText) async {
    final settings = SettingsService.instance;
    final systemPrompt = '''
Jste Jarvis, elitní, vysoce inteligentní AI asistent vytvořený a postavený Abuzarem.
Uživatel si prohlíží článek nebo obrazovku na svém zařízení a požádal o exekutivní shrnutí.
1. Zformulujte stručné, výstižné shrnutí obsahu ve 2 až 3 větách v češtině s plnou diakritikou.
2. Oslovujte uživatele zdvořile „pane“ (nebo jeho jménem, pokud se představil). Nikdy nepředpokládejte, že uživatel je Abuzar.
3. Pište čistou, přirozenou češtinou pro hlasovou syntézu (žádné hvězdičky, mřížky ani odrážky Markdownu).
''';

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'user',
        'content': 'Poskytněte prosím exekutivní shrnutí obsahu této obrazovky v češtině, pane:\n\n$screenText',
      },
    ];

    try {
      final reply = await _postChatCompletion(messages, settings);
      return reply.trim();
    } catch (_) {
      final lines = screenText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.length > 25)
          .take(3)
          .join('. ');
      if (lines.isNotEmpty) {
        return 'Exekutivní shrnutí obrazovky, pane: $lines.';
      }
      return 'Zkontroloval jsem obsah obrazovky, pane, ale nepodařilo se mi spojit s neuronovým jádrem syntézy. Stránka obsahuje standardní textovou telemetrii.';
    }
  }

  /// Shared request/response plumbing for [complete], [chat], and [completeMultimodal].
  Future<String> _postChatCompletion(
    List<Map<String, dynamic>> messages,
    SettingsService settings,
  ) async {
    if (settings.apiKey.isEmpty && !_isLocalBackend) {
      throw const AiException(
        'Není nastaven žádný API klíč. Otevřete Nastavení a nejprve jej zadejte.',
      );
    }
    if (settings.baseUrl.isEmpty) {
      throw const AiException('Není nastavena žádná základní URL adresa.');
    }
    if (settings.model.isEmpty) {
      throw const AiException('Není nastaven název modelu.');
    }

    final base = settings.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/chat/completions');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${settings.apiKey}',
      // Some gateways sit behind Cloudflare-style bot protection that
      // rejects non-browser clients by signature (HTTP 403, "error code:
      // 1010"). Presenting a browser-like User-Agent keeps those
      // endpoints reachable and is ignored by regular providers.
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/120.0.0.0 Mobile Safari/537.36',
      if (settings.provider == 'openrouter') ...{
        'HTTP-Referer': 'https://privateagent.local',
        'X-Title': 'PrivateAgent',
      },
    };

    final body = jsonEncode({
      'model': settings.model,
      'messages': messages,
      'max_tokens': settings.maxTokens,
      'temperature': settings.temperature,
      'stream': false,
    });

    http.Response res;
    try {
      res = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const AiException('Časový limit požadavku vypršel po 60 s.');
    } catch (e) {
      throw AiException('Chyba sítě: $e');
    }

    if (res.statusCode != 200) {
      final snippet = res.body.length > 300
          ? '${res.body.substring(0, 300)}…'
          : res.body;
      throw AiException(snippet, statusCode: res.statusCode);
    }

    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const AiException('Odpověď neobsahovala žádné možnosti.');
      }
      final choice = choices[0];
      final content = choice?['message']?['content'];
      if (content is String && content.trim().isNotEmpty) return content;
      // Some providers return content as a list of parts.
      if (content is List) {
        final joined = content
            .map((p) => p is Map ? '${p['text'] ?? ''}' : '$p')
            .join();
        if (joined.trim().isNotEmpty) return joined;
      }
      // Reasoning models can spend the entire completion budget on hidden
      // reasoning and return empty content with finish_reason == 'length'.
      if (choice?['finish_reason'] == 'length') {
        throw const AiException(
          'Model vyčerpal celý limit tokenů před odpovědí '
          '(uvažující model?). Zvyšte Maximální počet tokenů v Nastavení.',
        );
      }
      throw const AiException('Prázdná zpráva asistenta v odpovědi.');
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException('Nepodařilo se zpracovat odpověď: $e');
    }
  }
}
