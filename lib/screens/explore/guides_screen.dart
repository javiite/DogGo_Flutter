import 'package:flutter/material.dart';

import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../shared/widgets/doggo_search_field.dart';
import '../../theme/doggo_theme.dart';
import 'guide_detail_screen.dart';
import 'models/guide_article.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Todas';
  String _search = '';

  static const List<String> _categories = [
    'Todas',
    'Paseos',
    'Salud',
    'Seguridad',
    'Equipo',
    'Comportamiento',
  ];

  List<GuideArticle> get _filteredGuides {
    final query = _search.trim().toLowerCase();

    return dogGoGuideArticles
        .where((guide) {
          final matchesCategory =
              _selectedCategory == 'Todas' ||
              guide.category == _selectedCategory;

          final matchesSearch =
              query.isEmpty ||
              guide.title.toLowerCase().contains(query) ||
              guide.summary.toLowerCase().contains(query) ||
              guide.category.toLowerCase().contains(query);

          return matchesCategory && matchesSearch;
        })
        .toList(growable: false);
  }

  GuideArticle get _featuredGuide {
    return dogGoGuideArticles.firstWhere(
      (guide) => guide.featured,
      orElse: () => dogGoGuideArticles.first,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openGuide(GuideArticle guide) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GuideDetailScreen(guide: guide)));
  }

  @override
  Widget build(BuildContext context) {
    final guides = _filteredGuides;

    return DogGoScreenScaffold(
      title: 'Guías DogGo',
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
          children: [
            _GuidesHero(
              guide: _featuredGuide,
              onTap: () {
                _openGuide(_featuredGuide);
              },
            ),
            const SizedBox(height: 24),
            DogGoSearchField(
              controller: _searchController,
              hintText: 'Buscar una guía',
              hasValue: _search.isNotEmpty,
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              onClear: () {
                _searchController.clear();

                setState(() {
                  _search = '';
                });
              },
            ),
            const SizedBox(height: 17),
            SizedBox(
              height: 39,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, _) {
                  return const SizedBox(width: 8);
                },
                itemBuilder: (context, index) {
                  final category = _categories[index];

                  return _CategoryChip(
                    label: category,
                    selected: category == _selectedCategory,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 27),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategory == 'Todas'
                        ? 'Aprende y disfruta'
                        : _selectedCategory,
                    style: DogGoTheme.title(size: 22),
                  ),
                ),
                Text(
                  '${guides.length} ${guides.length == 1 ? 'guía' : 'guías'}',
                  style: DogGoTheme.body(
                    size: 11,
                    color: DogGoTheme.teal,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Información útil para cada momento con tu mascota.',
              style: DogGoTheme.subtitle(size: 12),
            ),
            const SizedBox(height: 16),
            if (guides.isEmpty)
              const _EmptyGuides()
            else
              for (var index = 0; index < guides.length; index++) ...[
                _GuideCard(
                  guide: guides[index],
                  onTap: () {
                    _openGuide(guides[index]);
                  },
                ),
                if (index < guides.length - 1) const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _GuidesHero extends StatelessWidget {
  final GuideArticle guide;
  final VoidCallback onTap;

  const _GuidesHero({required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.purple,
      borderRadius: BorderRadius.circular(27),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF555D78), Color(0xFF747C99)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(27),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -22,
                bottom: -30,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 145,
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'DESTACADA',
                          style: DogGoTheme.body(
                            size: 9,
                            color: Colors.white,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    guide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.title(size: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guide.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.body(
                      size: 11.5,
                      color: Colors.white.withValues(alpha: .79),
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Leer guía',
                        style: DogGoTheme.body(
                          size: 12,
                          color: Colors.white,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DogGoTheme.teal : DogGoTheme.card,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? DogGoTheme.teal : DogGoTheme.border,
            ),
          ),
          child: Text(
            label,
            style: DogGoTheme.body(
              size: 11,
              color: selected ? Colors.white : DogGoTheme.muted,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final GuideArticle guide;
  final VoidCallback onTap;

  const _GuideCard({required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: guide.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(guide.icon, color: guide.color, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: guide.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            guide.category,
                            style: DogGoTheme.body(
                              size: 9,
                              color: guide.color,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${guide.readMinutes} min',
                          style: DogGoTheme.body(
                            size: 9.5,
                            color: DogGoTheme.muted,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      guide.title,
                      style: DogGoTheme.body(
                        size: 14,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      guide.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Padding(
                padding: EdgeInsets.only(top: 36),
                child: Icon(
                  Icons.chevron_right_rounded,
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

class _EmptyGuides extends StatelessWidget {
  const _EmptyGuides();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: DogGoTheme.muted,
          ),
          const SizedBox(height: 12),
          Text('No encontramos guías', style: DogGoTheme.title(size: 18)),
          const SizedBox(height: 6),
          Text(
            'Prueba con otra búsqueda o categoría.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 12),
          ),
        ],
      ),
    );
  }
}
