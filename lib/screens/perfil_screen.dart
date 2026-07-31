import 'package:flutter/material.dart';

import '../core/navigation/app_routes.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_map_preview.dart';
import 'cambiar_password_screen.dart';
import 'editar_perfil_paseador_screen.dart';
import 'editar_perfil_screen.dart';
import 'profile/profile_controller.dart';
import 'profile/profile_state.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openScreen(Widget screen) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => screen,
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _controller.refresh();
    }
  }

  Future<void> _editProfile() {
    return _openScreen(
      EditarPerfilScreen(
        perfil: _controller.state.user,
      ),
    );
  }

  Future<void> _editWalkerProfile() {
    return _openScreen(
      const EditarPerfilPaseadorScreen(),
    );
  }

  Future<void> _changePassword() {
    return _openScreen(
      const CambiarPasswordScreen(),
    );
  }

  void _openNamed(String route) {
    Navigator.pushNamed(context, route);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Seguro que quieres cerrar tu sesión en DogGo?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: DogGoTheme.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final closed = await _controller.closeSession();

    if (!mounted) return;

    if (!closed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo cerrar la sesión. Inténtalo nuevamente.',
          ),
        ),
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi perfil'),
            actions: [
              IconButton(
                tooltip: 'Recargar perfil',
                onPressed:
                    state.loading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(ProfileState state) {
    if (state.loading && state.user.isEmpty) {
      return const DogGoLoadingView(
        message: 'Cargando tu perfil...',
      );
    }

    if (state.error != null && state.user.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            DogGoSpacing.screenHorizontal,
          ),
          child: DogGoErrorView(
            title: 'No pudimos cargar tu perfil',
            message: state.error!,
            onRetry: _controller.refresh,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          DogGoSpacing.md,
          DogGoSpacing.screenHorizontal,
          DogGoSpacing.xxl,
        ),
        children: [
          if (state.error != null) ...[
            DogGoErrorView(
              message: state.error!,
              onRetry: _controller.refresh,
              compact: true,
            ),
            const SizedBox(height: DogGoSpacing.md),
          ],
          _ProfileHeader(state: state),
          const SizedBox(height: DogGoSpacing.largeGap),
          if (state.isOwner)
            _buildOwnerSection(state)
          else if (state.isWalker)
            _buildWalkerSection(state)
          else
            _buildGenericSection(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildAccountSection(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildQuickActions(state),
          const SizedBox(height: DogGoSpacing.md),
          _buildSecuritySection(),
          const SizedBox(height: DogGoSpacing.xl),
          _buildLogoutButton(),
          const SizedBox(height: DogGoSpacing.lg),
          const _ProfileFooter(),
        ],
      ),
    );
  }

  Widget _buildOwnerSection(ProfileState state) {
    return _ProfileCard(
      title: 'Perfil de dueño',
      subtitle:
          'Información utilizada para coordinar los paseos y la recolección.',
      icon: Icons.pets_rounded,
      iconColor: DogGoTheme.teal,
      iconBackground: DogGoTheme.tealLight,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.home_outlined,
            title: 'Dirección',
            value: state.ownerAddress.isEmpty
                ? 'Sin dirección registrada'
                : state.ownerAddress,
          ),
          _InfoRow(
            icon: Icons.map_outlined,
            title: 'Zona',
            value: state.ownerZone.isEmpty
                ? 'Sin zona registrada'
                : state.ownerZone,
          ),
          _InfoRow(
            icon: Icons.signpost_outlined,
            title: 'Referencias',
            value: state.ownerReferences.isEmpty
                ? 'Sin referencias registradas'
                : state.ownerReferences,
          ),
          if (state.ownerDescription.isNotEmpty)
            _InfoRow(
              icon: Icons.notes_rounded,
              title: 'Descripción',
              value: state.ownerDescription,
            ),
          if (state.walkingPreferences.isNotEmpty)
            _InfoRow(
              icon: Icons.directions_walk_rounded,
              title: 'Preferencias de paseo',
              value: state.walkingPreferences,
            ),
          const SizedBox(height: DogGoSpacing.sm),
          DogGoMapPreview(
            latitud: state.ownerLatitude,
            longitud: state.ownerLongitude,
            height: 190,
            emptyText: 'Sin ubicación predeterminada',
            onTap: _editProfile,
          ),
          const SizedBox(height: DogGoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar perfil'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkerSection(ProfileState state) {
    final completion = state.walkerCompletionPercentage / 100;

    return _ProfileCard(
      title: 'Perfil profesional',
      subtitle: state.walkerProfileComplete
          ? 'Tu información principal está completa.'
          : 'Completa tu información para generar más confianza.',
      icon: Icons.directions_walk_rounded,
      iconColor: DogGoTheme.purple,
      iconBackground: DogGoTheme.purpleLight,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(DogGoSpacing.md),
            decoration: BoxDecoration(
              color: state.walkerProfileComplete
                  ? DogGoTheme.greenLight
                  : DogGoTheme.orangeLight,
              borderRadius: BorderRadius.circular(
                DogGoRadius.medium,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      state.walkerProfileComplete
                          ? Icons.verified_rounded
                          : Icons.pending_actions_rounded,
                      color: state.walkerProfileComplete
                          ? DogGoTheme.green
                          : DogGoTheme.orange,
                    ),
                    const SizedBox(width: DogGoSpacing.sm),
                    Expanded(
                      child: Text(
                        state.walkerProfileComplete
                            ? 'Perfil completo'
                            : 'Perfil al ${state.walkerCompletionPercentage}%',
                        style: DogGoTheme.body(
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusPill(
                      text: state.walkerAvailable
                          ? 'Disponible'
                          : 'No disponible',
                      active: state.walkerAvailable,
                    ),
                  ],
                ),
                const SizedBox(height: DogGoSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.pill,
                  ),
                  child: LinearProgressIndicator(
                    value: completion,
                    minHeight: 8,
                    color: state.walkerProfileComplete
                        ? DogGoTheme.green
                        : DogGoTheme.orange,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          _InfoRow(
            icon: Icons.description_outlined,
            title: 'Descripción',
            value: state.walkerDescription.isEmpty
                ? 'Sin descripción registrada'
                : state.walkerDescription,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            title: 'Zona de servicio',
            value: state.walkerZone.isEmpty
                ? 'Sin zona registrada'
                : state.walkerZone,
          ),
          _InfoRow(
            icon: Icons.payments_outlined,
            title: 'Tarifa',
            value: state.walkerRateLabel,
          ),
          _InfoRow(
            icon: Icons.workspace_premium_outlined,
            title: 'Experiencia',
            value: state.walkerExperienceLabel,
          ),
          const SizedBox(height: DogGoSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _editWalkerProfile,
              icon: const Icon(Icons.badge_outlined),
              label: Text(
                state.hasWalkerProfile
                    ? 'Editar perfil profesional'
                    : 'Completar perfil profesional',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericSection(ProfileState state) {
    return _ProfileCard(
      title: 'Cuenta DogGo',
      subtitle:
          'Esta cuenta no tiene un perfil especializado asociado.',
      icon: Icons.account_circle_outlined,
      iconColor: DogGoTheme.purple,
      iconBackground: DogGoTheme.purpleLight,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            title: 'Nombre',
            value: state.fullName,
          ),
          _InfoRow(
            icon: Icons.alternate_email_rounded,
            title: 'Rol',
            value: state.roleLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(ProfileState state) {
    return _ProfileCard(
      title: 'Datos de cuenta',
      subtitle: 'Información principal registrada en DogGo.',
      icon: Icons.person_outline_rounded,
      iconColor: DogGoTheme.teal,
      iconBackground: DogGoTheme.tealLight,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            title: 'Nombre completo',
            value: state.fullName,
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            title: 'Correo',
            value: state.email,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            title: 'Teléfono',
            value: state.phone,
          ),
          _InfoRow(
            icon: Icons.manage_accounts_outlined,
            title: 'Tipo de cuenta',
            value: state.roleLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ProfileState state) {
    return _ProfileCard(
      title: 'Accesos rápidos',
      subtitle: 'Administra la actividad de tu cuenta.',
      icon: Icons.dashboard_customize_outlined,
      iconColor: DogGoTheme.orange,
      iconBackground: DogGoTheme.orangeLight,
      child: Column(
        children: [
          if (state.isOwner)
            _ActionTile(
              icon: Icons.pets_outlined,
              title: 'Mis perros',
              subtitle: 'Consulta y administra tus mascotas.',
              onTap: () => _openNamed(AppRoutes.pets),
            ),
          _ActionTile(
            icon: Icons.calendar_month_outlined,
            title: 'Mis paseos',
            subtitle: 'Revisa tus paseos y su estado.',
            onTap: () => _openNamed(AppRoutes.walks),
          ),
          if (state.isOwner)
            _ActionTile(
              icon: Icons.search_rounded,
              title: 'Buscar paseadores',
              subtitle: 'Encuentra paseadores disponibles.',
              onTap: () => _openNamed(AppRoutes.walkers),
            ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _ProfileCard(
      title: 'Seguridad',
      subtitle: 'Mantén protegida tu cuenta.',
      icon: Icons.security_outlined,
      iconColor: DogGoTheme.green,
      iconBackground: DogGoTheme.greenLight,
      child: _ActionTile(
        icon: Icons.password_rounded,
        title: 'Cambiar contraseña',
        subtitle: 'Actualiza tu contraseña de acceso.',
        onTap: _changePassword,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: DogGoTheme.red,
          side: const BorderSide(
            color: DogGoTheme.red,
          ),
        ),
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Cerrar sesión'),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileState state;

  const _ProfileHeader({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final photo = state.profilePhotoUrl;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.extraLarge,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DogGoTheme.teal,
                  DogGoTheme.tealDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: photo == null
                          ? const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 58,
                            )
                          : Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 58,
                                );
                              },
                            ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: DogGoTheme.orange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        state.isWalker
                            ? Icons.directions_walk_rounded
                            : Icons.pets_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DogGoSpacing.md),
                Text(
                  state.fullName,
                  textAlign: TextAlign.center,
                  style: DogGoTheme.title(
                    size: 27,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: DogGoSpacing.xs),
                Text(
                  state.email,
                  textAlign: TextAlign.center,
                  style: DogGoTheme.subtitle(
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: DogGoSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(
                      DogGoRadius.pill,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    state.roleLabel,
                    style: DogGoTheme.body(
                      size: 12,
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget child;

  const _ProfileCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.title(
                        size: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: DogGoTheme.subtitle(
                        size: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DogGoTheme.divider,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: DogGoTheme.teal,
            size: 20,
          ),
          const SizedBox(width: DogGoSpacing.compactGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DogGoTheme.caption(
                    size: 11,
                    color: DogGoTheme.muted,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: DogGoTheme.body(
                    size: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          DogGoRadius.medium,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                ),
                child: Icon(
                  icon,
                  color: DogGoTheme.teal,
                  size: 21,
                ),
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.body(
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: DogGoTheme.subtitle(
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool active;

  const _StatusPill({
    required this.text,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? DogGoTheme.greenLight
            : DogGoTheme.redLight,
        borderRadius: BorderRadius.circular(
          DogGoRadius.pill,
        ),
      ),
      child: Text(
        text,
        style: DogGoTheme.caption(
          color: active
              ? DogGoTheme.green
              : DogGoTheme.red,
          weight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.pets_rounded,
          color: DogGoTheme.teal,
          size: 23,
        ),
        const SizedBox(height: DogGoSpacing.sm),
        Text(
          'DogGo',
          style: DogGoTheme.title(
            size: 16,
            color: DogGoTheme.teal,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Paseos felices, mascotas felices',
          style: DogGoTheme.caption(),
        ),
      ],
    );
  }
}