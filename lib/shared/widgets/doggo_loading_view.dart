import 'package:flutter/material.dart';

import '../../theme/doggo_spacing.dart';
import '../../theme/doggo_theme.dart';

class DogGoLoadingView extends StatelessWidget {
  final String message;
  final bool compact;

  const DogGoLoadingView({
    super.key,
    this.message = 'Cargando información...',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(
            compact
                ? DogGoSpacing.md
                : DogGoSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: compact ? 28 : 38,
                height: compact ? 28 : 38,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: DogGoSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: DogGoTheme.body(
                  size: compact ? 12 : 13.5,
                  color: DogGoTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}