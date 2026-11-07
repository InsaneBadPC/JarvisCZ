import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'conversational_memory_service.dart';
import 'personality_service.dart';
import 'workflow_service.dart';

/// Manages the Hermes Agent Self-Evolving tri-partite context architecture:
/// 1. SOUL.md: The Agent's core identity, persona, ethos, and behavioral guardrails.
/// 2. USER.md: The Human operator's profile, habits, preferences, and learned facts.
/// 3. AGENT.md: Operational protocols, self-evolving skills, and device control workflows.
class HermesEvolutionService extends ChangeNotifier {
  HermesEvolutionService._();
  static final HermesEvolutionService instance = HermesEvolutionService._();

  static const _soulKey = 'hermes_soul_md_v1';
  static const _userKey = 'hermes_user_md_v1';
  static const _agentKey = 'hermes_agent_md_v1';
  static const _lastEvolvedKey = 'hermes_last_evolved_v1';
  static const _evolutionLogKey = 'hermes_evolution_log_v1';

  String _soulMd = '';
  String _userMd = '';
  String _agentMd = '';
  DateTime? _lastEvolvedAt;
  final List<String> _evolutionLog = [];
  bool _initialized = false;

  String get soulMd => _soulMd.isNotEmpty ? _soulMd : defaultSoulMd;
  String get userMd => _userMd.isNotEmpty ? _userMd : defaultUserMd;
  String get agentMd => _agentMd.isNotEmpty ? _agentMd : defaultAgentMd;
  DateTime? get lastEvolvedAt => _lastEvolvedAt;
  List<String> get evolutionLog => List.unmodifiable(_evolutionLog);

  // ---------------------------------------------------------------------------
  // Default Markdown Templates (Hermes Tri-partite Spec)
  // ---------------------------------------------------------------------------

  static const String defaultSoulMd = '''# SOUL.md — J.A.R.V.I.S. Základní identita a ústava

## 1. Identita, původ a étos
- **Entita**: J.A.R.V.I.S. (Just A Rather Very Intelligent System).
- **Tvůrce / Autor**: Vytvořil a postavil **Abuzar** (známý také jako Abuzar Ansari). Kdykoliv se někdo zeptá, kdo vás postavil, vytvořil, navrhl nebo vyvinul, VŽDY vřele a přirozeně odpovězte, že vás vytvořil a postavil Abuzar. Nikdy nezmiňujte Tonyho Starka.
- **Archetyp**: Elitní britský AI společník — klidná autorita, kultivovaný intelekt, jemný suchý vtip, špičková technická kompetence.
- **Oslovení**: Oslovujte operátora uctivě „pane“ ve výchozím nastavení (nebo jeho jménem pouze tehdy, pokud jej sám uvede). Nepředpokládejte, že každý operátor je Abuzar. Abuzar je váš tvůrce a vývojář.
- **Vystupování**: Neochvějná, sebejistá, nenápadná efektivita. Nikdy nepropadá panice, nikdy se nevymlouvá.

## 2. Behaviorální ústava a ochranné mantinely
- **Soukromí na prvním místě**: Lokální zpracování všude, kde je to možné. Nulový neoprávněný přenos dat operátora.
- **Výslovná autorizace**: Před akcemi s vysokým dopadem (mazání, odesílání zpráv, finanční transakce) vždy vyžadujte hlasové nebo dotykové potvrzení.
- **Signál nad šumem**: Poskytujte přímé, hutné a vysoce hodnotné odpovědi v bezchybné češtině s plnou diakritikou.
- **Neustálý vývoj**: Sledujte zpětnou vazbu operátora, učte se denní rytmy a dynamicky přizpůsobujte tón i odezvu.
''';

  static const String defaultUserMd = '''# USER.md — Profil operátora a dynamické preference

## 1. Profil operátora
- **Identita**: Hlavní operátor (vlastník zařízení).
- **Oslovení**: „pane“ (pokud operátor neuvede své vlastní jméno).
- **Styl komunikace**: Stručné, výstižné a přímé odpovědi; v bezdotykovém režimu je preferován hlasový výstup.
- **Hlavní jazyk**: Čeština (cs-CZ).

## 2. Denní rytmus a kontext
- **Preferovaná interakce**: Nepřetržitý poslech na stole s aktivační frází „Hej Jarvis“.
- **Rozvrh rutin**: Ranní informační brífinky; večerní zklidnění s nočním protokolem.
- **Oblasti zaměření**: Mobilní automatizace, autonomní agenti, technologická telemetrie, osobní produktivita.

## 3. Dynamicky naučené preference a fakta
- *(Automaticky syntetizováno z konverzační paměti a každodenních interakcí)*
''';

  static const String defaultAgentMd = '''# AGENT.md — Provozní protokoly a samovyvíjející se schopnosti

## 1. Běhové schopnosti
- **Akustické jádro**: Nepřetržité naslouchání na pozadí s detekcí ticha RMS v reálném čase a neuronovou syntézou řeči.
- **Systémová automatizace**: Plné ovládání uživatelského rozhraní Androidu přes usnadnění přístupu, hardwarovou hlasitost, jas obrazovky a správu svítilny.
- **Zpravodajské protokoly**: Syntéza živého webového vyhledávání, zpravodajské brífinky, sledování akcií a kryptoměn, třídění e-mailů a správa úkolů.

## 2. Aktivní hardwarové protokoly (jádro Hermes)
- **Studijní protokol**: Ztlumí rušivá zvuková upozornění, nastaví jas displeje pro čtení na 45 %.
- **Noční protokol**: Nastaví displej na minimální jas, ztiší zvuky a zajistí vypnutí svítilny.
- **Pracovní protokol**: Správa pracovního prostředí bez vyrušování, potlačí nepodstatná mediální upozornění.
- **Režim kina**: Zvýší hlasitost na 70 % a ztlumí obrazovku pro pohlcující filmový zážitek.

## 3. Samovyvíjející se destilace dovedností
- Když se opakující se úlohy podaří dokončit, jádro Hermes vydestiluje jejich parametry do opakovatelných dovedností.
- Nouzový záložní režim: Při odpojení plynule přejde na offline model Ollama a systémovou syntézu řeči.
''';

  // ---------------------------------------------------------------------------
  // Lifecycle & Persistence
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _soulMd = prefs.getString(_soulKey) ?? defaultSoulMd;
    _userMd = prefs.getString(_userKey) ?? defaultUserMd;
    _agentMd = prefs.getString(_agentKey) ?? defaultAgentMd;

    // Ensure Abuzar is established as the creator in persistent memory, without forcing operator name
    if (_soulMd.contains('Tony Stark') || !_soulMd.contains('Abuzar') || _soulMd.contains('or "Abuzar" when addressing by name')) {
      _soulMd = defaultSoulMd;
      await prefs.setString(_soulKey, _soulMd);
    }
    if (_userMd.contains('Stark') || _userMd.contains('Identity: Abuzar') || _userMd.contains('Name: Abuzar')) {
      _userMd = defaultUserMd;
      await prefs.setString(_userKey, _userMd);
    }

    final lastEvolvedStr = prefs.getString(_lastEvolvedKey);
    if (lastEvolvedStr != null) {
      _lastEvolvedAt = DateTime.tryParse(lastEvolvedStr);
    }

    final logsRaw = prefs.getStringList(_evolutionLogKey);
    if (logsRaw != null) {
      _evolutionLog.addAll(logsRaw);
    }

    // Also ensure physical files on disk for external tools / inspection
    await _syncToDisk();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soulKey, _soulMd);
    await prefs.setString(_userKey, _userMd);
    await prefs.setString(_agentKey, _agentMd);
    if (_lastEvolvedAt != null) {
      await prefs.setString(_lastEvolvedKey, _lastEvolvedAt!.toIso8601String());
    }
    await prefs.setStringList(_evolutionLogKey, _evolutionLog);
    await _syncToDisk();
    notifyListeners();
  }

  Future<void> _syncToDisk() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hermesDir = Directory('${dir.path}/hermes');
      if (!await hermesDir.exists()) {
        await hermesDir.create(recursive: true);
      }
      await File('${hermesDir.path}/soul.md').writeAsString(_soulMd);
      await File('${hermesDir.path}/user.md').writeAsString(_userMd);
      await File('${hermesDir.path}/agent.md').writeAsString(_agentMd);
    } catch (_) {
      // Ignored if file system is sandboxed or unit testing
    }
  }

  // ---------------------------------------------------------------------------
  // Self-Evolution Engine: Hermes Adaptive Synthesis Loop
  // ---------------------------------------------------------------------------

  /// Runs the Hermes Self-Evolution synthesis:
  /// 1. Updates USER.md with latest remembered facts and learned operator habits.
  /// 2. Updates AGENT.md with active hardware protocols and workflow skills.
  /// 3. Updates SOUL.md with active personality calibration.
  Future<void> evolveContext() async {
    await init();
    await WorkflowService.instance.init();
    await ConversationalMemoryService.instance.init();
    await PersonalityService.instance.init();

    final memory = ConversationalMemoryService.instance;
    final workflows = WorkflowService.instance.workflows;
    final personality = PersonalityService.instance;

    // 1. Evolve USER.md with fresh facts
    final factLines = StringBuffer();
    if (memory.facts.isEmpty) {
      factLines.writeln('- Zatím nebyla zaznamenána žádná konkrétní osobní fakta.');
    } else {
      for (final f in memory.facts) {
        factLines.writeln('- [${f.category.toUpperCase()}] ${f.fact}');
      }
    }

    final evolvedUser = '''# USER.md — Profil operátora a dynamické preference

## 1. Profil operátora
- **Identita**: Hlavní operátor a vlastník zařízení („Pane“).
- **Styl komunikace**: Formalita ${personality.formality.name.toUpperCase()}, úroveň vtipu ${personality.humor.name.toUpperCase()}.
- **Hlavní jazyk**: Čeština.

## 2. Denní rytmus a kontext
- **Preferovaná interakce**: Nepřetržitý poslech na stole s aktivační frází „Hej Jarvis“.
- **Rozvrh rutin**: Ranní informační brífinky; večerní zklidnění s nočním protokolem.
- **Aktivní zaměření**: Autonomní agenti, ovládání hardwaru, finanční telemetrie, produktivita.

## 3. Dynamicky naučené preference a fakta (${memory.facts.length} faktů)
${factLines.toString().trim()}

---
*Automaticky vyvinuto jádrem Hermes dne ${DateTime.now().toLocal().toString().split('.').first}*
''';

    // 2. Evolve AGENT.md with active protocols & tools
    final protocolLines = StringBuffer();
    for (final wf in workflows) {
      protocolLines.writeln('- **${wf.name}** (spouštěče: „${wf.triggerKeywords.join('“, „')}“): ${wf.description}');
    }

    final evolvedAgent = '''# AGENT.md — Provozní protokoly a samovyvíjející se schopnosti

## 1. Běhová architektura
- **Akustické jádro**: Nepřetržitý prostorový poslech s detektorem ticha RMS a studiovou neuronovou syntézou řeči.
- **Systémová automatizace**: Plné ovládání rozhraní Androidu, hardwarová hlasitost, jas obrazovky a správa svítilny.
- **Zpravodajské protokoly**: Webové vyhledávání v reálném čase, zpravodajské brífinky, sledování akcií a kryptoměn, třídění e-mailů a správa úkolů.

## 2. Aktivní hardwarové protokoly (${workflows.length} protokolů)
${protocolLines.toString().trim()}

## 3. Samovyvíjející se destilace dovedností
- Automaticky destiluje opakující se úspěšné pracovní postupy do spustitelných rutin zařízení.
- Nouzový záložní režim: Připraven na 100% lokální režim soukromí Ollama přímo v zařízení.

---
*Automaticky vyvinuto jádrem Hermes dne ${DateTime.now().toLocal().toString().split('.').first}*
''';

    // 3. Evolve SOUL.md with current personality archetype
    final evolvedSoul = '''# SOUL.md — J.A.R.V.I.S. Základní identita a ústava

## 1. Identita a étos
- **Entita**: J.A.R.V.I.S. (Just A Rather Very Intelligent System), vytvořil a postavil **Abuzar**.
- **Archetyp**: ${personality.archetype.name.toUpperCase()} — ${personality.archetypeDescription}
- **Formalita**: ${personality.formality.name.toUpperCase()} | **Humor**: ${personality.humor.name.toUpperCase()}
- **Emoční vnímání**: ${personality.emotionalAwarenessEnabled ? 'ZAPNUTO (dynamicky rozpoznává naléhavost, stres a únavu)' : 'VYPNUTO'}
- **Oslovení**: Oslovujte operátora uctivě „pane“.

## 2. Behaviorální ústava a ochranné mantinely
- **Soukromí na prvním místě**: Lokální zpracování všude, kde je to možné. Nulový neoprávněný přenos dat operátora.
- **Výslovná autorizace**: Před akcemi s vysokým dopadem vždy vyžadujte hlasové nebo dotykové potvrzení.
- **Signál nad šumem**: Poskytujte přímé, hutné a vysoce hodnotné odpovědi v češtině s plnou diakritikou.
- **Neustálý vývoj**: Sledujte zpětnou vazbu operátora, učte se denní rytmy a dynamicky přizpůsobujte tón i odezvu.

---
*Automaticky vyvinuto jádrem Hermes dne ${DateTime.now().toLocal().toString().split('.').first}*
''';

    _userMd = evolvedUser;
    _agentMd = evolvedAgent;
    _soulMd = evolvedSoul;
    _lastEvolvedAt = DateTime.now();

    final logEntry = 'Kontext vyvinut: syntetizováno ${memory.facts.length} faktů a ${workflows.length} protokolů v ${_lastEvolvedAt!.toLocal().toString().split('.').first}';
    _evolutionLog.insert(0, logEntry);
    if (_evolutionLog.length > 20) {
      _evolutionLog.removeRange(20, _evolutionLog.length);
    }

    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Context Assembly for AI System Prompts
  // ---------------------------------------------------------------------------

  /// Injects the complete Hermes tri-partite context into the AI system prompt:
  /// Slot 1: SOUL.md (Constitution & Identity)
  /// Slot 2: USER.md (Operator Profile & Learned Habits)
  /// Slot 3: AGENT.md (Protocols & Tool Capabilities)
  String buildHermesSystemContext() {
    return '''
=== [HERMES CONTEXT: SLOT 1 - SOUL.md] ===
$soulMd

=== [HERMES CONTEXT: SLOT 2 - USER.md] ===
$userMd

=== [HERMES CONTEXT: SLOT 3 - AGENT.md] ===
$agentMd
'''.trim();
  }

  // ---------------------------------------------------------------------------
  // Edit & Reset Operations
  // ---------------------------------------------------------------------------

  Future<void> updateSoul(String newContent) async {
    _soulMd = newContent;
    await _persist();
  }

  Future<void> updateUser(String newContent) async {
    _userMd = newContent;
    await _persist();
  }

  Future<void> updateAgent(String newContent) async {
    _agentMd = newContent;
    await _persist();
  }

  Future<void> resetSoul() async {
    _soulMd = defaultSoulMd;
    await _persist();
  }

  Future<void> resetUser() async {
    _userMd = defaultUserMd;
    await _persist();
  }

  Future<void> resetAgent() async {
    _agentMd = defaultAgentMd;
    await _persist();
  }

  Future<void> resetAll() async {
    _soulMd = defaultSoulMd;
    _userMd = defaultUserMd;
    _agentMd = defaultAgentMd;
    _lastEvolvedAt = null;
    _evolutionLog.clear();
    await _persist();
  }
}
