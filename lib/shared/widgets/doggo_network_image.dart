import 'package:flutter/material.dart';

import '../../theme/doggo_theme.dart';

class DogGoNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Widget fallback;
  final String semanticLabel;

  const DogGoNetworkImage({
    super.key,
    required this.url,
    required this.fallback,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();

    if (value == null || value.isEmpty) {
      return Semantics(image: true, label: semanticLabel, child: fallback);
    }

    return Semantics(
      image: true,
      label: semanticLabel,
      child: Image.network(
        value,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: DogGoTheme.teal,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
