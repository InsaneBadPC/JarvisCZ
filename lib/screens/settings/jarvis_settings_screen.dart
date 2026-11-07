import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../services/app_usage_service.dart';
import '../../services/commute_traffic_service.dart';
import '../../services/conversational_memory_service.dart';
import '../../services/hermes_evolution_service.dart';
import '../../services/jarvis_service.dart';
import '../../services/macro_recorder_service.dart';
import '../../services/personality_service.dart';
import '../../services/phone_storage_service.dart';
import '../../services/proactive_agent_service.dart';
import '../../services/sentry_service.dart';
import '../../services/code_black_service.dart';
import '../../services/floating_copilot_service.dart';
import '../../services/settings_service.dart';
import '../../services/smart_home_service.dart';
import '../../services/system_diagnostics_service.dart';
import '../../services/vision_perception_service.dart';
import '../../services/voice_service.dart';
import '../../services/workflow_service.dart';
import '../../widgets/air_gestures_hud_widget.dart';
import '../../widgets/airspace_radar_dialog.dart';
import '../../widgets/arc_reactor_charging_dialog.dart';
import '../../widgets/network_audit_dialog.dart';
import '../../widgets/optical_solver_dialog.dart';
import '../../widgets/polyglot_diplomat_dialog.dart';
import '../security/code_black_screen.dart';
import 'permissions_screen.dart';

/// Dedicated configuration suite for all J.A.R.V.I.S. autonomous capabilities:
/// - Always-On Voice & Speech Synthesis
/// - Personality & Emotional Intelligence
/// - Self-Evolving Workflows (Hermes Engine)
/// - Conversational Memory & Data Governance
/// - Hermes Self-Evolving tri-partite context (SOUL.md, USER.md, AGENT.md)
class JarvisSettingsScreen extends StatefulWidget {
  const JarvisSettingsScreen({super.key});

  @override
  State<JarvisSettingsScreen> createState() => _JarvisSettingsScreenState();
}

class _JarvisSettingsScreenState extends State<JarvisSettingsScreen> {
  final _settings = SettingsService.instance;
  final _hermes = HermesEvolutionService.instance;

  @override
  void initState() {
    super.initState();
    _hermes.init().then((_) {
      if (mounted) setState(() {});
    });
    _hermes.addListener(_onHermesChanged);
    SentryService.instance.addListener(_onHermesChanged);
  }

  @override
  void dispose() {
    _hermes.removeListener(_onHermesChanged);
    SentryService.instance.removeListener(_onHermesChanged);
    super.dispose();
  }

  void _onHermesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 16,
                color: Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'J.A.R.V.I.S.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          _sectionTitle('Obrazovka JARVIS (vizuální styl HUD)'),
          _screenStyleCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('Stálý hlasový poslech a syntéza řeči'),
          _voiceCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('Osobnost a emoční inteligence'),
          _personalityCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('Samovyvíjející se pracovní postupy (jádro Hermes)'),
          _workflowsCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('🛡️ Režim hlídky (taktický hlídač proti krádeži)'),
          _sentryCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('⚡ Plovoucí HUD obloukového reaktoru (systémový hologram)'),
          _arcReactorHudCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('📁 Přímé úložiště a systémová telemetrie (bez klepání na UI)'),
          _directToolsCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('👁️ „Oko Jarvise“ — Multimodální vnímání kamerou'),
          _jarvisEyeCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('🚀 Starkovy superschopnosti a kybernetická sada'),
          _starkSuperpowersCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('🪄 Autonomní „Záznamník maker“ (dovednosti Hermes)'),
          _macroRecorderCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('🏠 Chytrá domácnost a IoT automatizace (Home Assistant)'),
          _smartHomeCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('🗺️ Proaktivní dojíždění a dopravní varování v reálném čase'),
          _commuteCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('🗣️ Proaktivní autonomní hlas a plánovaná připomenutí'),
          _proactiveVoiceCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('Správa paměti a soukromí'),
          _privacyCard(theme),
          const SizedBox(height: 20),
          _sectionTitle('Samovyvíjející se kontext Hermes (SOUL, USER, AGENT)'),
          _hermesEvolutionCard(theme),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // 0. JARVIS Screen (Visual Style) Card
  // ---------------------------------------------------------------------------
  Widget _screenStyleCard(ThemeData theme) {
    final currentStyle = _settings.jarvisScreenStyle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.view_in_ar_rounded,
                    size: 20,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Režim obrazovky JARVIS',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vyberte si vizuální hologramové zobrazení pro režim JARVIS',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _screenStyleOption(
                    theme: theme,
                    title: 'Obloukový reaktor',
                    subtitle: '3D sférické jádro a gyroskop',
                    icon: Icons.blur_circular_rounded,
                    isSelected: currentStyle == JarvisScreenStyle.arcReactor,
                    onTap: () async {
                      await _settings.setJarvisScreenStyle(JarvisScreenStyle.arcReactor);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _screenStyleOption(
                    theme: theme,
                    title: 'Jarvis',
                    subtitle: '3D hologram obleku Iron Mana',
                    icon: Icons.accessibility_new_rounded,
                    isSelected: currentStyle == JarvisScreenStyle.jarvis,
                    onTap: () async {
                      await _settings.setJarvisScreenStyle(JarvisScreenStyle.jarvis);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenStyleOption({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const activeColor = Color(0xFF00E5FF);
    final borderColor = isSelected ? activeColor : theme.colorScheme.outline.withValues(alpha: 0.25);
    final bgColor = isSelected
        ? activeColor.withValues(alpha: 0.12)
        : (theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant,
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: isSelected ? activeColor : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? activeColor : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Voice & Speech Synthesis Card
  // ---------------------------------------------------------------------------
  Widget _voiceCard(ThemeData theme) {
    final neuralVoiceOptions = [
      ('cs-CZ-AntoninNeural', 'Antonín (Český neurální – autentický Jarvis CZ)', 'Kultivovaný český studiový mužský hlas'),
      ('cs-CZ-VlastaNeural', 'Vlasta (Český neurální – F.R.I.D.A.Y. CZ)', 'Přirozený český ženský neurální hlas'),
      ('en-GB-RyanNeural', 'Ryan (Britský neurální – autentický Jarvis)', 'Styl Paula Bettanyho, vřelý, výmluvný a lidský'),
      ('en-GB-ThomasNeural', 'Thomas (Britský neurální – konverzační)', 'Přirozená britská kadence a plynulé frázování'),
      ('en-US-GuyNeural', 'Guy (Americký neurální – studiový mužský)', 'Kultivovaný, autoritativní tón amerického hlasatele'),
      ('en-US-ChristopherNeural', 'Christopher (Americký neurální – sebejistý)', 'Přímý, čistý a soustředěný'),
      ('en-IE-EmilyNeural', 'Emily (Irský neurální – F.R.I.D.A.Y.)', 'Okouzlující, svěží irský přízvuk'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always-on Hands-free toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Stálý nepřetržitý poslech',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Stolní režim: tiše naslouchá na pozadí, ignoruje ruch v místnosti a probudí se na „Hey Jarvis“',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.jarvisAlwaysOn,
              onChanged: (val) async {
                await _settings.setJarvisAlwaysOn(val);
                if (val) {
                  JarvisService.instance.ensureAlwaysOnRunning();
                } else {
                  JarvisService.instance.stopAlwaysOn();
                }
                setState(() {});
              },
            ),
            const Divider(height: 24),

            // Ultra-Realistic Neural Voice Toggle & Selector
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Ultrarealistický studiový neurální hlas',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Přirozená syntéza lidského hlasu ve vysílací kvalitě (automatická záloha offline)',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.useNeuralVoice,
              onChanged: (val) async {
                await _settings.setUseNeuralVoice(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 8),

            const Text(
              'Hlasový model a osobnost',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Vyberte studiový lidský hlas pro mluvené odpovědi Jarvise.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _settings.jarvisNeuralVoice,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: neuralVoiceOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt.$1,
                        child: Text(
                          opt.$2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newVoice) async {
                      if (newVoice != null) {
                        await _settings.setJarvisNeuralVoice(newVoice);
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Otestovat hlas',
                  icon: const Icon(Icons.volume_up_rounded, size: 22),
                  onPressed: () async {
                    await VoiceService.instance.speak(
                      'Všechny systémy jsou plně funkční, pane. Čekám na váš rozkaz.',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Personality & Tone Card
  // ---------------------------------------------------------------------------
  Widget _personalityCard(ThemeData theme) {
    final personality = PersonalityService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Archetyp osobnosti',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              personality.archetypeDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<PersonalityArchetype>(
              segments: const [
                ButtonSegment(
                  value: PersonalityArchetype.jarvis,
                  label: Text('JARVIS', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.shield_outlined, size: 16),
                ),
                ButtonSegment(
                  value: PersonalityArchetype.companion,
                  label: Text('Přítel', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.favorite_outline, size: 16),
                ),
                ButtonSegment(
                  value: PersonalityArchetype.cyberpunk,
                  label: Text('Kyber', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.terminal, size: 16),
                ),
                ButtonSegment(
                  value: PersonalityArchetype.executive,
                  label: Text('Manažer', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.business_center_outlined, size: 16),
                ),
              ],
              selected: {personality.archetype},
              onSelectionChanged: (val) async {
                await personality.setArchetype(val.first);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Formálnost a kadence',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            SegmentedButton<FormalityLevel>(
              segments: const [
                ButtonSegment(
                  value: FormalityLevel.casual,
                  label: Text('Neformální', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: FormalityLevel.balanced,
                  label: Text('Vyvážená', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: FormalityLevel.formal,
                  label: Text('Formální', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {personality.formality},
              onSelectionChanged: (val) async {
                await personality.setFormality(val.first);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Humor a vtip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            SegmentedButton<HumorLevel>(
              segments: const [
                ButtonSegment(
                  value: HumorLevel.none,
                  label: Text('Žádný', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: HumorLevel.subtle,
                  label: Text('Jemný', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: HumorLevel.high,
                  label: Text('Vysoký důvtip', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {personality.humor},
              onSelectionChanged: (val) async {
                await personality.setHumor(val.first);
                setState(() {});
              },
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Emoční inteligence a vnímání',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Rozpoznává naléhavost, stres a únavu z formulací a dynamicky přizpůsobuje konverzační empatii',
                style: TextStyle(fontSize: 12),
              ),
              value: personality.emotionalAwarenessEnabled,
              onChanged: (val) async {
                await personality.setEmotionalAwarenessEnabled(val);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Self-Evolving Workflows Card (Hermes Engine)
  // ---------------------------------------------------------------------------
  Widget _workflowsCard(ThemeData theme) {
    final workflows = WorkflowService.instance.workflows;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Samovyvíjející se dovednosti a pracovní postupy',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Jádro Hermes: automaticky rozpoznává záměr uživatele a zapojuje hardwarové protokoly',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.jarvisWorkflowsEnabled,
              onChanged: (val) async {
                await _settings.setJarvisWorkflowsEnabled(val);
                setState(() {});
              },
            ),
            if (_settings.jarvisWorkflowsEnabled) ...[
              const SizedBox(height: 8),
              Text(
                'AKTIVNÍ HARDWAROVÉ PROTOKOLY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              for (final wf in workflows) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        wf.id == 'study'
                            ? Icons.school_outlined
                            : (wf.id == 'night'
                                ? Icons.bedtime_outlined
                                : (wf.id == 'cinema'
                                    ? Icons.movie_outlined
                                    : Icons.work_outline)),
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wf.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              wf.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hlasový spouštěč: „${wf.triggerKeywords.take(3).join('“, „')}“',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          await WorkflowService.instance.executeWorkflow(wf);
                          await VoiceService.instance
                              .speak(wf.spokenConfirmation);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Spuštěno: ${wf.name}'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child:
                            const Text('Otestovat', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3a-1. Sentry Mode (Tactical Anti-Theft Watchdog) Card
  // ---------------------------------------------------------------------------
  Widget _sentryCard(ThemeData theme) {
    final sentry = SentryService.instance;
    final isArmed = sentry.isArmed;
    final ownerChat = _settings.telegramOwnerChatId;
    final hasTelegram = ownerChat.isNotEmpty;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isArmed
              ? const Color(0xFFFF5252).withValues(alpha: 0.7)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isArmed ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isArmed
                        ? const Color(0xFFFF5252).withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isArmed ? Icons.shield : Icons.shield_outlined,
                    color: isArmed ? const Color(0xFFFF5252) : theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taktický hlídač Sentry',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isArmed
                            ? 'AKTIVOVÁNO // Monitorování akcelerometru a perimetru'
                            : 'POHOTOVOST // Pohybové senzory deaktivovány',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isArmed ? const Color(0xFFFF5252) : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isArmed,
                  activeThumbColor: const Color(0xFFFF5252),
                  onChanged: (val) async {
                    if (val) {
                      await sentry.armSentry();
                    } else {
                      await sentry.disarmSentry();
                    }
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Aktivovaný hlídač detekuje neoprávněnou manipulaci, vysloví důrazné bezpečnostní varování, tiše pořídí snímek přední kamerou a okamžitě odešle fotografii do spárovaného terminálu Telegram.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasTelegram
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasTelegram
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.amber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasTelegram ? Icons.telegram : Icons.warning_amber_rounded,
                    color: hasTelegram ? Colors.greenAccent : Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasTelegram
                          ? 'Spojení s Telegramem: Připojeno (ID chatu: $ownerChat)'
                          : 'Spojení s Telegramem: Nespárováno. Nastavte v Nastavení pro odesílání fotografií.',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasTelegram ? Colors.greenAccent : Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (sentry.lastBreachTime != null) ...[
              const SizedBox(height: 10),
              Text(
                'Poslední narušení bezpečnosti: ${sentry.lastBreachTime}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFFF5252), fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3a-2. Floating Arc-Reactor HUD Hologram Card
  // ---------------------------------------------------------------------------
  Widget _arcReactorHudCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Color(0xFF00E5FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plovoucí HUD obloukového reaktoru',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Systémové holografické překrytí',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF00E5FF),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Přepnout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (await FlutterOverlayWindow.isActive()) {
                      await FlutterOverlayWindow.closeOverlay();
                    } else {
                      final granted = await FlutterOverlayWindow.isPermissionGranted();
                      if (!granted) {
                        await FlutterOverlayWindow.requestPermission();
                      }
                      await FlutterOverlayWindow.showOverlay(
                        enableDrag: true,
                        overlayTitle: 'J.A.R.V.I.S. HUD',
                        overlayContent: 'Jádro Starkova obloukového reaktoru aktivní',
                        flag: OverlayFlag.defaultFlag,
                        visibility: NotificationVisibility.visibilityPublic,
                        positionGravity: PositionGravity.auto,
                        width: 110,
                        height: 110,
                      );
                    }
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Plave nad jakýmkoliv prohlížečem či aplikací. V pohotovostním režimu svítí azurově, při poslechu vašeho hlasu se zbarví do smaragdově zelené a při výpočtech či mluvení přechází do solární zlaté.\n\nKlepnutím na „Shrnout obrazovku“ na libovolné webové stránce nebo článku získáte výstižný manažerský souhrn přednesený nahlas systémem J.A.R.V.I.S.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3a-3. Direct Storage & Telemetry (No UI Taps) Card
  // ---------------------------------------------------------------------------
  Widget _directToolsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.speed, color: Colors.tealAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Přímé nástroje hardwaru a úložiště',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Nulové klepání na UI // Nativní systémová API',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.tealAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'J.A.R.V.I.S. již při běžných diagnostických úlohách neprochází nastavení telefonu ani neklepe na obrazovku. Hardwarové specifikace, nejpoužívanější aplikace, statistiky času u obrazovky a vytváření souborů v souborovém systému probíhají přímo přes nativní API systému Android.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.memory, size: 14),
                  label: const Text('Zkontrolovat specifikace', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    final spoken = await SystemDiagnosticsService.instance.getDiagnosticsSpoken();
                    await VoiceService.instance.speak(spoken);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(spoken), duration: const Duration(seconds: 4)),
                      );
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.apps, size: 14),
                  label: const Text('Hlavní aplikace', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    final spoken = await AppUsageService.instance.getInstalledAppsSpoken();
                    await VoiceService.instance.speak(spoken);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(spoken), duration: const Duration(seconds: 3)),
                      );
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.pie_chart_outline, size: 14),
                  label: const Text('Čas u obrazovky', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    final spoken = await AppUsageService.instance.getTopUsedAppsSpoken();
                    await VoiceService.instance.speak(spoken);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(spoken), duration: const Duration(seconds: 4)),
                      );
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.note_add_outlined, size: 14),
                  label: const Text('Zapsat soubor písně', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    const song = 'Elektrické horizonty od J.A.R.V.I.S.\nNeon pulzuje titanovým rámem...';
                    final res = await PhoneStorageService.instance.createFile(
                      fileName: 'song.txt',
                      content: song,
                      folder: 'Download',
                    );
                    const msg = 'Soubor song.txt byl vytvořen přímo ve složce Download!';
                    await VoiceService.instance.speak('Vytvořil jsem soubor song.txt přímo ve vaší složce Stažené soubory, pane.');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['success'] == true ? msg : 'Chyba: ${res['message']}')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3b. "Jarvis Eye" Multimodal Camera & Optical Perception Card
  // ---------------------------------------------------------------------------
  Widget _jarvisEyeCard(ThemeData theme) {
    final vision = VisionPerceptionService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Optické vnímání Oko Jarvise',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Okamžitý snímek kamerou a optická analýza v reálném čase (zkoumá objekty, dokumenty, fyzické chyby, účtenky, desky plošných spojů) s vizuální syntézou LLM',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.jarvisEyeEnabled,
              onChanged: (val) async {
                await _settings.setJarvisEyeEnabled(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: vision.isInspecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.remove_red_eye_outlined, size: 18),
                label: Text(vision.isInspecting
                    ? 'Skenování optického cíle...'
                    : 'Otestovat snímek Oka Jarvise'),
                onPressed: vision.isInspecting
                    ? null
                    : () async {
                        final result = await vision.inspectOpticalSnapshot();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.spokenSummary),
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          setState(() {});
                        }
                      },
              ),
            ),
            if (vision.lastResult != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.radar_outlined,
                          size: 14,
                          color: Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'NEJNOVĚJŠÍ OPTICKÁ TELEMETRIE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF00E5FF),
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${vision.lastResult!.timestamp.hour.toString().padLeft(2, '0')}:${vision.lastResult!.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF00E5FF),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vision.lastResult!.spokenSummary,
                      style: const TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3b-2. Stark Superpowers & Cyber Suite Card
  // ---------------------------------------------------------------------------
  Widget _starkSuperpowersCard(ThemeData theme) {
    const cyan = Color(0xFF00E5FF);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: cyan, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Taktická sada Starkových superschopností',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Bezdotyková gesta přiblížení, telemetrie připojení obloukového reaktoru, živý diplomatický hlasový překlad, radar vzdušného prostoru nad hlavou a kybernetický bezpečnostní audit sítě.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const Divider(height: 24),

            // 1. Air Gestures
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pan_tool_outlined, color: cyan),
              title: const Text('Bezdotyková vzdušná gesta Iron Mana'),
              subtitle: const Text('Mávnutím nebo podržením ruky nad senzorem přiblížení přeskočíte skladbu, pozastavíte přehrávání nebo pořídíte snímek obrazovky'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan.withValues(alpha: 0.15),
                  foregroundColor: cyan,
                  side: const BorderSide(color: cyan, width: 1.0),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.65),
                    builder: (_) => const AirGesturesHudWidget(),
                  );
                },
                child: const Text('Vzdušný HUD'),
              ),
            ),
            const SizedBox(height: 8),

            // 2. Arc Reactor Charging Telemetry
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt, color: Color(0xFFFFD54F)),
              title: const Text('Telemetrie nabíjení obloukového reaktoru'),
              subtitle: const Text('Filmový zářící HUD a hlasová telemetrie výkonu při připojení nabíječky'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFFFFD54F),
                  side: const BorderSide(color: Color(0xFFFFD54F), width: 1.0),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.7),
                    builder: (_) => const ArcReactorChargingDialog(),
                  );
                },
                child: const Text('Otestovat HUD'),
              ),
            ),
            const SizedBox(height: 8),

            // 3. Polyglot Diplomat
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.translate, color: Color(0xFF64B5F6)),
              title: const Text('Polyglotní diplomat (živý překladač)'),
              subtitle: const Text('Obousměrný hlasový tlumočník v reálném čase mezi více než 14 světovými jazyky'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFF64B5F6),
                  side: const BorderSide(color: Color(0xFF64B5F6), width: 1.0),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.65),
                    builder: (_) => const PolyglotDiplomatDialog(),
                  );
                },
                child: const Text('Přeložit'),
              ),
            ),
            const SizedBox(height: 8),

            // 4. Code Black Deceptive Lockout
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_person_outlined, color: Colors.redAccent),
              title: const Text('Klamné uzamčení „Kód Černá“'),
              subtitle: const Text('Simuluje katastrofální selhání jádra systému. Odemknutí: 4 klepnutí v pravém horním rohu nebo hlasovým příkazem'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.18),
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.0),
                ),
                onPressed: () {
                  CodeBlackService.instance.arm();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CodeBlackScreen()),
                  );
                },
                child: const Text('Aktivovat'),
              ),
            ),
            const SizedBox(height: 8),

            // 5. Floating Co-Pilot
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_in_picture_alt, color: Color(0xFFBA68C8)),
              title: const Text('Holografický plovoucí kopilot'),
              subtitle: const Text('Univerzální bublina obloukového reaktoru nad ostatními aplikacemi (WhatsApp, Chrome, Amazon)'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA68C8).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFFBA68C8),
                  side: const BorderSide(color: Color(0xFFBA68C8), width: 1.0),
                ),
                onPressed: () async {
                  await FloatingCopilotService.instance.activateOverlay();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Překrytí plovoucího kopilota je aktivní na obrazovce'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Spustit'),
              ),
            ),
            const SizedBox(height: 8),

            // 6. Overhead Airspace Radar
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radar, color: Color(0xFF00E676)),
              title: const Text('Radar vzdušného prostoru a satelitů'),
              subtitle: const Text('„Jarvisi, co to nade mnou letí?“ — Živé lety ADS-B a orbitální přelety ISS'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFF00E676),
                  side: const BorderSide(color: Color(0xFF00E676), width: 1.0),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.7),
                    builder: (_) => const AirspaceRadarDialog(),
                  );
                },
                child: const Text('Radar'),
              ),
            ),
            const SizedBox(height: 8),

            // 7. Optical HUD Solver
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.document_scanner_outlined, color: Color(0xFFFFB300)),
              title: const Text('Optický HUD řešitel v reálném čase'),
              subtitle: const Text('Namiřte kameru na matematické rovnice, výpisy chyb na monitoru nebo rozpočítání účtu z restaurace'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFFFFB300),
                  side: const BorderSide(color: Color(0xFFFFB300), width: 1.0),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.7),
                    builder: (_) => const OpticalSolverDialog(),
                  );
                },
                child: const Text('Řešit v AR'),
              ),
            ),
            const SizedBox(height: 8),

            // 8. Network Cyber Security Audit
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security, color: cyan),
              title: const Text('Bezpečnost sítě a skener Wi-Fi'),
              subtitle: const Text('Prohledá místní podsíť, analyzuje MAC adresy v ARP, prověří RTSP IP kamery a porty SSH'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan.withValues(alpha: 0.15),
                  foregroundColor: cyan,
                  side: const BorderSide(color: cyan, width: 1.0),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.7),
                    builder: (_) => const NetworkAuditDialog(),
                  );
                },
                child: const Text('Audit LAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3c. Autonomous "Macro Recorder" (Hermes Skills) Card
  // ---------------------------------------------------------------------------
  Widget _macroRecorderCard(ThemeData theme) {
    final recorder = MacroRecorderService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Autonomní nahrávání maker',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Zaznamenávejte sekvence uživatelských interakcí napříč aplikacemi pomocí událostí přístupnosti a ukládejte je jako pojmenované spustitelné dovednosti do AGENT.md',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.macroRecorderEnabled,
              onChanged: (val) async {
                await _settings.setMacroRecorderEnabled(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            if (recorder.isRecording) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          size: 14,
                          color: Color(0xFFFF5252),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'NAHRÁVÁNÍ: „${recorder.activeMacroGoal}“',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF5252),
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Předveďte akce v libovolné aplikaci. Události přístupnosti se mapují na jednotlivé kroky úlohy.',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                        ),
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text('Zastavit a uložit do AGENT.md'),
                        onPressed: () async {
                          final skill = await recorder.stopRecording();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Dovednost „${skill?.goal}“ byla uložena do AGENT.md!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.fiber_manual_record_outlined, size: 16),
                  label: const Text('Spustit nahrávání ukázky makra'),
                  onPressed: () {
                    _showStartMacroDialog();
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'ULOŽENÉ MAKRO DOVEDNOSTI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${recorder.recordedMacros.length} uloženo',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recorder.recordedMacros.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Zatím nebyla nahrána žádná makra. Klepněte na „Spustit nahrávání“ nebo řekněte „Jarvisi, nahraj makro <název>“ a předveďte autonomní dovednost.',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              )
            else
              ...recorder.recordedMacros.take(5).map(
                    (skill) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_outlined, size: 16, color: Color(0xFFBA68C8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skill.goal,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${skill.steps.length} dílčích akcí • Použito ${skill.successCount}×',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow_outlined, size: 20),
                            tooltip: 'Přehrát makro',
                            onPressed: () async {
                              await recorder.replaySkill(skill);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Smazat makro',
                            onPressed: () async {
                              await recorder.deleteSkill(skill.id);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showStartMacroDialog() {
    final controller = TextEditingController(text: 'Otevřít Spotify a přehrát tréninkový playlist');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nahrát nové autonomní makro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zadejte cíl tohoto makra v přirozeném jazyce. Jakmile nahrávání začne, proveďte příslušné akce v libovolné aplikaci v telefonu:',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Cíl makra',
                border: OutlineInputBorder(),
                hintText: 'např. Objednat obvyklou kávu ve Starbucks',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.fiber_manual_record, size: 16),
            label: const Text('Spustit nahrávání'),
            onPressed: () async {
              final goal = controller.text.trim();
              Navigator.pop(ctx);
              if (goal.isNotEmpty) {
                await MacroRecorderService.instance.startRecording(goal);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3d. Smart Home & IoT Automation Card
  // ---------------------------------------------------------------------------
  Widget _smartHomeCard(ThemeData theme) {
    final smartHome = SmartHomeService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Ovládání chytré domácnosti a IoT',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Místní síťové ovládání přes REST/webhooky pro Home Assistant (světla, vypínače, scény) s hlasovými spouštěči a integrací do Nočního/Kino protokolu',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.smartHomeEnabled,
              onChanged: (val) async {
                await _settings.setSmartHomeEnabled(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _settings.homeAssistantUrl,
              decoration: const InputDecoration(
                labelText: 'Základní URL adresa Home Assistant',
                hintText: 'http://homeassistant.local:8123',
                prefixIcon: Icon(Icons.link, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) async {
                await _settings.setHomeAssistantUrl(val);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: _settings.homeAssistantToken,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Dlouhodobý přístupový token (Bearer)',
                hintText: 'eyJhbGciOi...',
                prefixIcon: Icon(Icons.key_outlined, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) async {
                await _settings.setHomeAssistantToken(val);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: _settings.smartHomeDefaultEntity,
              decoration: const InputDecoration(
                labelText: 'Výchozí ID cílové entity',
                hintText: 'light.living_room',
                prefixIcon: Icon(Icons.lightbulb_outline, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) async {
                await _settings.setSmartHomeDefaultEntity(val);
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: smartHome.isConnecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check, size: 16),
                    label: const Text('Otestovat připojení', style: TextStyle(fontSize: 12)),
                    onPressed: smartHome.isConnecting
                        ? null
                        : () async {
                            final res = await smartHome.checkConnection();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.message),
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              setState(() {});
                            }
                          },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    await smartHome.turnOn();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Odeslán signál pro zapnutí světla'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Zapnout', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    await smartHome.turnOff();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Odeslán signál pro vypnutí světla'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Vypnout', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3e. Proactive Commute & Real-Time Traffic Warnings Card
  // ---------------------------------------------------------------------------
  Widget _commuteCard(ThemeData theme) {
    final commute = CommuteTrafficService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Proaktivní dojíždění a dopravní varování',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Vypočítává dobu jízdy v reálném čase a dopravní špičku v návaznosti na schůzky v kalendáři, aby vás včas upozornil, kdy vyrazit',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.proactiveCommuteEnabled,
              onChanged: (val) async {
                await _settings.setProactiveCommuteEnabled(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _settings.commuteHomeAddress,
              decoration: const InputDecoration(
                labelText: 'Adresa domova / výchozího místa',
                hintText: 'např. Václavské náměstí 1 nebo Centrum',
                prefixIcon: Icon(Icons.home_outlined, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) async {
                await _settings.setCommuteHomeAddress(val);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: _settings.commuteWorkAddress,
              decoration: const InputDecoration(
                labelText: 'Práce / standardní cíl',
                hintText: 'např. Technologický park nebo Stark Tower',
                prefixIcon: Icon(Icons.business_outlined, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) async {
                await _settings.setCommuteWorkAddress(val);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: commute.isChecking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.directions_car_outlined, size: 16),
                label: Text(commute.isChecking
                    ? 'Výpočet živé trasy...'
                    : 'Zkontrolovat dojíždění a dopravu'),
                onPressed: commute.isChecking
                    ? null
                    : () async {
                        final status = await commute.checkCommute();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(status.spokenSummary),
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          setState(() {});
                        }
                      },
              ),
            ),
            if (commute.lastStatus != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.traffic_outlined,
                          size: 15,
                          color: commute.lastStatus!.trafficSeverity == TrafficSeverity.heavy
                              ? const Color(0xFFFF5252)
                              : (commute.lastStatus!.trafficSeverity == TrafficSeverity.moderate
                                  ? const Color(0xFFFFB300)
                                  : const Color(0xFF00E676)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          commute.lastStatus!.severityLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: commute.lastStatus!.trafficSeverity == TrafficSeverity.heavy
                                ? const Color(0xFFFF5252)
                                : (commute.lastStatus!.trafficSeverity == TrafficSeverity.moderate
                                    ? const Color(0xFFFFB300)
                                    : const Color(0xFF00E676)),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${commute.lastStatus!.distanceKm} km',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      commute.lastStatus!.spokenSummary,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3f. Proactive Autonomous Voice & Scheduled Nudges Card
  // ---------------------------------------------------------------------------
  Widget _proactiveVoiceCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Autonomní proaktivní hlasové výzvy',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Jarvis na vás nahlas promluví a připomene vám noční režim, studijní bloky, nadcházející schůzky a zbývající úkoly',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.jarvisAutoSpeakEnabled,
              onChanged: (val) async {
                await _settings.setJarvisAutoSpeakEnabled(val);
                setState(() {});
              },
            ),
            if (_settings.jarvisAutoSpeakEnabled) ...[
              const Divider(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Hands-free hlasové potvrzování',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Jarvis po položení otázky otevře okno aktivního poslechu, takže můžete odpovědět „Ano“ nebo „Ne“ bez dotyku zařízení',
                  style: TextStyle(fontSize: 12),
                ),
                value: _settings.proactiveVoiceConfirmationEnabled,
                onChanged: (val) async {
                  await _settings.setProactiveVoiceConfirmationEnabled(val);
                  setState(() {});
                },
              ),
              const Divider(height: 20),
              const Text(
                'AUTONOMNÍ ČASOVÉ A PLÁNOVANÉ SPOUŠTĚČE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '🌙 Automatická hlasová výzva nočního režimu',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  '„Je pokročilá noční hodina, pane. Mám zapnout noční režim?“ (21:00 – 23:30)',
                  style: TextStyle(fontSize: 12),
                ),
                value: _settings.proactiveNightModePrompt,
                onChanged: (val) async {
                  await _settings.setProactiveNightModePrompt(val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '📚 Výzva protokolu studia a soustředění',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Nabídne zapnutí Studijního protokolu a ztlumení rušivých vlivů během odpoledního soustředění (14:00 – 16:30)',
                  style: TextStyle(fontSize: 12),
                ),
                value: _settings.proactiveStudyPrompt,
                onChanged: (val) async {
                  await _settings.setProactiveStudyPrompt(val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '📅 Připomenutí nadcházejících schůzek a kalendáře',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Upozorní 15–30 min před plánovanými událostmi v kalendáři včetně přehledu a kontroly dopravy',
                  style: TextStyle(fontSize: 12),
                ),
                value: _settings.proactiveMeetingReminders,
                onChanged: (val) async {
                  await _settings.setProactiveMeetingReminders(val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '📋 Přehled zbývajících úkolů',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Večerní kontrola zbývajících prioritních položek agendy (17:00 – 19:30)',
                  style: TextStyle(fontSize: 12),
                ),
                value: _settings.proactiveTaskReminderPrompt,
                onChanged: (val) async {
                  await _settings.setProactiveTaskReminderPrompt(val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '☀️ Ranní informační přehled',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Po probuzení nabídne přednes počasí, kalendáře a hlavních zpráv (7:00 – 9:30)',
                  style: TextStyle(fontSize: 12),
                ),
                value: _settings.proactiveMorningBriefingPrompt,
                onChanged: (val) async {
                  await _settings.setProactiveMorningBriefingPrompt(val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '🔋 Telemetrické varování při slabé baterii',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Varuje při poklesu baterie pod 20 % a nabídne zapnutí protokolu Úspora baterie',
                  style: TextStyle(fontSize: 12),
                ),
                value: _settings.proactiveBatteryAlert,
                onChanged: (val) async {
                  await _settings.setProactiveBatteryAlert(val);
                  setState(() {});
                },
              ),
              const Divider(height: 24),
              const Text(
                'OTESTOVAT PROAKTIVNÍ AUTONOMNÍ VÝZVY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Klepnutím na libovolnou výzvu otestujete hlasový projev Jarvise a čekání na vaše hands-free hlasové potvrzení („Ano“ / „Ne“):',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.nightlight_round, size: 14),
                    label: const Text('Otestovat noční režim', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ProactiveAgentService.instance.testProactivePrompt('night');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testování hlasové výzvy nočního režimu... Řekněte Jarvisovi „Ano“ nebo „Ne“.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book, size: 14),
                    label: const Text('Otestovat studijní protokol', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ProactiveAgentService.instance.testProactivePrompt('study');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testování výzvy studijního protokolu... Řekněte Jarvisovi „Ano“ nebo „Ne“.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: const Text('Otestovat upozornění na schůzku', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ProactiveAgentService.instance.testProactivePrompt('meeting');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testování upozornění na schůzku... Řekněte Jarvisovi „Ano“ nebo „Ne“.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('Otestovat přehled úkolů', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ProactiveAgentService.instance.testProactivePrompt('todo');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testování přehledu úkolů... Řekněte Jarvisovi „Ano“ nebo „Ne“.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Memory & Privacy Governance Card
  // ---------------------------------------------------------------------------
  Widget _privacyCard(ThemeData theme) {
    final memory = ConversationalMemoryService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Režim soukromí (Local-First)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Vynutí 100% lokální AI v zařízení přes Ollama (127.0.0.1:11434) a offline TTS — žádná data neopustí vaše zařízení',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.localFirstPrivacyMode,
              onChanged: (val) async {
                await _settings.setLocalFirstPrivacyMode(val);
                setState(() {});
              },
            ),
            const Divider(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Potvrzování oprávnění pro citlivé akce',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Vyžaduje výslovné potvrzení před odesláním zpráv, uskutečněním hovorů nebo provedením zásadních akcí v zařízení',
                style: TextStyle(fontSize: 12),
              ),
              value: _settings.confirmRiskyActions,
              onChanged: (val) async {
                await _settings.setConfirmRiskyActions(val);
                setState(() {});
              },
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                'Centrum oprávnění aplikací a zpráv',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Zkontrolujte a udělte oprávnění pro doručené SMS, e-mailový kanál, mikrofon a automatizaci obrazovky',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                );
              },
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Konverzační paměť a fakta',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${memory.facts.length} zapamatovaných faktů uložených lokálně',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.manage_search_rounded, size: 18),
                  label: const Text('Spravovat', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showMemoryFactsSheet(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('Vymazat veškerou konverzační paměť'),
                onPressed: () => _confirmWipeMemory(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemoryFactsSheet() {
    final addController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final memory = ConversationalMemoryService.instance;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_outlined),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Zapamatovaná fakta a preference',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addController,
                            decoration: const InputDecoration(
                              hintText: 'Přidat nový fakt (např. „Oblíbený tým je Sparta“)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () async {
                            final text = addController.text.trim();
                            if (text.isNotEmpty) {
                              await memory.addFact(text);
                              addController.clear();
                              setModalState(() {});
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: memory.facts.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Zatím nejsou uložena žádná fakta.'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: memory.facts.length,
                              itemBuilder: (context, i) {
                                final f = memory.facts[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(f.fact, style: const TextStyle(fontSize: 13)),
                                  subtitle: Text(
                                    '${f.category} • ${f.createdAt.toString().split('.').first}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () async {
                                      await memory.deleteFact(f.id);
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmWipeMemory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vymazat veškerou paměť?'),
        content: const Text(
          'Tímto trvale vymažete veškerou historii dialogů napříč relacemi, naučené preference a uložená fakta. Tuto akci nelze vrátit zpět.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ConversationalMemoryService.instance.wipeAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veškerá paměť byla úspěšně vymazána.')),
                );
                setState(() {});
              }
            },
            child: const Text('Vymazat vše'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Hermes Self-Evolving tri-partite context (SOUL.md, USER.md, AGENT.md)
  // ---------------------------------------------------------------------------
  Widget _hermesEvolutionCard(ThemeData theme) {
    final soulLines = _hermes.soulMd.trim().split('\n').length;
    final userLines = _hermes.userMd.trim().split('\n').length;
    final agentLines = _hermes.agentMd.trim().split('\n').length;

    final lastEvolved = _hermes.lastEvolvedAt != null
        ? 'Naposledy vyvinuto: ${_hermes.lastEvolvedAt!.toLocal().toString().split('.').first}'
        : 'Jsou aktivní výchozí šablony Hermes';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00E5FF).withValues(alpha: 0.25),
                        const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: Color(0xFF00E5FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Samovyvíjející se jádro Hermes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                width: 0.7,
                              ),
                            ),
                            child: const Text(
                              'AKTIVNÍ',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00E5FF),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Třídílné kontextové soubory (SOUL, USER, AGENT) založené na architektuře Nous Research Hermes.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              lastEvolved,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 20),

            // SOUL.md Card
            _hermesFileTile(
              theme: theme,
              fileName: 'SOUL.md',
              slotBadge: 'SLOT 1',
              badgeColor: const Color(0xFF00E5FF),
              icon: Icons.shield_outlined,
              description:
                  'Definuje osobnost agenta, britskou noblesu, oslovování („pane“), behaviorální mantinely a etiku.',
              metrics: '$soulLines řádků • ${_hermes.soulMd.length} znaků',
              content: _hermes.soulMd,
              onTap: () => _openMarkdownEditor(
                fileName: 'SOUL.md',
                title: 'Základní identita a behaviorální ústava',
                slotBadge: 'SLOT 1',
                initialContent: _hermes.soulMd,
                onSave: (val) => _hermes.updateSoul(val),
                onReset: () => _hermes.resetSoul(),
              ),
            ),
            const SizedBox(height: 10),

            // USER.md Card
            _hermesFileTile(
              theme: theme,
              fileName: 'USER.md',
              slotBadge: 'SLOT 2',
              badgeColor: const Color(0xFFFFB300),
              icon: Icons.person_outline_rounded,
              description:
                  'Profil operátora, preference kadence, denní rutiny a dynamicky syntetizovaná fakta z paměti.',
              metrics: '$userLines řádků • ${_hermes.userMd.length} znaků',
              content: _hermes.userMd,
              onTap: () => _openMarkdownEditor(
                fileName: 'USER.md',
                title: 'Profil operátora a naučené preference',
                slotBadge: 'SLOT 2',
                initialContent: _hermes.userMd,
                onSave: (val) => _hermes.updateUser(val),
                onReset: () => _hermes.resetUser(),
              ),
            ),
            const SizedBox(height: 10),

            // AGENT.md Card
            _hermesFileTile(
              theme: theme,
              fileName: 'AGENT.md',
              slotBadge: 'SLOT 3',
              badgeColor: const Color(0xFF7C4DFF),
              icon: Icons.smart_toy_outlined,
              description:
                  'Provozní protokoly (Studium, Noc, Práce, Kino), hardwarové akční členy a samovyvinuté dovednosti.',
              metrics: '$agentLines řádků • ${_hermes.agentMd.length} znaků',
              content: _hermes.agentMd,
              onTap: () => _openMarkdownEditor(
                fileName: 'AGENT.md',
                title: 'Provozní protokoly a samovyvíjející se dovednosti',
                slotBadge: 'SLOT 3',
                initialContent: _hermes.agentMd,
                onSave: (val) => _hermes.updateAgent(val),
                onReset: () => _hermes.resetAgent(),
              ),
            ),
            const SizedBox(height: 16),

            // Evolutionary Action Buttons
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_mode_rounded, size: 18),
                label: const Text('Vyvinout nyní (syntetizovat paměť a dovednosti)'),
                onPressed: () async {
                  await _hermes.evolveContext();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jádro Hermes aktualizovalo soubory SOUL.md, USER.md a AGENT.md nejnovější telemetrií!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    setState(() {});
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restore_page_outlined, size: 18),
                label: const Text('Obnovit všechny kontextové soubory na výchozí'),
                onPressed: () => _confirmResetHermesAll(),
              ),
            ),

            if (_hermes.evolutionLog.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 16),
              Text(
                'NEDÁVNÉ ZÁZNAMY SAMOVÝVOJE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              for (final entry in _hermes.evolutionLog.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.commit, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hermesFileTile({
    required ThemeData theme,
    required String fileName,
    required String slotBadge,
    required Color badgeColor,
    required IconData icon,
    required String description,
    required String metrics,
    required String content,
    required VoidCallback onTap,
  }) {
    final snippet = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.startsWith('#'))
        .take(2)
        .join(' ')
        .trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: badgeColor),
                const SizedBox(width: 8),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.6),
                  ),
                  child: Text(
                    slotBadge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  metrics,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Zobrazit a upravit Markdown',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openMarkdownEditor({
    required String fileName,
    required String title,
    required String slotBadge,
    required String initialContent,
    required Future<void> Function(String) onSave,
    required Future<void> Function() onReset,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _HermesMarkdownEditorSheet(
        fileName: fileName,
        title: title,
        slotBadge: slotBadge,
        initialContent: initialContent,
        onSave: onSave,
        onReset: onReset,
      ),
    );
  }

  void _confirmResetHermesAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obnovit všechny soubory Hermes?'),
        content: const Text(
          'Tímto vrátíte soubory SOUL.md, USER.md a AGENT.md na jejich výchozí šablony Nous Research.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _hermes.resetAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Všechny kontextové soubory Hermes byly obnoveny na výchozí hodnoty.')),
                );
                setState(() {});
              }
            },
            child: const Text('Obnovit vše'),
          ),
        ],
      ),
    );
  }
}

class _HermesMarkdownEditorSheet extends StatefulWidget {
  final String fileName;
  final String title;
  final String slotBadge;
  final String initialContent;
  final Future<void> Function(String) onSave;
  final Future<void> Function() onReset;

  const _HermesMarkdownEditorSheet({
    required this.fileName,
    required this.title,
    required this.slotBadge,
    required this.initialContent,
    required this.onSave,
    required this.onReset,
  });

  @override
  State<_HermesMarkdownEditorSheet> createState() =>
      _HermesMarkdownEditorSheetState();
}

class _HermesMarkdownEditorSheetState
    extends State<_HermesMarkdownEditorSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _controller.text;
    final lines = text.split('\n').length;
    final chars = text.length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.fileName,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.slotBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                widget.title,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Upravit Markdown'),
              Tab(icon: Icon(Icons.preview_outlined, size: 18), text: 'Vykreslený náhled'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '$lines řádků • $chars znaků',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.restore, size: 14),
                    label: const Text('Obnovit soubor', style: TextStyle(fontSize: 11)),
                    onPressed: () async {
                      await widget.onReset();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Soubor ${widget.fileName} byl obnoven na výchozí šablonu')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Edit
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Zadejte obsah ve formátu Markdown...',
                      ),
                    ),
                  ),
                  // Tab 2: Rendered Preview
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        code: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Ukládání...' : 'Uložit změny do ${widget.fileName}'),
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            await widget.onSave(_controller.text);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Změny v souboru ${widget.fileName} byly uloženy'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

