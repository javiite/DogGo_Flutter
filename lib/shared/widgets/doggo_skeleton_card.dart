import 'package:flutter/material.dart';

import '../../theme/doggo_radius.dart';
import '../../theme/doggo_theme.dart';

class DogGoSkeletonCard extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const DogGoSkeletonCard({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = DogGoRadius.large,
  });

  @override
  State<DogGoSkeletonCard> createState() {
    return _DogGoSkeletonCardState();
  }
}

class _DogGoSkeletonCardState
    extends State<DogGoSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.disableAnimationsOf(context);

    if (disableAnimations) {
      return _buildStaticSkeleton();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              widget.borderRadius,
            ),
            gradient: LinearGradient(
              begin: Alignment(
                -1.5 + (_controller.value * 3),
                0,
              ),
              end: Alignment(
                -.5 + (_controller.value * 3),
                0,
              ),
              colors: const [
                DogGoTheme.purpleLight,
                DogGoTheme.card,
                DogGoTheme.purpleLight,
              ],
              stops: const [0, .5, 1],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticSkeleton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: DogGoTheme.purpleLight,
        borderRadius: BorderRadius.circular(
          widget.borderRadius,
        ),
      ),
    );
  }
}