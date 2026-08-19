import 'package:flutter/material.dart';
import '../../../theme/doggo_theme.dart';

class AvailabilityWarningCard extends StatelessWidget {
  final bool loading;
  final bool unavailable;
  final String? error;
  final VoidCallback onRetry;
  const AvailabilityWarningCard({
    super.key,
    required this.loading,
    required this.unavailable,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!loading && !unavailable && error == null) {
      return const SizedBox.shrink();
    }
    final failed = error != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: failed || unavailable
            ? DogGoTheme.orangeLight
            : DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              failed ? Icons.wifi_off_rounded : Icons.event_busy_rounded,
              color: DogGoTheme.orange,
            ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              loading
                  ? 'Consultando la agenda del paseador...'
                  : failed
                  ? error!
                  : 'Este paseador no está recibiendo solicitudes por ahora.',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (failed)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
