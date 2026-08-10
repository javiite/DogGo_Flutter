import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeShortcutsSection extends StatelessWidget {
  final bool isWalker;
  final VoidCallback onPetsOrProfile;
  final VoidCallback onAgenda;
  final VoidCallback onWalks;
  final VoidCallback onExplore;

  const HomeShortcutsSection({
    super.key,
    required this.isWalker,
    required this.onPetsOrProfile,
    required this.onAgenda,
    required this.onWalks,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _ShortcutData(
        icon: isWalker ? Icons.badge_outlined : Icons.pets_rounded,
        label: isWalker ? 'Mi perfil' : 'Mis mascotas',
        subtitle: isWalker
            ? 'Información profesional'
            : 'Perfiles y fotografías',
        color: DogGoTheme.teal,
        background: DogGoTheme.tealLight,
        onTap: onPetsOrProfile,
      ),
      _ShortcutData(
        icon: Icons.calendar_month_rounded,
        label: 'Agenda',
        subtitle: 'Fechas y próximos paseos',
        color: DogGoTheme.purple,
        background: DogGoTheme.purpleLight,
        onTap: onAgenda,
      ),
      _ShortcutData(
        icon: Icons.route_rounded,
        label: 'Mis paseos',
        subtitle: 'Solicitudes e historial',
        color: DogGoTheme.orange,
        background: DogGoTheme.orangeLight,
        onTap: onWalks,
      ),
      _ShortcutData(
        icon: Icons.explore_rounded,
        label: 'Explorar',
        subtitle: 'Lugares, guías y servicios',
        color: DogGoTheme.green,
        background: DogGoTheme.greenLight,
        onTap: onExplore,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Accesos rápidos',
                  style: DogGoTheme.title(size: 20),
                ),
              ),
              Text('Todo a la mano', style: DogGoTheme.subtitle(size: 10.5)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: shortcuts.length,
            padding: EdgeInsets.zero,
            primary: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.92,
            ),
            itemBuilder: (context, index) {
              return _ShortcutCard(data: shortcuts[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final _ShortcutData data;

  const _ShortcutCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: data.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.body(
                        size: 11.5,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(size: 8.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutData {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ShortcutData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });
}
