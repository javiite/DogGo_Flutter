import 'dart:io';

import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'evidence/evidence_controller.dart';
import 'evidence/evidence_state.dart';
import 'evidence/models/evidence_type.dart';

class EvidenciaPaseoScreen
    extends StatefulWidget {
  final int paseoId;
  final String tipo;
  final String nombrePerro;
  final String nombrePaseador;

  const EvidenciaPaseoScreen({
    super.key,
    required this.paseoId,
    required this.tipo,
    required this.nombrePerro,
    required this.nombrePaseador,
  });

  @override
  State<EvidenciaPaseoScreen> createState() =>
      _EvidenciaPaseoScreenState();
}

class _EvidenciaPaseoScreenState
    extends State<EvidenciaPaseoScreen> {
  late final EvidenceController _controller;

  @override
  void initState() {
    super.initState();

    _controller = EvidenceController(
      walkId: widget.paseoId,
      type: widget.tipo,
      petName: widget.nombrePerro,
      walkerName: widget.nombrePaseador,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final result =
        await _controller.takePhoto();

    if (!mounted) {
      return;
    }

    await _handleSelectionResult(result);
  }

  Future<void> _chooseFromGallery() async {
    final result =
        await _controller.chooseFromGallery();

    if (!mounted) {
      return;
    }

    await _handleSelectionResult(result);
  }

  Future<void> _handleSelectionResult(
    EvidenceResult result,
  ) async {
    if (result.code ==
        EvidenceResultCode.cancelled) {
      return;
    }

    if (result.code ==
        EvidenceResultCode.permissionDenied) {
      await _showPermissionDialog();
      return;
    }

    if (!result.success) {
      _showMessage(result.message);
    }
  }

  Future<void> _showPermissionDialog() async {
    final openSettings =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: DogGoTheme.teal,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permiso de cámara',
                ),
              ),
            ],
          ),
          content: const Text(
            'Para tomar la evidencia necesitas permitir el acceso a la cámara.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text(
                'Abrir configuración',
              ),
            ),
          ],
        );
      },
    );

    if (openSettings == true) {
      await _controller.openAppSettings();
    }
  }

  Future<void> _upload() async {
    final state = _controller.state;

    if (!state.hasFile) {
      _showMessage(
        'Selecciona o toma una fotografía primero.',
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                state.type ==
                        EvidenceType.start
                    ? Icons
                        .play_circle_outline_rounded
                    : Icons.flag_outlined,
                color: _typeColor(state.type),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirmar ${state.type.shortTitle.toLowerCase()}',
                ),
              ),
            ],
          ),
          content: Text(
            '${state.type.confirmationMessage}\n\n'
            'Después de enviarla quedará vinculada al paseo #${state.walkId}.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Revisar'),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              icon: const Icon(
                Icons.cloud_upload_outlined,
              ),
              label: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result =
        await _controller.upload();

    if (!mounted) {
      return;
    }

    _showMessage(
      result.message,
      success: result.success,
    );

    if (result.success &&
        result.code ==
            EvidenceResultCode.uploaded) {
      Navigator.pop(context, true);
    }
  }

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? DogGoTheme.teal
              : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          backgroundColor: DogGoTheme.cream,
          appBar: AppBar(
            title: Text(
              state.type.shortTitle,
            ),
          ),
          bottomNavigationBar:
              _UploadBottomBar(
            state: state,
            onUpload: _upload,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              DogGoSpacing.screenHorizontal,
              18,
              DogGoSpacing.screenHorizontal,
              125,
            ),
            children: [
              _EvidenceHero(
                state: state,
              ),
              if (state.error != null) ...[
                const SizedBox(height: 14),
                DogGoErrorView(
                  title:
                      'No pudimos procesar la evidencia',
                  message: state.error!,
                  icon:
                      Icons.photo_camera_back_outlined,
                  compact: true,
                ),
              ],
              const SizedBox(height: 18),
              _EvidencePreview(
                state: state,
                onRemove:
                    _controller.removeSelectedFile,
              ),
              const SizedBox(height: 13),
              _SourceButtons(
                state: state,
                onCamera: _takePhoto,
                onGallery:
                    _chooseFromGallery,
              ),
              const SizedBox(height: 22),
              _InstructionsCard(
                type: state.type,
              ),
              const SizedBox(height: 14),
              _EvidenceInformation(
                state: state,
              ),
              const SizedBox(height: 14),
              const _PrivacyCard(),
            ],
          ),
        );
      },
    );
  }
}

class _EvidenceHero extends StatelessWidget {
  final EvidenceState state;

  const _EvidenceHero({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(state.type);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          DogGoRadius.extraLarge,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .17),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -45,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: .08,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: .14,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    DogGoRadius.large,
                  ),
                ),
                child: Icon(
                  state.type ==
                          EvidenceType.start
                      ? Icons
                          .play_circle_outline_rounded
                      : Icons.flag_outlined,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.type.title,
                      style: DogGoTheme.title(
                        size: 21,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      state.type.description,
                      style: DogGoTheme.subtitle(
                        size: 11.5,
                        color: Colors.white
                            .withValues(alpha: .84),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _HeroChip(
                          icon:
                              Icons.pets_rounded,
                          text: state.petName,
                        ),
                        _HeroChip(
                          icon: Icons
                              .directions_walk_rounded,
                          text:
                              state.walkerName,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 210,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(
          DogGoRadius.pill,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.caption(
                size: 9,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidencePreview extends StatelessWidget {
  final EvidenceState state;
  final VoidCallback onRemove;

  const _EvidencePreview({
    required this.state,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final file = state.selectedFile;

    return Container(
      height: 330,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.extraLarge,
        ),
        border: Border.all(
          color: state.hasFile
              ? _typeColor(state.type)
                  .withValues(alpha: .25)
              : DogGoTheme.border,
        ),
        boxShadow: DogGoTheme.softShadow(
          opacity: .03,
          blur: 20,
          offset: const Offset(0, 8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: file == null
          ? _EmptyPreview(
              type: state.type,
            )
          : _SelectedPreview(
              file: file,
              state: state,
              onRemove: onRemove,
            ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  final EvidenceType type;

  const _EmptyPreview({
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: _typeSurface(type),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_a_photo_outlined,
            color: _typeColor(type),
            size: 36,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Selecciona una fotografía',
          textAlign: TextAlign.center,
          style: DogGoTheme.title(size: 18),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
          ),
          child: Text(
            'Puedes tomarla ahora o elegir una imagen reciente de tu galería.',
            textAlign: TextAlign.center,
            style:
                DogGoTheme.subtitle(size: 11.5),
          ),
        ),
      ],
    );
  }
}

class _SelectedPreview extends StatelessWidget {
  final File file;
  final EvidenceState state;
  final VoidCallback onRemove;

  const _SelectedPreview({
    required this.file,
    required this.state,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: DogGoTheme.red,
                size: 48,
              ),
            );
          },
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: .58,
              ),
              borderRadius: BorderRadius.circular(
                DogGoRadius.medium,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fotografía lista',
                        style: DogGoTheme.body(
                          size: 10.5,
                          color: Colors.white,
                          weight:
                              FontWeight.w800,
                        ),
                      ),
                      Text(
                        state.fileSizeLabel,
                        style: DogGoTheme.caption(
                          size: 8.5,
                          color: Colors.white
                              .withValues(
                                  alpha: .72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: IconButton(
            onPressed:
                state.busy ? null : onRemove,
            tooltip: 'Eliminar fotografía',
            icon: const Icon(
              Icons.close_rounded,
            ),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.black.withValues(
                alpha: .55,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceButtons extends StatelessWidget {
  final EvidenceState state;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _SourceButtons({
    required this.state,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                state.busy ? null : onCamera,
            icon: state.selecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_outlined,
                  ),
            label: Text(
              state.hasFile
                  ? 'Tomar otra'
                  : 'Cámara',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                state.busy ? null : onGallery,
            icon: const Icon(
              Icons.photo_library_outlined,
            ),
            label: Text(
              state.hasFile
                  ? 'Cambiar'
                  : 'Galería',
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final EvidenceType type;

  const _InstructionsCard({
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final instructions = type.instructions;

    return _InformationCard(
      icon: Icons.fact_check_outlined,
      iconColor: _typeColor(type),
      iconBackground: _typeSurface(type),
      title: 'Antes de tomarla',
      subtitle:
          'Revisa estas recomendaciones',
      child: Column(
        children: List.generate(
          instructions.length,
          (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index ==
                        instructions.length - 1
                    ? 0
                    : 12,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _typeSurface(type),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: DogGoTheme.caption(
                        size: 9,
                        color: _typeColor(type),
                        weight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      instructions[index],
                      style: DogGoTheme.body(
                        size: 11,
                        weight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EvidenceInformation
    extends StatelessWidget {
  final EvidenceState state;

  const _EvidenceInformation({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.info_outline_rounded,
      iconColor: DogGoTheme.orange,
      iconBackground:
          DogGoTheme.orangeLight,
      title: 'Datos del archivo',
      subtitle:
          'La imagen se optimiza antes de seleccionarse',
      child: Column(
        children: [
          _InformationRow(
            label: 'Paseo',
            value: '#${state.walkId}',
          ),
          const Divider(height: 22),
          _InformationRow(
            label: 'Tipo',
            value: state.type.title,
          ),
          const Divider(height: 22),
          _InformationRow(
            label: 'Archivo',
            value: state.fileName,
          ),
          const Divider(height: 22),
          _InformationRow(
            label: 'Tamaño',
            value: state.fileSizeLabel,
          ),
          const Divider(height: 22),
          const _InformationRow(
            label: 'Límite',
            value: '12 MB',
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.purpleLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            color: DogGoTheme.purple,
            size: 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'La evidencia se utilizará para comprobar el servicio. Evita fotografiar documentos, domicilios completos o personas que no autorizaron aparecer.',
              style: DogGoTheme.body(
                size: 10.5,
                color: DogGoTheme.purple,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadBottomBar extends StatelessWidget {
  final EvidenceState state;
  final VoidCallback onUpload;

  const _UploadBottomBar({
    required this.state,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          10,
          DogGoSpacing.screenHorizontal,
          12,
        ),
        decoration: BoxDecoration(
          color: DogGoTheme.card.withValues(
            alpha: .98,
          ),
          border: const Border(
            top: BorderSide(
              color: DogGoTheme.border,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: .04,
              ),
              blurRadius: 17,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed:
                state.canUpload ? onUpload : null,
            icon: state.uploading
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.cloud_upload_outlined,
                  ),
            label: Text(
              state.uploading
                  ? 'Subiendo evidencia...'
                  : state.hasFile
                      ? 'Confirmar y enviar'
                      : 'Selecciona una fotografía',
            ),
          ),
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget child;

  const _InformationCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                      BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.title(
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: DogGoTheme.caption(
                        size: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final String label;
  final String value;

  const _InformationRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(
              size: 10.5,
              color: DogGoTheme.muted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 10.5,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

Color _typeColor(EvidenceType type) {
  switch (type) {
    case EvidenceType.start:
      return DogGoTheme.green;
    case EvidenceType.end:
      return DogGoTheme.purple;
  }
}

Color _typeSurface(EvidenceType type) {
  switch (type) {
    case EvidenceType.start:
      return DogGoTheme.greenLight;
    case EvidenceType.end:
      return DogGoTheme.purpleLight;
  }
}