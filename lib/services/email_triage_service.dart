import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'ai_service.dart';

enum EmailPriority {
  urgent,
  important,
  actionRequired,
  newsletter,
  low,
}

class EmailTriageResult {
  final EmailPriority priority;
  final String summary;
  final List<String> actionItems;
  final List<String> suggestedReplies;

  const EmailTriageResult({
    required this.priority,
    required this.summary,
    required this.actionItems,
    required this.suggestedReplies,
  });
}

/// Email triage & drafting service:
/// - Summarizes emails into key highlights.
/// - Flags priorities (Urgent, Important, Action Required, Low).
/// - Suggests smart reply options.
/// - Launches native email clients with prefilled drafts.
class EmailTriageService {
  EmailTriageService._();
  static final EmailTriageService instance = EmailTriageService._();

  /// Analyzes and triages email text using LLM synthesis with fast local fallback.
  Future<EmailTriageResult> triageEmail(String emailContent) async {
    final clean = emailContent.trim();
    if (clean.isEmpty) {
      return const EmailTriageResult(
        priority: EmailPriority.low,
        summary: 'Nebyl zadán žádný text e-mailu k analýze, pane.',
        actionItems: [],
        suggestedReplies: [],
      );
    }

    const prompt = '''
Jsi expertní asistent pro třídění e-mailů.
Analyzuj následující text e-mailu a extrahuj strukturované metriky v češtině s plnou diakritikou:
1. "priority": Jedna z hodnot "urgent" | "important" | "action_required" | "newsletter" | "low"
2. "summary": Stručné shrnutí ve 2 větách v češtině.
3. "action_items": Pole konkrétních požadovaných kroků nebo úkolů v češtině.
4. "suggested_replies": Pole 3 různých profesionálních návrhů odpovědí v češtině (např. Potvrzení/Přijetí, Zdvořilé odmítnutí, Žádost o podrobnosti).

Vypiš POUZE JSON objekt:
{
  "priority": "urgent"|"important"|"action_required"|"newsletter"|"low",
  "summary": "...",
  "action_items": ["..."],
  "suggested_replies": ["..."]
}
''';

    try {
      final raw = await AiService.instance.chat(
        message: '$prompt\n\nEMAIL TEXT:\n$clean',
      );
      final jsonStart = raw.indexOf('{');
      final jsonEnd = raw.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final decoded = jsonDecode(raw.substring(jsonStart, jsonEnd + 1));
        if (decoded is Map) {
          final priorityStr =
              decoded['priority']?.toString().toLowerCase() ?? 'important';
          EmailPriority pri;
          switch (priorityStr) {
            case 'urgent':
              pri = EmailPriority.urgent;
              break;
            case 'important':
              pri = EmailPriority.important;
              break;
            case 'action_required':
              pri = EmailPriority.actionRequired;
              break;
            case 'newsletter':
              pri = EmailPriority.newsletter;
              break;
            default:
              pri = EmailPriority.low;
          }

          final summary = decoded['summary']?.toString() ?? 'E-mail byl analyzován.';
          final actions = (decoded['action_items'] as List?)
                  ?.map((a) => a.toString())
                  .toList() ??
              [];
          final replies = (decoded['suggested_replies'] as List?)
                  ?.map((r) => r.toString())
                  .toList() ??
              [];

          return EmailTriageResult(
            priority: pri,
            summary: summary,
            actionItems: actions,
            suggestedReplies: replies,
          );
        }
      }
    } catch (_) {}

    // Fallback heuristic triage
    final lower = clean.toLowerCase();
    final isUrgent = lower.contains('urgent') ||
        lower.contains('asap') ||
        lower.contains('deadline') ||
        lower.contains('immediately') ||
        lower.contains('naléhav') ||
        lower.contains('ihned') ||
        lower.contains('termín');

    return EmailTriageResult(
      priority: isUrgent ? EmailPriority.urgent : EmailPriority.important,
      summary: clean.length > 200 ? '${clean.substring(0, 200)}...' : clean,
      actionItems: ['Zkontrolovat zprávu a odpovědět na ni.'],
      suggestedReplies: [
        'Děkuji za zprávu. Váš e-mail jsem obdržel a brzy se vám ozvu.',
        'Děkuji za aktualizaci. Z mé strany je vše v pořádku.',
      ],
    );
  }

  /// Drafts an email reply and opens it directly in Gmail / default email client.
  Future<bool> openEmailDraft({
    String to = '',
    String subject = '',
    String body = '',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      },
    );

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

