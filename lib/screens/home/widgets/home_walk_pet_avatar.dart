import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeWalkPetAvatar extends StatelessWidget {
  final List<String> imageUrls;
  final String fallbackImageUrl;
  final int petCount;
  final double size;
  final bool dark;
  final Color accentColor;

  const HomeWalkPetAvatar({
    super.key,
    this.imageUrls = const [],
    this.fallbackImageUrl = '',
    this.petCount = 1,
    required this.size,
    this.dark = false,
    this.accentColor = DogGoTheme.teal,
  });

  List<String> get _validImages {
    final candidates = <String>[
      ...imageUrls,
      if (fallbackImageUrl.trim().isNotEmpty)
        fallbackImageUrl,
    ];

    return candidates
        .map((url) => url.trim())
        .where(
          (url) =>
              url.startsWith('http://') ||
              url.startsWith('https://'),
        )
        .toSet()
        .toList(growable: false);
  }

  int get _effectiveCount {
    if (petCount > 0) {
      return petCount;
    }

    return _validImages.isEmpty
        ? 1
        : _validImages.length;
  }

  @override
  Widget build(BuildContext context) {
    final images = _validImages;
    final count = _effectiveCount;
    final secondarySize = size * .48;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _PetTile(
              imageUrl:
                  images.isEmpty ? '' : images.first,
              dark: dark,
              accentColor: accentColor,
              borderRadius: size * .28,
            ),
          ),
          if (count > 1)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: secondarySize,
                height: secondarySize,
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(
                          alpha: .16,
                        )
                      : DogGoTheme.tealLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: .18,
                      ),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _PetTile(
                  imageUrl: images.length > 1
                      ? images[1]
                      : '',
                  dark: dark,
                  accentColor: accentColor,
                  circular: true,
                ),
              ),
            ),
          if (count > 2)
            Positioned(
              top: -5,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 25,
                  minHeight: 25,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: DogGoTheme.orange,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Text(
                  '+${count - 2}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PetTile extends StatelessWidget {
  final String imageUrl;
  final bool dark;
  final Color accentColor;
  final double borderRadius;
  final bool circular;

  const _PetTile({
    required this.imageUrl,
    required this.dark,
    required this.accentColor,
    this.borderRadius = 0,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: dark
          ? Colors.white.withValues(alpha: .14)
          : accentColor.withValues(alpha: .10),
      alignment: Alignment.center,
      child: Icon(
        Icons.pets_rounded,
        color: dark ? Colors.white : accentColor,
        size: circular ? 16 : 28,
      ),
    );

    final content = imageUrl.isEmpty
        ? placeholder
        : Image.network(
            imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) {
              return placeholder;
            },
          );

    if (circular) {
      return ClipOval(child: content);
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(borderRadius),
      child: content,
    );
  }
}