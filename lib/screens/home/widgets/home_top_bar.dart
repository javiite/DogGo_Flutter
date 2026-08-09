import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../services/role_switch_service.dart';
import '../../../theme/doggo_theme.dart';
import '../../../widgets/doggo_logo.dart';
import '../../profile_completion_screen.dart';

class HomeTopBar extends StatefulWidget {
  final String role;
  final bool isWalker;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;
  final VoidCallback onMenuTap;

  const HomeTopBar({
    super.key,
    required this.role,
    required this.isWalker,
    required this.unreadNotifications,
    required this.onNotificationsTap,
    required this.onMenuTap,
  });

  @override
  State<HomeTopBar> createState() {
    return _HomeTopBarState();
  }
}

class _HomeTopBarState
    extends State<HomeTopBar> {
  bool _switchingRole = false;

  DogGoRoleMode get _currentMode {
    return widget.isWalker
        ? DogGoRoleMode.walker
        : DogGoRoleMode.owner;
  }

  Future<void> _openRoleSelector() async {
    if (_switchingRole) {
      return;
    }

    final selected =
        await showModalBottomSheet<
            DogGoRoleMode>(
      context: context,
      showDragHandle: true,
      backgroundColor: DogGoTheme.card,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Cambiar modo',
                  style: DogGoTheme.title(
                    size: 23,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Usa la misma cuenta como dueño o paseador. Tus perfiles y datos se conservarán.',
                  style: DogGoTheme.subtitle(
                    size: 13,
                  ),
                ),
                const SizedBox(height: 20),
                _RoleModeOption(
                  selected: _currentMode ==
                      DogGoRoleMode.owner,
                  icon: Icons.pets_rounded,
                  title: 'Dueño',
                  subtitle:
                      'Administra tus mascotas y solicita paseos.',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      DogGoRoleMode.owner,
                    );
                  },
                ),
                const SizedBox(height: 11),
                _RoleModeOption(
                  selected: _currentMode ==
                      DogGoRoleMode.walker,
                  icon: Icons
                      .directions_walk_rounded,
                  title: 'Paseador',
                  subtitle:
                      'Recibe solicitudes y administra servicios.',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      DogGoRoleMode.walker,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        selected == null ||
        selected == _currentMode) {
      return;
    }

    setState(() {
      _switchingRole = true;
    });

    try {
      final result =
          await RoleSwitchService.changeMode(
        selected,
      );

      if (!mounted) {
        return;
      }

      if (!result.success) {
        setState(() {
          _switchingRole = false;
        });

        _showMessage(
          result.message,
          error: true,
        );

        return;
      }

      setState(() {
        _switchingRole = false;
      });

      _showMessage(result.message);

      if (result.requiresProfileCompletion) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                ProfileCompletionScreen(
              mode: selected,
            ),
          ),
          (_) => false,
        );

        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _switchingRole = false;
      });

      _showMessage(
        _cleanError(error),
        error: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: error
              ? DogGoTheme.red
              : DogGoTheme.teal,
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons
                        .check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .replaceFirst(
          'ApiException: ',
          '',
        )
        .trim();

    return message.isEmpty
        ? 'No se pudo cambiar el modo.'
        : message;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(
        14,
        8,
        14,
        8,
      ),
      color: DogGoTheme.card,
      child: Row(
        children: [
          const DogGoLogo(size: 44),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: DogGoTheme.card,
              borderRadius:
                  BorderRadius.circular(22),
              child: InkWell(
                onTap: _switchingRole
                    ? null
                    : _openRoleSelector,
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
                child: Container(
                  height: 44,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                    border: Border.all(
                      color:
                          DogGoTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_switchingRole)
                        const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Icon(
                          widget.isWalker
                              ? Icons
                                  .directions_walk_rounded
                              : Icons
                                  .pets_rounded,
                          size: 17,
                          color:
                              DogGoTheme.teal,
                        ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          widget.role,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              DogGoTheme.body(
                            size: 12.5,
                            color:
                                DogGoTheme.ink,
                            weight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        _switchingRole
                            ? Icons
                                .hourglass_top_rounded
                            : Icons
                                .keyboard_arrow_down_rounded,
                        size: 17,
                        color:
                            DogGoTheme.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _TopBarButton(
            icon: Icons
                .notifications_none_rounded,
            badgeCount:
                widget.unreadNotifications,
            onTap:
                widget.onNotificationsTap,
          ),
          const SizedBox(width: 6),
          _TopBarButton(
            icon: Icons.menu_rounded,
            onTap: widget.onMenuTap,
          ),
        ],
      ),
    );
  }
}

class _RoleModeOption
    extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleModeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DogGoTheme.tealLight
          : DogGoTheme.card,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? DogGoTheme.teal
                  : DogGoTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? DogGoTheme.card
                      : DogGoTheme.tealLight,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  icon,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style:
                                DogGoTheme.title(
                              size: 16,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  DogGoTheme.teal,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                999,
                              ),
                            ),
                            child: const Text(
                              'Actual',
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                          DogGoTheme.subtitle(
                        size: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons
                        .check_circle_rounded
                    : Icons
                        .chevron_right_rounded,
                color: selected
                    ? DogGoTheme.teal
                    : DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeCount > 0;

    return Material(
      color: DogGoTheme.card,
      borderRadius:
          BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: DogGoTheme.border,
                ),
              ),
              child: Icon(
                icon,
                color: DogGoTheme.ink,
                size: 22,
              ),
            ),
            if (showBadge)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  constraints:
                      const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        DogGoTheme.orange,
                    borderRadius:
                        BorderRadius
                            .circular(
                      999,
                    ),
                    border: Border.all(
                      color:
                          DogGoTheme.card,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99
                          ? '99+'
                          : '$badgeCount',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}