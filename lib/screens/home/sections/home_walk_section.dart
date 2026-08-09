import 'package:flutter/material.dart';

import '../../../shared/widgets/doggo_error_view.dart';
import '../../../shared/widgets/doggo_skeleton_card.dart';
import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_theme.dart';
import '../widgets/home_walk_pet_images.dart';

class HomeWalkSection extends StatelessWidget {
  final bool loading;
  final String? errorMessage;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;

  // Se conserva para llamadas anteriores.
  final String imageUrl;

  // Nuevos datos para múltiples mascotas.
  final List<String> imageUrls;
  final int petCount;

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
    this.imageUrls = const [],
    this.petCount = 1,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.onRetry,
    this.errorMessage,
  });

  List<String> get _effectiveImages {
    if (imageUrls.isNotEmpty) {
      return imageUrls;
    }

    return imageUrl.trim().isEmpty
        ? const []
        : [imageUrl];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        18,
        24,
        0,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const DogGoSkeletonCard(
        height: 304,
        borderRadius:
            DogGoRadius.extraLarge,
      );
    }

    if (errorMessage != null) {
      return DogGoErrorView(
        title:
            'No pudimos cargar tus paseos',
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
      imageUrls: _effectiveImages,
      petCount: petCount,
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
  final List<String> imageUrls;
  final int petCount;
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
    required this.imageUrls,
    required this.petCount,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '$eyebrow. $title. $subtitle. $statusText',
      child: Container(
        height: 304,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DogGoTheme.teal,
          borderRadius: BorderRadius.circular(
            DogGoRadius.extraLarge,
          ),
          boxShadow:
              DogGoTheme.elevatedShadow(),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: .67,
                heightFactor: 1,
                alignment:
                    Alignment.centerRight,
                child: HomeWalkPetImages(
                  imageUrls: imageUrls,
                  petCount: petCount,
                ),
              ),
            ),
            const _WalkGradient(),
            Padding(
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
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
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
                      overflow:
                          TextOverflow.ellipsis,
                      style: DogGoTheme.title(
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: 225,
                    child: Text(
                      subtitle,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: DogGoTheme.body(
                        size: 12.7,
                        color: Colors.white
                            .withValues(
                          alpha: .86,
                        ),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(
                    text: statusText,
                    color: statusColor,
                  ),
                  const SizedBox(height: 13),
                  _Actions(
                    primaryLabel:
                        primaryLabel,
                    secondaryLabel:
                        secondaryLabel,
                    onPrimary: onPrimary,
                    onSecondary: onSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkGradient extends StatelessWidget {
  const _WalkGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            DogGoTheme.teal,
            DogGoTheme.teal,
            Color(0xEA087D68),
            Color(0x66087D68),
            Color(0x22087D68),
          ],
          stops: [
            0,
            .38,
            .56,
            .78,
            1,
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
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
        color: color.withValues(alpha: .23),
        borderRadius: BorderRadius.circular(
          DogGoRadius.pill,
        ),
        border: Border.all(
          color: color.withValues(alpha: .68),
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

class _Actions extends StatelessWidget {
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _Actions({
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
                side: BorderSide(
                  color: Colors.white.withValues(
                    alpha: .82,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    DogGoRadius.button,
                  ),
                ),
              ),
              child: Text(
                primaryLabel,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
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
                foregroundColor:
                    DogGoTheme.teal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    DogGoRadius.button,
                  ),
                ),
              ),
              child: Text(
                secondaryLabel,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}