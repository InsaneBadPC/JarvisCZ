import 'package:flutter/material.dart';

import '../../services/permission_manager_service.dart';

/// Centralized permissions management screen for user ease:
/// Audits and requests all required permissions for Voice, SMS, Email, and Device Automation.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  final _service = PermissionManagerService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _service.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oprávnění aplikace'),
        actions: [
          IconButton(
            tooltip: 'Obnovit',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _service.refresh(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          if (_service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final granted = _service.grantedCount;
          final total = _service.totalCount;
          final ratio = total == 0 ? 0.0 : granted / total;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              // Summary Hub Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.security_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aktivních oprávnění: $granted z $total',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  granted == total
                                      ? 'Všechny systémy jsou plně autorizovány pro autonomní provoz.'
                                      : 'Některé funkce vyžadují ke svému fungování oprávnění uživatele.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ratio == 1.0 ? Colors.green : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.done_all_rounded, size: 18),
                              label: const Text('Udělit základní oprávnění'),
                              onPressed: () async {
                                await _service.requestAllCorePermissions();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Žádost o oprávnění byla odeslána'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Permissions List
              _sectionTitle('Komunikace a schránky zpráv'),
              for (final p in _service.permissions.where(
                (p) =>
                    p.type == AppPermissionType.sms ||
                    p.type == AppPermissionType.notificationListener ||
                    p.type == AppPermissionType.contacts ||
                    p.type == AppPermissionType.notifications,
              )) ...[
                _permissionCard(theme, p),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 14),
              _sectionTitle('Hlasové jádro a automatizace'),
              for (final p in _service.permissions.where(
                (p) =>
                    p.type == AppPermissionType.microphone ||
                    p.type == AppPermissionType.accessibility ||
                    p.type == AppPermissionType.overlay ||
                    p.type == AppPermissionType.batteryOptimization,
              )) ...[
                _permissionCard(theme, p),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Otevřít systémové nastavení aplikace'),
                onPressed: () => _service.openAppInfo(),
              ),
            ],
          );
        },
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
            letterSpacing: 1.1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  Widget _permissionCard(ThemeData theme, AppPermissionInfo p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: p.isGranted
                    ? Colors.green.withValues(alpha: 0.12)
                    : theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                p.icon,
                size: 20,
                color: p.isGranted ? Colors.green : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.isGranted
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: p.isGranted
                                ? Colors.green.withValues(alpha: 0.4)
                                : Colors.amber.withValues(alpha: 0.5),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          p.isGranted ? 'UDĚLENO' : (p.isSystemSettingsOnly ? 'NASTAVIT' : 'VYŽADOVÁNO'),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: p.isGranted ? Colors.green : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                  if (!p.isGranted) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          p.isSystemSettingsOnly
                              ? Icons.open_in_new_rounded
                              : Icons.check_circle_outline,
                          size: 14,
                        ),
                        label: Text(
                          p.isSystemSettingsOnly ? 'Otevřít nastavení' : 'Udělit oprávnění',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          await _service.requestPermission(p.type);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

