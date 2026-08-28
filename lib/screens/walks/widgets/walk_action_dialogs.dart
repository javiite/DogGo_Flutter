import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

Future<bool?> showWalkActionConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  required IconData icon,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: destructive ? DogGoTheme.red : DogGoTheme.teal),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: destructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: DogGoTheme.red,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}

Future<String?> showWalkCancellationReason(BuildContext context) async {
  final controller = TextEditingController();
  String? errorText;

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cancel_outlined, color: DogGoTheme.red),
                SizedBox(width: 10),
                Expanded(child: Text('Cancelar paseo')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indica por qué necesitas cancelar el servicio.',
                  style: DogGoTheme.subtitle(size: 12.5),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 250,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Motivo de cancelación',
                    hintText: 'Ejemplo: cambio de horario, emergencia o clima.',
                    errorText: errorText,
                    alignLabelWithHint: true,
                  ),
                ),
                Text(
                  'Este motivo quedará visible en el detalle.',
                  style: DogGoTheme.caption(size: 10),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Volver'),
              ),
              ElevatedButton(
                onPressed: () {
                  final reason = controller.text.trim();

                  if (reason.length < 3) {
                    setDialogState(() {
                      errorText = 'Escribe un motivo más completo.';
                    });
                    return;
                  }

                  Navigator.pop(dialogContext, reason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DogGoTheme.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar cancelación'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return result;
}
