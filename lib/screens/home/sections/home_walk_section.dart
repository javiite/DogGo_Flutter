import 'package:flutter/material.dart';

import '../../../shared/widgets/doggo_error_view.dart';
import '../../../shared/widgets/doggo_skeleton_card.dart';
import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_theme.dart';

class HomeWalkSection extends StatelessWidget {
  final bool loading;
  final String? errorMessage;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final String imageUrl;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback onRetry;

  const HomeWalkSection({
    super.key,
    required this.loading,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.imageUrl,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const DogGoSkeletonCard(
        height: 292,
        borderRadius: DogGoRadius.extraLarge,
      );
    }

    if (errorMessage != null) {
      return DogGoErrorView(
        title: 'No pudimos cargar tus paseos',
        message: errorMessage!,
        icon: Icons.route_outlined,
        onRetry: onRetry,
      );
    }

    return _WalkCard(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      statusText: statusText,
      statusColor: statusColor,
      imageUrl: imageUrl,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
    );
  }
}

class _WalkCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final String imageUrl;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _WalkCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.imageUrl,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  bool get _hasImage {
    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$eyebrow. $title. $subtitle. $statusText',
      child: Container(
        height: 292,
        decoration: BoxDecoration(
          color: DogGoTheme.teal,
          borderRadius: BorderRadius.circular(
            DogGoRadius.extraLarge,
          ),
          boxShadow: DogGoTheme.elevatedShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: 16,
              bottom: 62,
              width: 178,
              child: _buildImage(),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  22,
                  20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 215,
                      child: Text(
                        eyebrow,
                        style: DogGoTheme.label(
                          size: 10.5,
                          color: DogGoTheme.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 220,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.title(
                          size: 25,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 220,
                      child: Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.body(
                          size: 12.7,
                          color: Colors.white.withValues(
                            alpha: .82,
                          ),
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _WalkStatus(
                      text: statusText,
                      color: statusColor,
                    ),
                    const SizedBox(height: 13),
                    _WalkActions(
                      primaryLabel: primaryLabel,
                      secondaryLabel: secondaryLabel,
                      onPrimary: onPrimary,
                      onSecondary: onSecondary,
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

  Widget _buildImage() {
    if (!_hasImage) {
      return const _WalkPlaceholder();
    }

    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
          ],
          stops: [0, .32, 1],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const _WalkPlaceholder();
        },
      ),
    );
  }
}

class _WalkStatus extends StatelessWidget {
  final String text;
  final Color color;

  const _WalkStatus({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .20),
        borderRadius: BorderRadius.circular(
          DogGoRadius.pill,
        ),
        border: Border.all(
          color: color.withValues(alpha: .62),
        ),
      ),
      child: Text(
        text,
        style: DogGoTheme.body(
          size: 10.5,
          color: Colors.white,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WalkActions extends StatelessWidget {
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _WalkActions({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 47,
            child: OutlinedButton(
              onPressed: onPrimary,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 47),
                side: BorderSide(
                  color: Colors.white.withValues(
                    alpha: .78,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.button,
                  ),
                ),
              ),
              child: Text(
                primaryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 47,
            child: ElevatedButton(
              onPressed: onSecondary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: DogGoTheme.teal,
                minimumSize: const Size(0, 47),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.button,
                  ),
                ),
              ),
              child: Text(
                secondaryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalkPlaceholder extends StatelessWidget {
  const _WalkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.pets_rounded,
        size: 150,
        color: Colors.white.withValues(alpha: .10),
      ),
    );
  }
}