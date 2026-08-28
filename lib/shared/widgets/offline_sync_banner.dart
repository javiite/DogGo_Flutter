import 'package:flutter/material.dart';

import '../../core/offline/offline_connectivity_sync_service.dart';
import '../../theme/doggo_theme.dart';

class OfflineSyncBanner extends StatelessWidget {
  OfflineSyncBanner({super.key, OfflineConnectivitySyncService? service})
    : _service = service ?? OfflineConnectivitySyncService.instance;

  final OfflineConnectivitySyncService _service;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final presentation = _presentation();
        if (presentation == null) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: presentation.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: presentation.border),
          ),
          child: Row(
            children: [
              if (_service.syncing)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: presentation.foreground,
                  ),
                )
              else
                Icon(
                  presentation.icon,
                  color: presentation.foreground,
                  size: 23,
                ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.title,
                      style: TextStyle(
                        color: presentation.foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (presentation.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        presentation.subtitle,
                        style: TextStyle(
                          color: presentation.foreground.withValues(
                            alpha: 0.78,
                          ),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (presentation.canRetry) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _service.syncing ? null : _service.syncNow,
                  style: TextButton.styleFrom(
                    foregroundColor: presentation.foreground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Sincronizar'),
                ),
              ],
              if (_service.hasIrrecoverable) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Descartar datos inválidos',
                  onPressed: () => _confirmDiscard(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: presentation.foreground,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar datos inválidos'),
        content: const Text(
          'Solo se eliminarán puntos GPS que el servidor rechazó de forma definitiva. '
          'Los datos que todavía pueden sincronizarse permanecerán guardados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.discardIrrecoverable();
    }
  }

  _BannerPresentation? _presentation() {
    final summary = _service.summary;

    switch (_service.status) {
      case OfflineRecoveryStatus.synchronized:
        return null;
      case OfflineRecoveryStatus.syncing:
        return null;
      case OfflineRecoveryStatus.offline:
        if (!summary.hasPending) return null;
        return _BannerPresentation(
          title: 'Sin conexión · ${summary.total} pendientes',
          subtitle: 'Tus datos están protegidos en este dispositivo.',
          icon: Icons.cloud_off_rounded,
          foreground: const Color(0xFF9A6500),
          background: const Color(0xFFFFF5DA),
          border: const Color(0xFFF0D48B),
          canRetry: true,
        );
      case OfflineRecoveryStatus.failed:
        if (!summary.hasPending) return null;
        return _BannerPresentation(
          title: 'No se pudo sincronizar',
          subtitle:
              _service.lastError?.toString() ??
              '${summary.total} elementos siguen guardados de forma segura.',
          icon: Icons.sync_problem_rounded,
          foreground: DogGoTheme.red,
          background: const Color(0xFFFFECEC),
          border: const Color(0xFFF2BDBD),
          canRetry: true,
        );
      case OfflineRecoveryStatus.idle:
        return null;
    }
  }
}

class _BannerPresentation {
  const _BannerPresentation({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
    this.canRetry = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
  final bool canRetry;
}
