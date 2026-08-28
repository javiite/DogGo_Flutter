import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_screen_scaffold.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'ratings/models/rating_option.dart';
import 'ratings/rating_controller.dart';
import 'ratings/rating_state.dart';

class CalificarPaseoScreen extends StatefulWidget {
  final int paseoId;
  final String nombrePerro;
  final String nombrePaseador;

  const CalificarPaseoScreen({
    super.key,
    required this.paseoId,
    required this.nombrePerro,
    required this.nombrePaseador,
  });

  @override
  State<CalificarPaseoScreen> createState() => _CalificarPaseoScreenState();
}

class _CalificarPaseoScreenState extends State<CalificarPaseoScreen> {
  late final RatingController _controller;

  final TextEditingController _commentController = TextEditingController();

  final FocusNode _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _controller = RatingController(
      walkId: widget.paseoId,
      petName: widget.nombrePerro,
      walkerName: widget.nombrePaseador,
    );

    _controller.initialize();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final state = _controller.state;
    final comment = _commentController.text.trim();

    if (comment.length < RatingController.minimumCommentLength) {
      _showMessage('Escribe un comentario más completo.');
      _commentFocus.requestFocus();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: DogGoTheme.orange),
              SizedBox(width: 10),
              Expanded(child: Text('Enviar calificación')),
            ],
          ),
          content: Text(
            'Calificarás el paseo con ${state.score} de 5 estrellas.\n\n'
            'Tu comentario será visible como parte de la reputación del paseador.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Revisar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await _controller.submit(comment);

    if (!mounted) {
      return;
    }

    if (!result.success) {
      _showMessage(result.message);
      return;
    }

    await _showSuccessDialog();

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: DogGoTheme.greenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: DogGoTheme.green,
                  size: 38,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                '¡Gracias por tu opinión!',
                textAlign: TextAlign.center,
                style: DogGoTheme.title(size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                'La calificación fue guardada correctamente.',
                textAlign: TextAlign.center,
                style: DogGoTheme.subtitle(size: 12.5),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return DogGoScreenScaffold(
          title: 'Calificar paseo',
          bottomNavigationBar: state.checking || state.alreadyRated
              ? null
              : _RatingBottomBar(
                  state: state,
                  commentController: _commentController,
                  onSubmit: _submit,
                ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(RatingState state) {
    if (state.checking) {
      return const DogGoLoadingView(message: 'Comprobando la calificación...');
    }

    if (state.alreadyRated) {
      return _AlreadyRatedView(
        petName: state.petName,
        onClose: () => Navigator.pop(context),
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        DogGoSpacing.screenHorizontal,
        18,
        DogGoSpacing.screenHorizontal,
        125,
      ),
      children: [
        _RatingHero(state: state),
        if (state.error != null) ...[
          const SizedBox(height: 14),
          DogGoErrorView(
            title: 'No pudimos enviar la calificación',
            message: state.error!,
            icon: Icons.star_outline_rounded,
            compact: true,
          ),
        ],
        const SizedBox(height: 18),
        _StarSelector(state: state, onSelected: _controller.selectScore),
        const SizedBox(height: 14),
        _RatingSummary(state: state),
        const SizedBox(height: 22),
        _CommentSection(
          state: state,
          controller: _commentController,
          focusNode: _commentFocus,
        ),
        const SizedBox(height: 14),
        const _ReviewGuidelines(),
        const SizedBox(height: 14),
        const _ReviewImpactCard(),
      ],
    );
  }
}

class _RatingHero extends StatelessWidget {
  final RatingState state;

  const _RatingHero({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(DogGoRadius.large),
                ),
                child: const Icon(
                  Icons.reviews_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Cómo estuvo el paseo?',
                      style: DogGoTheme.title(size: 21, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.body(
                        size: 12,
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Con ${state.walkerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.caption(
                        size: 10,
                        color: Colors.white.withValues(alpha: .75),
                      ),
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

class _StarSelector extends StatelessWidget {
  final RatingState state;
  final ValueChanged<int> onSelected;

  const _StarSelector({required this.state, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(state.score);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              state.selectedRating.label,
              key: ValueKey(state.score),
              style: DogGoTheme.title(size: 20, color: color),
            ),
          ),
          const SizedBox(height: 7),
          Text(state.scoreLabel, style: DogGoTheme.subtitle(size: 11.5)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= state.score;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: value == state.score,
                  label: '$value de 5 estrellas',
                  child: IconButton(
                    onPressed: state.submitting
                        ? null
                        : () => onSelected(value),
                    icon: Icon(
                      selected ? Icons.star_rounded : Icons.star_border_rounded,
                    ),
                    color: selected ? color : DogGoTheme.border,
                    iconSize: 42,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final RatingState state;

  const _RatingSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(state.score);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: color.withValues(alpha: .17)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .2)),
            ),
            child: Icon(_ratingIcon(state.score), color: color, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              state.selectedRating.summary,
              style: DogGoTheme.body(
                size: 11.5,
                color: color,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentSection extends StatelessWidget {
  final RatingState state;
  final TextEditingController controller;
  final FocusNode focusNode;

  const _CommentSection({
    required this.state,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cuéntanos tu experiencia', style: DogGoTheme.title(size: 17)),
          const SizedBox(height: 4),
          Text(
            state.selectedRating.question,
            style: DogGoTheme.subtitle(size: 11.5),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !state.submitting,
            minLines: 4,
            maxLines: 7,
            maxLength: RatingController.maximumCommentLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Comentario',
              hintText:
                  'Describe la puntualidad, comunicación y cuidado de tu mascota.',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 82),
                child: Icon(Icons.edit_note_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewGuidelines extends StatelessWidget {
  const _ReviewGuidelines();

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      icon: Icons.fact_check_outlined,
      title: 'Una reseña útil',
      child: const Column(
        children: [
          _Guideline(text: 'Describe aspectos reales del servicio.'),
          SizedBox(height: 11),
          _Guideline(text: 'Evita compartir teléfonos o domicilios.'),
          SizedBox(height: 11),
          _Guideline(text: 'Mantén un lenguaje respetuoso.'),
        ],
      ),
    );
  }
}

class _Guideline extends StatelessWidget {
  final String text;

  const _Guideline({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            color: DogGoTheme.greenLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: DogGoTheme.green,
            size: 15,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: DogGoTheme.body(size: 10.5, weight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ReviewImpactCard extends StatelessWidget {
  const _ReviewImpactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.purpleLight,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.groups_outlined, color: DogGoTheme.purple, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu opinión ayuda a otros dueños a elegir paseadores confiables y permite mejorar la comunidad DogGo.',
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

class _AlreadyRatedView extends StatelessWidget {
  final String petName;
  final VoidCallback onClose;

  const _AlreadyRatedView({required this.petName, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: DogGoTheme.greenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: DogGoTheme.green,
                  size: 39,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Paseo ya calificado',
                textAlign: TextAlign.center,
                style: DogGoTheme.title(size: 21),
              ),
              const SizedBox(height: 7),
              Text(
                'Ya compartiste tu opinión sobre el paseo de $petName.',
                textAlign: TextAlign.center,
                style: DogGoTheme.subtitle(size: 12.5),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onClose,
                child: const Text('Volver al paseo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBottomBar extends StatelessWidget {
  final RatingState state;
  final TextEditingController commentController;
  final VoidCallback onSubmit;

  const _RatingBottomBar({
    required this.state,
    required this.commentController,
    required this.onSubmit,
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
          color: DogGoTheme.card.withValues(alpha: .98),
          border: const Border(top: BorderSide(color: DogGoTheme.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 17,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: commentController,
          builder: (context, value, _) {
            final validComment =
                value.text.trim().length >=
                RatingController.minimumCommentLength;

            return SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: state.submitting || !validComment ? null : onSubmit,
                icon: state.submitting
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  state.submitting
                      ? 'Enviando calificación...'
                      : 'Enviar ${state.score} estrellas',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InformationCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(icon, color: DogGoTheme.teal, size: 21),
              ),
              const SizedBox(width: 11),
              Text(title, style: DogGoTheme.title(size: 16)),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

Color _ratingColor(int score) {
  if (score <= 2) {
    return DogGoTheme.red;
  }

  if (score == 3) {
    return DogGoTheme.orange;
  }

  if (score == 4) {
    return DogGoTheme.teal;
  }

  return DogGoTheme.green;
}

IconData _ratingIcon(int score) {
  if (score <= 2) {
    return Icons.sentiment_dissatisfied_rounded;
  }

  if (score == 3) {
    return Icons.sentiment_neutral_rounded;
  }

  if (score == 4) {
    return Icons.sentiment_satisfied_rounded;
  }

  return Icons.sentiment_very_satisfied_rounded;
}
