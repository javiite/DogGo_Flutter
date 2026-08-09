import 'package:flutter/material.dart';

import '../../theme/doggo_theme.dart';
import 'models/guide_article.dart';

class GuideDetailScreen extends StatelessWidget {
  final GuideArticle guide;

  const GuideDetailScreen({
    super.key,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        backgroundColor: DogGoTheme.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Guía DogGo',
          style: DogGoTheme.title(size: 19),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          _ArticleHeader(guide: guide),
          const SizedBox(height: 25),
          Text(
            guide.summary,
            style: DogGoTheme.body(
              size: 14,
              color: DogGoTheme.muted,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          for (var index = 0;
              index < guide.sections.length;
              index++) ...[
            _ArticleSection(
              number: index + 1,
              section: guide.sections[index],
              color: guide.color,
              background: guide.background,
            ),
            if (index < guide.sections.length - 1)
              const SizedBox(height: 16),
          ],
          const SizedBox(height: 25),
          _QuickTipsCard(guide: guide),
          const SizedBox(height: 24),
          const _ImportantNote(),
        ],
      ),
    );
  }
}

class _ArticleHeader extends StatelessWidget {
  final GuideArticle guide;

  const _ArticleHeader({
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 215),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            guide.color,
            Color.lerp(guide.color, Colors.black, .18)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            bottom: -35,
            child: Icon(
              guide.icon,
              size: 165,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 51,
                height: 51,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  guide.icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                guide.category.toUpperCase(),
                style: DogGoTheme.body(
                  size: 10,
                  color: DogGoTheme.orangeLight,
                  weight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                guide.title,
                style: DogGoTheme.title(
                  size: 25,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${guide.readMinutes} min de lectura',
                    style: DogGoTheme.body(
                      size: 11,
                      color: Colors.white.withValues(alpha: .82),
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArticleSection extends StatelessWidget {
  final int number;
  final GuideSection section;
  final Color color;
  final Color background;

  const _ArticleSection({
    required this.number,
    required this.section,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: DogGoTheme.body(
                    size: 12,
                    color: color,
                    weight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    section.title,
                    style: DogGoTheme.title(size: 17),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            section.content,
            style: DogGoTheme.body(
              size: 13,
              color: DogGoTheme.muted,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTipsCard extends StatelessWidget {
  final GuideArticle guide;

  const _QuickTipsCard({
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: guide.background,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: guide.color,
                size: 23,
              ),
              const SizedBox(width: 9),
              Text(
                'Consejos rápidos',
                style: DogGoTheme.title(size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var index = 0;
              index < guide.quickTips.length;
              index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: guide.color,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    guide.quickTips[index],
                    style: DogGoTheme.body(
                      size: 12.5,
                      color: DogGoTheme.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (index < guide.quickTips.length - 1)
              const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class _ImportantNote extends StatelessWidget {
  const _ImportantNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: DogGoTheme.orange,
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Estas recomendaciones son informativas. Ante cualquier problema de salud consulta a un veterinario.',
              style: DogGoTheme.body(
                size: 11.5,
                color: DogGoTheme.ink,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}