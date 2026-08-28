import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeWalkPetImages extends StatelessWidget {
  final List<String> imageUrls;
  final int petCount;

  const HomeWalkPetImages({
    super.key,
    required this.imageUrls,
    required this.petCount,
  });

  List<String> get _validUrls {
    return imageUrls
        .map((url) => url.trim())
        .where(
          (url) =>
              url.startsWith('http://') ||
              url.startsWith('https://'),
        )
        .toSet()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final urls = _validUrls;

    if (urls.isEmpty) {
      return const _Placeholder();
    }

    if (urls.length == 1) {
      return _NetworkPetImage(
        url: urls.first,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _NetworkPetImage(
          url: urls.first,
        ),
        Positioned(
          top: 18,
          right: 14,
          child: _SecondaryPhoto(
            url: urls[1],
            extraCount:
                petCount > 2 ? petCount - 2 : 0,
          ),
        ),
        Positioned(
          right: 18,
          bottom: 75,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: .48,
              ),
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: .30,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pets_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  '$petCount mascotas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryPhoto extends StatelessWidget {
  final String url;
  final int extraCount;

  const _SecondaryPhoto({
    required this.url,
    required this.extraCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 76,
          height: 76,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: DogGoTheme.tealLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: .20,
                ),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _NetworkPetImage(
            url: url,
          ),
        ),
        if (extraCount > 0)
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              width: 31,
              height: 31,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DogGoTheme.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Text(
                '+$extraCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NetworkPetImage extends StatelessWidget {
  final String url;

  const _NetworkPetImage({
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      frameBuilder: (
        context,
        child,
        frame,
        synchronouslyLoaded,
      ) {
        if (synchronouslyLoaded || frame != null) {
          return child;
        }

        return Container(
          color: DogGoTheme.teal,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 23,
            height: 23,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) {
        return const _Placeholder();
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DogGoTheme.teal,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(
        right: 18,
      ),
      child: Icon(
        Icons.pets_rounded,
        size: 140,
        color: Colors.white.withValues(
          alpha: .10,
        ),
      ),
    );
  }
}
