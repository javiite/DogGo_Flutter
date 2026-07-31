import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';

class ServerSetupScreen extends StatefulWidget {
  final VoidCallback onConfigured;

  const ServerSetupScreen({
    super.key,
    required this.onConfigured,
  });

  @override
  State<ServerSetupScreen> createState() {
    return _ServerSetupScreenState();
  }
}

class _ServerSetupScreenState
    extends State<ServerSetupScreen> {
  final TextEditingController _urlController =
      TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedUrl() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) {
      return;
    }

    if (url != null && url.trim().isNotEmpty) {
      _urlController.text = url.trim();
    }
  }

  String _cleanUrl(String value) {
    var cleanValue = value.trim();

    while (cleanValue.endsWith('/')) {
      cleanValue = cleanValue.substring(
        0,
        cleanValue.length - 1,
      );
    }

    return cleanValue;
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        uri.hasScheme &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveServer() async {
    final url = _cleanUrl(_urlController.text);

    if (url.isEmpty) {
      _showMessage('Escribe la URL del servidor.');
      return;
    }

    if (!_isValidUrl(url)) {
      _showMessage(
        'Escribe una dirección válida que empiece con http:// o https://',
      );
      return;
    }

    if (url.toLowerCase().endsWith('/api')) {
      _showMessage(
        'No agregues /api al final. Escribe únicamente la URL base.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await StorageService.guardarBaseUrl(url);

      if (!mounted) {
        return;
      }

      _showMessage('Servidor guardado correctamente.');

      await Future<void>.delayed(
        const Duration(milliseconds: 350),
      );

      if (!mounted) {
        return;
      }

      widget.onConfigured();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No se pudo guardar el servidor: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        title: const DogGoLogo(size: 52),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            DogGoSpacing.screenHorizontal,
            DogGoSpacing.md,
            DogGoSpacing.screenHorizontal,
            DogGoSpacing.xl,
          ),
          children: [
            const _IntroductionCard(),
            const SizedBox(height: DogGoSpacing.md),
            _ServerFormCard(
              controller: _urlController,
              saving: _saving,
              onSave: _saveServer,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroductionCard extends StatelessWidget {
  const _IntroductionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DogGoSpacing.lg),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(
          DogGoRadius.extraLarge,
        ),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -22,
            child: Icon(
              Icons.cloud_outlined,
              size: 128,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONFIGURACIÓN INICIAL',
                style: DogGoTheme.label(
                  size: 10.5,
                  color: DogGoTheme.orange,
                ),
              ),
              const SizedBox(height: DogGoSpacing.md),
              Text(
                'Conecta DogGo\ncon tu servidor',
                style: DogGoTheme.display(
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: DogGoSpacing.md),
              SizedBox(
                width: 280,
                child: Text(
                  'Ingresa la dirección base del servidor para iniciar sesión y cargar tus datos.',
                  style: DogGoTheme.body(
                    size: 13,
                    color:
                        Colors.white.withValues(alpha: .80),
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServerFormCard extends StatelessWidget {
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  const _ServerFormCard({
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        DogGoSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dirección del servidor',
            style: DogGoTheme.title(size: 19),
          ),
          const SizedBox(height: DogGoSpacing.xs),
          Text(
            'Puedes usar un servidor local o una dirección HTTPS.',
            style: DogGoTheme.subtitle(size: 12.5),
          ),
          const SizedBox(height: DogGoSpacing.lg),
          TextField(
            controller: controller,
            enabled: !saving,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) {
              if (!saving) {
                onSave();
              }
            },
            decoration: const InputDecoration(
              labelText: 'URL base',
              hintText: 'http://127.0.0.1:5230',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          const _ServerHelpBox(),
          const SizedBox(height: DogGoSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                saving
                    ? 'Guardando...'
                    : 'Guardar y continuar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerHelpBox extends StatelessWidget {
  const _ServerHelpBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.md),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.medium,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: DogGoTheme.teal,
            size: 21,
          ),
          const SizedBox(width: DogGoSpacing.sm),
          Expanded(
            child: Text(
              'Para un teléfono conectado mediante ADB reverse usa:\n'
              'http://127.0.0.1:5230\n\n'
              'No agregues /api al final.',
              style: DogGoTheme.body(
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}