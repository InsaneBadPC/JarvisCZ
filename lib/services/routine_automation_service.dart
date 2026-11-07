import 'calendar_reminder_service.dart';
import 'jarvis_tools_service.dart';
import 'system_control_service.dart';
import 'todo_service.dart';

enum RoutineType { morning, evening }

/// Morning and evening autonomous routine engine.
class RoutineAutomationService {
  RoutineAutomationService._();
  static final RoutineAutomationService instance =
      RoutineAutomationService._();

  /// Runs the comprehensive Morning Briefing Routine.
  Future<String> executeMorningRoutine({String? userCity}) async {
    // 1. Hardware: Unmute, set balanced daytime volume (60%) and brightness (75%)
    try {
      await SystemControlService.instance.setMuted(false);
      await SystemControlService.instance.setVolume(0.60);
      await SystemControlService.instance.setBrightness(0.75);
    } catch (_) {}

    // 2. Telemetry: Date, Battery, Weather
    final dt = JarvisToolsService.instance.getCurrentDateTime();
    final battery = await JarvisToolsService.instance.getBatteryStatus();
    final battLevel = battery['level'] as int;

    String weatherText = '';
    try {
      weatherText = await JarvisToolsService.instance
          .getWeather(userCity?.isNotEmpty == true ? userCity! : '');
    } catch (_) {}

    // 3. Today's Calendar & Tasks
    final calBriefing =
        CalendarReminderService.instance.getTodayBriefingSpoken();
    final todoBriefing = TodoService.instance.getPendingTasksSpoken();

    // 4. Compile articulate morning briefing
    final buffer = StringBuffer('Dobré ráno, pane. Vítejte do nového dne. ');
    buffer.write('Aktuálně je $dt. ');
    if (battLevel >= 0) {
      buffer.write('Baterie vašeho zařízení je na $battLevel %. ');
    }
    if (weatherText.isNotEmpty && !weatherText.contains('Unable to retrieve') && !weatherText.contains('Nepodařilo se')) {
      buffer.write('Venkovní podmínky: $weatherText. ');
    }
    buffer.write('$calBriefing ');
    buffer.write('$todoBriefing ');
    buffer.write('Všechny systémy jsou připraveny a plně k vaší dispozici. Čím dnes začneme, pane?');

    return buffer.toString();
  }

  /// Runs the soothing Evening / Night Routine.
  Future<String> executeEveningRoutine() async {
    // 1. Hardware: Dim display to 15%, lower audio to 20%, silence notifications
    try {
      await SystemControlService.instance.setBrightness(0.15);
      await SystemControlService.instance.setVolume(0.20);
      await JarvisToolsService.instance.setTorch(false);
    } catch (_) {}

    // 2. Review today's accomplishments
    final completedTodos = TodoService.instance.completedItems.length;

    final buffer = StringBuffer('Dobrý večer, pane. Zahajuji noční protokol. ');
    buffer.write('Ztlumil jsem displej, ztišil hlasitá oznámení a připravil vaše zařízení ke spánku. ');
    if (completedTodos > 0) {
      final taskWord = completedTodos == 1 ? 'úkol' : (completedTodos >= 2 && completedTodos <= 4 ? 'úkoly' : 'úkolů');
      buffer.write('Dnes jste dokončil $completedTodos $taskWord — vynikající práce. ');
    }
    buffer.write('Dobře si odpočiňte, pane. Zůstanu v tiché pohotovosti a budu dohlížet na vaše systémy až do úsvitu.');

    return buffer.toString();
  }
}

