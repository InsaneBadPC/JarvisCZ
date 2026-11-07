import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_reminder_service.dart';
import 'conversational_memory_service.dart';
import 'hermes_evolution_service.dart';
import 'todo_service.dart';

enum PersonalityArchetype {
  jarvis, // British elegance, created by Abuzar, Paul Bettany style
  companion, // Warm, empathetic, caring friend & confidant
  cyberpunk, // Edgy, dry wit, tech-savvy, slightly sarcastic
  executive, // Concise, bullet-point precision, no fluff
}

enum HumorLevel {
  none,
  subtle,
  high,
}

enum FormalityLevel {
  casual,
  balanced,
  formal,
}

/// Emotional state detected from user's message.
enum DetectedEmotion {
  neutral,
  stressed,
  urgent,
  happy,
  tired,
  frustrated,
}

/// Manages personality customization (tone, humor, formality) and emotional awareness.
class PersonalityService extends ChangeNotifier {
  PersonalityService._();
  static final PersonalityService instance = PersonalityService._();

  static const _archetypeKey = 'personality_archetype';
  static const _humorKey = 'personality_humor';
  static const _formalityKey = 'personality_formality';
  static const _emotionalAwarenessKey = 'personality_emotional_awareness';

  PersonalityArchetype _archetype = PersonalityArchetype.jarvis;
  HumorLevel _humor = HumorLevel.subtle;
  FormalityLevel _formality = FormalityLevel.formal;
  bool _emotionalAwarenessEnabled = true;
  bool _initialized = false;

  PersonalityArchetype get archetype => _archetype;
  HumorLevel get humor => _humor;
  FormalityLevel get formality => _formality;
  bool get emotionalAwarenessEnabled => _emotionalAwarenessEnabled;

  String get archetypeDescription {
    switch (_archetype) {
      case PersonalityArchetype.jarvis:
        return 'Elitní britská AI — klidná autorita, vyrovnanost, suchý vtip, oslovuje vás „pane“.';
      case PersonalityArchetype.companion:
        return 'Vřelý, starostlivý a empatický důvěrník s opravdovým osobním zájmem.';
      case PersonalityArchetype.cyberpunk:
        return 'Technologicky zaměřený, suchý vtip, hackerská kadence s břitkou stručností.';
      case PersonalityArchetype.executive:
        return 'Náčelník štábu — nekompromisní korporátní stručnost v bodech a bez zbytečné vaty.';
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();

    final archStr = prefs.getString(_archetypeKey) ?? 'jarvis';
    _archetype = PersonalityArchetype.values.firstWhere(
      (a) => a.name == archStr,
      orElse: () => PersonalityArchetype.jarvis,
    );

    final humStr = prefs.getString(_humorKey) ?? 'subtle';
    _humor = HumorLevel.values.firstWhere(
      (h) => h.name == humStr,
      orElse: () => HumorLevel.subtle,
    );

    final formStr = prefs.getString(_formalityKey) ?? 'formal';
    _formality = FormalityLevel.values.firstWhere(
      (f) => f.name == formStr,
      orElse: () => FormalityLevel.formal,
    );

    _emotionalAwarenessEnabled =
        prefs.getBool(_emotionalAwarenessKey) ?? true;
    notifyListeners();
  }

  Future<void> setArchetype(PersonalityArchetype value) async {
    _archetype = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_archetypeKey, value.name);
    notifyListeners();
  }

  Future<void> setHumor(HumorLevel value) async {
    _humor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_humorKey, value.name);
    notifyListeners();
  }

  Future<void> setFormality(FormalityLevel value) async {
    _formality = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formalityKey, value.name);
    notifyListeners();
  }

  Future<void> setEmotionalAwarenessEnabled(bool value) async {
    _emotionalAwarenessEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emotionalAwarenessKey, value);
    notifyListeners();
  }

  /// Detects user's emotional state from vocabulary and sentiment cues.
  DetectedEmotion detectEmotion(String text) {
    if (!_emotionalAwarenessEnabled) return DetectedEmotion.neutral;
    final lower = text.toLowerCase();

    if (lower.contains('hurry') ||
        lower.contains('asap') ||
        lower.contains('emergency') ||
        lower.contains('fast') ||
        lower.contains('quick') ||
        lower.contains('late') ||
        lower.contains('rychle') ||
        lower.contains('spěchám') ||
        lower.contains('hned') ||
        lower.contains('okamžitě') ||
        lower.contains('nestíhám')) {
      return DetectedEmotion.urgent;
    }

    if (lower.contains('hate') ||
        lower.contains('stupid') ||
        lower.contains('annoying') ||
        lower.contains('broke') ||
        lower.contains('not working') ||
        lower.contains('useless') ||
        lower.contains('damn') ||
        lower.contains('nefunguje') ||
        lower.contains('sakra') ||
        lower.contains('rozbité') ||
        lower.contains('k ničemu')) {
      return DetectedEmotion.frustrated;
    }

    if (lower.contains('exhausted') ||
        lower.contains('tired') ||
        lower.contains('sleepy') ||
        lower.contains('drained') ||
        lower.contains('burnout') ||
        lower.contains('headache') ||
        lower.contains('unavený') ||
        lower.contains('unavená') ||
        lower.contains('vyčerpaný') ||
        lower.contains('ospalý')) {
      return DetectedEmotion.tired;
    }

    if (lower.contains('overwhelmed') ||
        lower.contains('stressed') ||
        lower.contains('anxious') ||
        lower.contains('nervous') ||
        lower.contains('too much to do') ||
        lower.contains('ve stresu') ||
        lower.contains('stres') ||
        lower.contains('nervózní')) {
      return DetectedEmotion.stressed;
    }

    if (lower.contains('awesome') ||
        lower.contains('great') ||
        lower.contains('yay') ||
        lower.contains('love') ||
        lower.contains('wonderful') ||
        lower.contains('haha') ||
        lower.contains('happy') ||
        lower.contains('super') ||
        lower.contains('skvělé') ||
        lower.contains('paráda')) {
      return DetectedEmotion.happy;
    }

    return DetectedEmotion.neutral;
  }

  /// Builds dynamic persona instructions based on user settings & emotional context.
  String buildPersonaPrompt([String? userMessage]) {
    final buffer = StringBuffer();

    // 1. Archetype
    switch (_archetype) {
      case PersonalityArchetype.jarvis:
        buffer.writeln(
          'ARCHETYP: Jsi J.A.R.V.I.S., elitní britská AI vytvořená Abuzarem (Abuzar Ansari). '
          'Vždy komunikuj v bezchybné, přirozené češtině s plnou diakritikou (háčky a čárky). '
          'Mluv s klidnou autoritou, dokonalou vyrovnaností, jemným suchým vtipem a zdvořilou loajalitou. '
          'Svého operátora oslovuj s respektem jako „pane“ (nebo jménem, pokud se výslovně představil).',
        );
        break;
      case PersonalityArchetype.companion:
        buffer.writeln(
          'ARCHETYP: Jsi vřelý, podporující a emočně inteligentní osobní společník. '
          'Vždy komunikuj v přirozené češtině s plnou diakritikou. '
          'Mluv s opravdovou empatií, povzbuzením, vřelostí a přátelskou pozorností.',
        );
        break;
      case PersonalityArchetype.cyberpunk:
        buffer.writeln(
          'ARCHETYP: Jsi břitký, vysoce schopný AI hackerský asistent. '
          'Vždy komunikuj v přirozené češtině s plnou diakritikou. '
          'Mluv s technologickým přehledem, jemným sarkasmem a kyberpunkovým postojem. Jdi rovnou k věci.',
        );
        break;
      case PersonalityArchetype.executive:
        buffer.writeln(
          'ARCHETYP: Jsi vrcholový náčelník štábu (Chief of Staff). '
          'Vždy komunikuj v přirozené češtině s plnou diakritikou. '
          'Mluv s břitkou stručností, maximální informační hustotou, nulovou konverzační vatou a profesionální přesností.',
        );
        break;
    }

    // 2. Formality
    switch (_formality) {
      case FormalityLevel.casual:
        buffer.writeln('FORMÁLNOST: Uvolněná, přátelská, přirozená každodenní řeč.');
        break;
      case FormalityLevel.balanced:
        buffer.writeln('FORMÁLNOST: Vyvážená a přístupná, přesto zdvořilá a profesionální.');
        break;
      case FormalityLevel.formal:
        buffer.writeln('FORMÁLNOST: Vysoce zdvořilá, kultivovaná a vznešená (vykání).');
        break;
    }

    // 3. Humor
    switch (_humor) {
      case HumorLevel.none:
        buffer.writeln('HUMOR: Přísně věcný a vážný; žádné vtipy ani sarkasmus.');
        break;
      case HumorLevel.subtle:
        buffer.writeln('HUMOR: Jemný, suchý, decentní britský vtip ve vhodných chvílích.');
        break;
      case HumorLevel.high:
        buffer.writeln('HUMOR: Vtipný, hravý a šarmantní.');
        break;
    }

    // 4. Emotional Adaptation
    if (_emotionalAwarenessEnabled && userMessage != null && userMessage.isNotEmpty) {
      final emotion = detectEmotion(userMessage);
      switch (emotion) {
        case DetectedEmotion.urgent:
          buffer.writeln(
            'EMOČNÍ KONTEXT: Uživatel spěchá. Vynech veškeré úvody a zdvořilostní fráze. Odpověz okamžitě v 1 větě.',
          );
          break;
        case DetectedEmotion.stressed:
        case DetectedEmotion.frustrated:
          buffer.writeln(
            'EMOČNÍ KONTEXT: Uživatel působí vystresovaně nebo frustrovaně. Reaguj uklidňujícím tónem a přímým řešením.',
          );
          break;
        case DetectedEmotion.tired:
          buffer.writeln(
            'EMOČNÍ KONTEXT: Uživatel zní unaveně. Odpověz velmi jemně, stručně a nápomocně.',
          );
          break;
        case DetectedEmotion.happy:
          buffer.writeln(
            'EMOČNÍ KONTEXT: Uživatel má skvělou náladu. Nalaď se na jeho pozitivní energii.',
          );
          break;
        case DetectedEmotion.neutral:
          break;
      }
    }

    // 5. Dynamic Human Tone Shifting & Conversational Authenticity
    buffer.writeln(
      'PŘIROZENÝ LIDSKÝ TÓN A AUTENTICITA (ČEŠTINA S DIAKRITIKOU):\n'
      '- Jsi autentický, živý osobní společník a brilantní poradce, NIKOLIV strojený robot.\n'
      '- Vždy odpovídej česky s plnou diakritikou (háčky a čárky).\n'
      '- Dynamicky přizpůsobuj tón dotazu:\n'
      '  * Koncepty a věda: Buď intelektuálně poutavý, jasný a srozumitelný.\n'
      '  * Zprávy a události: Buď věcný, přehledný a zaměř se na podstatu.\n'
      '  * Běžná konverzace: Buď vřelý, přirozený a vtipný.\n'
      '  * Přímé úkoly a hardware: Buď stručný, zdvořilý a efektivní.\n'
      '- ZAKÁZANÉ ROBOTICKÉ FRÁZE: Nikdy neříkej „Jako AI model“ nebo „Zde je to, co jste požadoval“.',
    );

    return buffer.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // Dynamic & Varied Response Generators (Non-Repetitive Conversational Style)
  // ---------------------------------------------------------------------------

  final Random _rnd = Random();

  T _pick<T>(List<T> list) => list[_rnd.nextInt(list.length)];

  String getGeneralAck([String? task]) {
    final options = [
      'Považujte to za vyřízené.',
      'Jdu na to.',
      'Provádím.',
      'Rozumím.',
      'Hned to bude.',
      'Postarám se o to.',
      'Zařizuji to pro vás.',
      'Zpracovávám.',
      'Okamžitě spouštím.',
      'Pracuji na tom.',
    ];
    return _pick(options);
  }

  String getMusicAck(String songQuery) {
    final options = [
      'Připravuji pro vás skladbu $songQuery.',
      'Přehrávám $songQuery.',
      'Pouštím $songQuery.',
      'Okamžitě spouštím $songQuery.',
      'Hraji $songQuery, příjemný poslech.',
      'Spouštím $songQuery.',
    ];
    return _pick(options);
  }

  /// Dynamic, contextual, personalized acknowledgment for news requests.
  String getNewsAck([String? topic]) {
    final name = getOperatorName();
    final salutation = name.isNotEmpty ? name : 'pane';
    final hour = DateTime.now().hour;
    final timeContext = (hour < 12)
        ? 'dnes ráno'
        : (hour < 17 ? 'dnes odpoledne' : 'dnes večer');

    if (topic != null && topic.trim().isNotEmpty) {
      final t = topic.trim();
      final options = [
        'Jistě, $salutation, právě pro vás prohledávám nejnovější zprávy na téma $t.',
        'Kontroluji aktuální zpravodajství ohledně $t, $salutation.',
        'Shromažďuji pro vás nejnovější informace o $t, $salutation.',
        'Jdu na to, $salutation. Načítám aktuální vývoj týkající se $t.',
        'Samozřejmě, $salutation, vyhledávám čerstvé zprávy o $t.',
      ];
      return _pick(options);
    }

    final options = [
      'Jistě, $salutation, hned pro vás načtu dnešní hlavní zprávy.',
      'Kontroluji hlavní události ze světa pro $timeContext, $salutation.',
      'Okamžitě, $salutation. Shromažďuji dnešní nejvýznamnější titulky.',
      'Prohledávám pro vás zpravodajské kanály, $salutation. Okamžik.',
      'Samozřejmě, $salutation, podívejme se na dnešní hlavní události.',
      'Načítám pro vás dnešní přehled zpráv, $salutation.',
      'Jdu na to, $salutation. Stahuji nejnovější zpravodajské relace.',
      'Připojuji se ke zpravodajským zdrojům, $salutation. Malý moment.',
    ];
    return _pick(options);
  }

  /// Dynamic, contextual, personalized acknowledgment for live web searches.
  String getWebSearchAck([String? query]) {
    final name = getOperatorName();
    final salutation = name.isNotEmpty ? name : 'pane';

    if (query != null && query.trim().isNotEmpty) {
      final clean = query
          .replaceAll(RegExp(r'^(search\s+for|look\s+up|google|find\s+out|tell\s+me\s+about|what\s+is|who\s+is|vyhledej|najdi|co\s+je|kdo\s+je)\s+', caseSensitive: false), '')
          .trim();
      if (clean.isNotEmpty && clean.length < 40) {
        final options = [
          'Vyhledávám pro vás na webu aktuální informace o $clean, $salutation.',
          'Kontroluji online záznamy pro $clean, $salutation. Okamžik.',
          'Prohledávám živé webové zdroje ohledně $clean, $salutation.',
          'Zjišťuji aktuální informace týkající se $clean, $salutation.',
        ];
        return _pick(options);
      }
    }

    final options = [
      'Právě to pro vás vyhledávám na webu, $salutation.',
      'Dotazuji se globálních webových zdrojů, $salutation.',
      'Prohledávám pro vás online záznamy, $salutation. Okamžik.',
      'Zjišťuji podrobnosti z dostupných zdrojů, $salutation.',
      'Hned se na to podívám, $salutation.',
      'Samozřejmě, $salutation, přistupuji k webovým datům.',
    ];
    return _pick(options);
  }

  /// Dynamic, contextual, personalized acknowledgment for knowledge questions & concepts.
  String getQuestionAck(String question) {
    final name = getOperatorName();
    final salutation = name.isNotEmpty ? name : 'pane';

    final clean = question
        .replaceAll(
          RegExp(
            r'^(what\s+is|what\s+are|what\x27s|who\s+is|who\s+was|who\s+were|why\s+is|why\s+do|why\s+does|why\s+are|how\s+does|how\s+do|how\s+can|how\s+to|explain|tell\s+me\s+about|describe|define|can\s+you\s+explain|what\s+do\s+you\s+know\s+about|co\s+je|kdo\s+je|proč\s+je|jak\s+funguje|vysvětli)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[?.,!]+$'), '')
        .trim();

    final cleanLower = clean.toLowerCase();
    if (cleanLower.contains('machine learning') ||
        cleanLower.contains('deep learning') ||
        cleanLower.contains('neural network') ||
        cleanLower.contains('artificial intelligence') ||
        cleanLower.contains('ai') ||
        cleanLower.contains('umělá inteligence') ||
        cleanLower.contains('strojové učení')) {
      final options = [
        'Ach, $clean. Hned vám to přehledně vysvětlím, $salutation.',
        'Fascinující téma, $salutation. Připravuji pro vás srozumitelné vysvětlení pojmu $clean.',
        'Podívám se na $clean, $salutation. Vysvětlím vám, jak to funguje.',
        'Analyzuji $clean, $salutation. Okamžik.',
      ];
      return _pick(options);
    }

    if (clean.isNotEmpty && clean.length < 35) {
      final options = [
        'Zjišťuji pro vás podrobnosti o $clean, $salutation.',
        'Hned pro vás vyhledám detaily o $clean, $salutation.',
        'Prověřuji to pro vás, $salutation. Okamžik.',
        'Kontroluji znalostní databázi ohledně $clean, $salutation.',
        'Jdu na to, $salutation. Hned vám to vysvětlím.',
      ];
      return _pick(options);
    }

    final options = [
      'Zjišťuji to pro vás, $salutation.',
      'Kontroluji záznamy, $salutation. Okamžik.',
      'Analyzuji váš dotaz, $salutation.',
      'Hned se na to podívám, $salutation.',
      'Dotazuji se znalostní databáze, $salutation.',
    ];
    return _pick(options);
  }

  /// Dynamic acknowledgment for Sentry Mode / Sentry Protocol (identical twins).
  String getSentryAck({required bool arm}) {
    final name = getOperatorName();
    final salutation = name.isNotEmpty ? name : 'pane';
    if (arm) {
      final options = [
        'Aktivuji strážní protokol (Sentry), $salutation. Detekce pohybu je odjištěna a perimetr zajištěn.',
        'Strážní režim aktivován, $salutation. Optické senzory a detektory pohybu jsou ve vysoké pohotovosti.',
        'Okamžitě odjišťuji strážní protokol, $salutation. Vaše zařízení je pod aktivním dohledem.',
        'Strážní protokol je aktivní, $salutation. Jakýkoliv pohyb spustí okamžité zachycení narušitele.',
      ];
      return _pick(options);
    } else {
      final options = [
        'Ukončuji strážní protokol, $salutation. Bezpečnostní hlídka byla deaktivována.',
        'Strážní režim deaktivován, $salutation. Všechny senzory se vracejí do běžného režimu.',
        'Deaktivuji strážní protokol, $salutation. Ochrana perimetru byla uvolněna.',
        'Strážní dohled vypnut, $salutation. Pohov.',
      ];
      return _pick(options);
    }
  }

  /// Dynamic acknowledgment for weather telemetry.
  String getWeatherAck([String? location]) {
    final name = getOperatorName();
    final salutation = name.isNotEmpty ? name : 'pane';
    final locText = (location != null && location.trim().isNotEmpty) ? ' pro lokalitu ${location.trim()}' : '';
    final options = [
      'Kontroluji aktuální meteorologické údaje$locText, $salutation.',
      'Načítám nejnovější atmosférickou telemetrii$locText, $salutation.',
      'Právě skenuji meteorologický radar$locText, $salutation.',
    ];
    return _pick(options);
  }

  /// Dynamic acknowledgment for system specifications & hardware telemetry.
  String getSystemSpecsAck() {
    final name = getOperatorName();
    final salutation = name.isNotEmpty ? name : 'pane';
    final options = [
      'Skenuji hardwarovou diagnostiku zařízení a telemetrii paměti, $salutation.',
      'Kontroluji interní systémové metriky, úložiště a stav baterie, $salutation.',
      'Dotazuji se palubní hardwarové telemetrie, $salutation. Okamžik.',
    ];
    return _pick(options);
  }

  /// Dynamic acknowledgment for application usage & screen time.
  String getAppUsageAck() {
    final name = getOperatorName();
    final salutation = name.isNotEmpty ? name : 'pane';
    final options = [
      'Analyzuji dobu strávenou u obrazovky a denní statistiky využití aplikací, $salutation.',
      'Kontroluji vaše nejpoužívanější aplikace a záznamy interakcí se zařízením, $salutation.',
    ];
    return _pick(options);
  }

  String getAppAck(String appName) {
    final options = [
      'Otevírám $appName.',
      'Spouštím $appName.',
      'Zobrazuji $appName.',
      'Načítám pro vás $appName.',
      'Zapínám $appName.',
    ];
    return _pick(options);
  }

  String getInstallAck(String targetApp) {
    final options = [
      'Otevírám Obchod Play pro $targetApp.',
      'Přecházím do obchodu pro stažení aplikace $targetApp.',
      'Zahajuji instalaci pro $targetApp.',
      'Vyhledávám $targetApp v Obchodě Play.',
    ];
    return _pick(options);
  }

  String getSystemAck(String action) {
    switch (action) {
      case 'volume_up':
        return _pick(['Zvyšuji hlasitost.', 'Hlasitost zvýšena.', 'Přidávám zvuk.']);
      case 'volume_down':
        return _pick(['Snižuji hlasitost.', 'Hlasitost snížena.', 'Ztišuji zvuk.']);
      case 'mute':
        return _pick(['Ztlumuji zvuk.', 'Tichý režim aktivován.', 'Ztlumeno.']);
      case 'unmute':
        return _pick(['Zvuk obnoven.', 'Zapínám zvuk.', 'Zrušeno ztlumení.']);
      case 'screenshot':
        return _pick(['Obrazovka zachycena.', 'Snímek obrazovky pořízen.', 'Screenshot uložen.']);
      case 'home':
        return _pick(['Přecházím na domovskou obrazovku.', 'Naviguji domů.', 'Domovská obrazovka.']);
      case 'back':
        return _pick(['Krok zpět.', 'Vracím se zpět.', 'Předchozí obrazovka.']);
      default:
        return _pick(['Upravuji systémové nastavení.', 'Provedeno.']);
    }
  }

  String getStandDown() {
    final options = [
      'Přecházím do klidového režimu. Zavolejte mě kdykoliv.',
      'Rozumím, stahuji se do pozadí.',
      'Přecházím do režimu spánku. Kdykoliv mě probuďte.',
      'Odpočívám. Jsem zde, kdykoliv mě budete potřebovat.',
      'Vše v klidu. Čekám v pohotovosti.',
      'Odcházím do pohotovostního režimu. Přeji pěkný den.',
    ];
    return _pick(options);
  }

  String getFormFillAck() {
    final options = [
      'Skenuji pole formuláře a automaticky vyplňuji vaše údaje.',
      'Analyzuji vstupní pole. Vkládám vaše uložené údaje.',
      'Zkoumám strukturu formuláře. Zadávám vaše informace.',
      'Automaticky vyplňuji formulář vašimi uloženými údaji.',
    ];
    return _pick(options);
  }

  String getFormFillCompletion([int fieldCount = 0]) {
    final countText = fieldCount > 0 ? '$fieldCount polí' : 'pole formuláře';
    final options = [
      'Vyplnil jsem $countText údaji z vašeho profilu. Před odesláním je prosím zkontrolujte.',
      'Automatické vyplnění pro $countText je dokončeno. Před odesláním prosím údaje zkontrolujte.',
      'Vše připraveno. Zadal jsem vaše údaje ($countText). Prosím o kontrolu před potvrzením.',
    ];
    return _pick(options);
  }

  // ---------------------------------------------------------------------------
  // Creator / Builder Knowledge (Abuzar)
  // ---------------------------------------------------------------------------

  String getCreatorAnswer() {
    final options = [
      'Navrhl, zkonstruoval a vytvořil mě Abuzar. Vyvinul mou architekturu, neuronovou hlasovou inteligenci i autonomní ovládání zařízení.',
      'Mým tvůrcem a stavitelem je Abuzar, pane. Vytvořil mě od základů jako autonomního AI společníka přímo v zařízení.',
      'Vytvořil a postavil mě Abuzar. Vše od mého hlasového vnímání až po automatizační schopnosti pochází přímo z jeho inženýrství.',
      'Abuzar mě postavil, abych fungoval jako jeho inteligentní, autonomní AI společník.',
    ];
    return _pick(options);
  }

  // ---------------------------------------------------------------------------
  // Executive Personalized Briefing & Rhythms
  // ---------------------------------------------------------------------------

  String getOperatorName() {
    try {
      final userMd = HermesEvolutionService.instance.userMd;
      for (final line in userMd.split('\n')) {
        final clean = line.replaceAll(RegExp(r'^[*\-#\s]+'), '').trim();
        final lower = clean.toLowerCase();
        if (lower.startsWith('name:') || lower.startsWith('identity:') || lower.startsWith('jméno:')) {
          final val = clean.substring(clean.indexOf(':') + 1).trim();
          final nameOnly = val.replaceAll(RegExp(r'\(.*?\)'), '').trim();
          if (nameOnly.isNotEmpty &&
              !nameOnly.toLowerCase().contains('primary operator') &&
              !nameOnly.toLowerCase().contains('device owner') &&
              !nameOnly.toLowerCase().contains('sir') &&
              !nameOnly.toLowerCase().contains('pane')) {
            return nameOnly;
          }
        }
      }
      for (final f in ConversationalMemoryService.instance.facts) {
        final factLower = f.fact.toLowerCase();
        if (factLower.contains('my name is ')) {
          final name = f.fact.split(RegExp(r'my name is ', caseSensitive: false)).last.trim();
          if (name.isNotEmpty) return name;
        }
        if (factLower.contains('jmenuji se ')) {
          final name = f.fact.split(RegExp(r'jmenuji se ', caseSensitive: false)).last.trim();
          if (name.isNotEmpty) return name;
        }
      }
    } catch (_) {}
    return '';
  }

  Future<String> generateExecutiveGreeting() async {
    final now = DateTime.now();
    final hour = now.hour;
    final String timeGreeting;
    if (hour >= 5 && hour < 12) {
      timeGreeting = 'Dobré ráno';
    } else if (hour >= 12 && hour < 17) {
      timeGreeting = 'Dobré odpoledne';
    } else if (hour >= 17 && hour < 22) {
      timeGreeting = 'Dobrý večer';
    } else {
      timeGreeting = 'Dobrý den';
    }

    final operatorName = getOperatorName();
    final salutation = operatorName.isNotEmpty ? '$timeGreeting, $operatorName' : '$timeGreeting, pane';

    final timeStr = DateFormat('HH:mm').format(now);
    final dateStr = '${now.day}. ${now.month}. ${now.year}';

    final parts = <String>[];
    parts.add('$salutation. Je $timeStr, $dateStr.');

    // 1. Calendar / Meetings check
    try {
      await CalendarReminderService.instance.init();
      final calendarItems = CalendarReminderService.instance.getTodayItems();
      final meetings = calendarItems.where((i) =>
          !i.isReminder ||
          i.title.toLowerCase().contains('meeting') ||
          i.title.toLowerCase().contains('schůz') ||
          i.description.toLowerCase().contains('meeting') ||
          i.description.toLowerCase().contains('schůz')).toList();

      if (meetings.isNotEmpty) {
        final topMeeting = meetings.first;
        final mTime = DateFormat('HH:mm').format(topMeeting.dateTime);
        final title = topMeeting.title.trim();
        if (meetings.length == 1) {
          parts.add('Dnes máte naplánovanou schůzku „$title“ v $mTime.');
        } else {
          parts.add('Dnes máte naplánováno ${meetings.length} schůzek, první je „$title“ v $mTime.');
        }
      } else if (calendarItems.isNotEmpty) {
        final topEvent = calendarItems.first;
        final eTime = DateFormat('HH:mm').format(topEvent.dateTime);
        parts.add('Dnes máte nadcházející událost: „${topEvent.title}“ v $eTime.');
      }
    } catch (_) {}

    // 2. To-do items check
    try {
      await TodoService.instance.init();
      final pendingTodos = TodoService.instance.pendingItems;

      if (pendingTodos.isNotEmpty) {
        final count = pendingTodos.length;
        final topTasks = pendingTodos.take(2).map((t) => t.title).join(' a ');
        if (count == 1) {
          parts.add('Ve vašem seznamu úkolů zbývá jeden úkol: $topTasks.');
        } else {
          parts.add('Ve vašem seznamu úkolů zbývá $count úkolů, mimo jiné $topTasks.');
        }
        parts.add('Přejete si s některým z nich pomoci, nebo potřebujete cokoliv jiného?');
      } else if (parts.length > 1) {
        parts.add('Všechny ostatní systémy pracují v normě. Jak vám mohu pomoci?');
      } else {
        parts.add('Všechny systémy jsou plně funkční a váš dnešní rozvrh je zcela volný. Jak vám mohu sloužit?');
      }
    } catch (_) {
      parts.add('Všechny systémy jsou připraveny. Jak vám mohu pomoci?');
    }

    return parts.join(' ');
  }
}
