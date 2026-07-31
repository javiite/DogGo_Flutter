import 'package:flutter/material.dart';

import '../core/permissions/app_permission.dart';
import 'cambiar_password_screen.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_state.dart';

class ConfiguracionScreen
    extends StatefulWidget {
  const ConfiguracionScreen({
    super.key,
  });

  @override
  State<ConfiguracionScreen> createState() {
    return _ConfiguracionScreenState();
  }
}

class _ConfiguracionScreenState
    extends State<ConfiguracionScreen>
    with WidgetsBindingObserver {
  late final SettingsController
      _controller;
  late final TextEditingController
      _urlController;

  bool _urlInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    _urlController =
        TextEditingController();
    _controller = SettingsController();
    _controller.addListener(
      _handleControllerChange,
    );
    _controller.initialize();
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }

    final state = _controller.state;

    if (!_urlInitialized &&
        !state.loading) {
      _urlInitialized = true;
      _urlController.text =
          state.baseUrl;
    }

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      _controller.refreshPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    _controller.removeListener(
      _handleControllerChange,
    );
    _controller.dispose();
    _urlController.dispose();

    super.dispose();
  }

  Future<void> _saveServer() async {
    FocusScope.of(context).unfocus();

    final result =
        await _controller.saveServer(
      _urlController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      _urlController.text =
          _controller.state.baseUrl;
    }

    _showMessage(
      result.message,
      success: result.success,
    );
  }

  Future<void> _testServer() async {
    FocusScope.of(context).unfocus();

    final result =
        await _controller.testServer(
      _urlController.text,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      result.message,
      success: result.success,
    );
  }

  Future<void> _handlePermission(
    AppPermissionType type,
  ) async {
    final permission =
        _controller.state
            .permissionFor(type);

    if (permission.isGranted) {
      await _showPermissionEnabled(
        type,
      );
      return;
    }

    if (permission.mustOpenSettings) {
      await _showOpenSettingsDialog(
        type,
      );
      return;
    }

    final result =
        await _controller
            .requestPermission(type);

    if (!mounted) {
      return;
    }

    if (result.requiresAppSettings) {
      await _showOpenSettingsDialog(
        type,
      );
      return;
    }

    _showMessage(
      result.message,
      success: result.success,
    );
  }

  Future<void> _showPermissionEnabled(
    AppPermissionType type,
  ) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.verified_rounded,
            color: Color(0xFF087D68),
            size: 38,
          ),
          title: Text(
            '${type.title} activada',
          ),
          content: Text(
            'DogGo ya tiene acceso a ${type.title.toLowerCase()}. Puedes cambiarlo desde los ajustes del teléfono.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Abrir ajustes',
              ),
            ),
          ],
        );
      },
    );

    if (open == true) {
      await _openAppSettings();
    }
  }

  Future<void> _showOpenSettingsDialog(
    AppPermissionType type,
  ) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons
                .settings_suggest_rounded,
            color: Color(0xFFE08A1E),
            size: 38,
          ),
          title: Text(
            'Permiso de ${type.title.toLowerCase()}',
          ),
          content: Text(
            'Este permiso no puede solicitarse nuevamente desde DogGo. Actívalo manualmente en los ajustes del teléfono.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Abrir ajustes',
              ),
            ),
          ],
        );
      },
    );

    if (open == true) {
      await _openAppSettings();
    }
  }

  Future<void> _openAppSettings() async {
    final result =
        await _controller.openAppSettings();

    if (!mounted || result.success) {
      return;
    }

    _showMessage(
      result.message,
      success: false,
    );
  }

  Future<void>
      _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            const CambiarPasswordScreen(),
      ),
    );
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.pets_rounded,
            color: Color(0xFF087D68),
            size: 39,
          ),
          title: const Text('DogGo'),
          content: const Text(
            'DogGo conecta dueños de mascotas con paseadores y permite administrar solicitudes, recorridos, evidencias y mensajes desde una sola aplicación.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Entendido',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
    String message, {
    required bool success,
  }) {
    _controller.clearFeedback();

    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: success
              ? const Color(0xFF087D68)
              : const Color(0xFFB64238),
          content: Row(
            children: [
              Icon(
                success
                    ? Icons
                        .check_circle_rounded
                    : Icons
                        .error_rounded,
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

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F7),
      appBar: AppBar(
        title: const Text(
          'Configuración',
        ),
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF20212D),
        elevation: 0,
        surfaceTintColor:
            Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: state.loading
            ? const _SettingsLoading()
            : RefreshIndicator(
                color:
                    const Color(0xFF087D68),
                onRefresh: _controller
                    .refreshPermissions,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(
                    parent:
                        BouncingScrollPhysics(),
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    34,
                  ),
                  children: [
                    _buildHeader(state),
                    if (state.error !=
                        null) ...[
                      const SizedBox(
                        height: 14,
                      ),
                      _buildError(
                        state.error!,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildServerSection(
                      state,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionsSection(
                      state,
                    ),
                    const SizedBox(height: 16),
                    _buildAccountSection(),
                    const SizedBox(height: 16),
                    _buildInformationSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(
    SettingsState state,
  ) {
    final granted =
        state.grantedPermissionCount;
    final total =
        state.totalPermissionCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A806A),
            Color(0xFF075F54),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087D68)
                .withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.14),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu DogGo, listo para usar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  state.allPermissionsGranted
                      ? 'Los permisos principales están activos.'
                      : '$granted de $total permisos principales activos.',
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.86),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 11),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  child:
                      LinearProgressIndicator(
                    value: total == 0
                        ? 0
                        : granted / total,
                    minHeight: 6,
                    backgroundColor:
                        Colors.white
                            .withOpacity(0.16),
                    valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(
                      Color(0xFFFFC447),
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

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EF),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF2B6B1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB64238),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF87352F),
                fontSize: 12.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            visualDensity:
                VisualDensity.compact,
            onPressed:
                _controller.clearFeedback,
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSection(
    SettingsState state,
  ) {
    return _SettingsSection(
      title: 'Conexión con el servidor',
      subtitle:
          'Dirección usada por la aplicación para comunicarse con DogGo.',
      icon: Icons.dns_rounded,
      color: const Color(0xFF087D68),
      iconBackground:
          const Color(0xFFE7F4F1),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'URL base de la API',
            style: TextStyle(
              color: Color(0xFF5F6069),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            enabled: !state.savingServer &&
                !state.testingServer,
            keyboardType: TextInputType.url,
            textInputAction:
                TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) {
              _testServer();
            },
            decoration: InputDecoration(
              hintText:
                  'http://127.0.0.1:5230',
              prefixIcon: const Icon(
                Icons.link_rounded,
              ),
              suffixIcon: _urlController
                      .text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar',
                      onPressed: state.busy
                          ? null
                          : () {
                              setState(
                                _urlController
                                    .clear,
                              );
                            },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
              filled: true,
              fillColor:
                  const Color(0xFFF5F7F6),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide:
                    BorderSide.none,
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFE4E7E6),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFF087D68),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      state.testingServer ||
                              state.savingServer
                          ? null
                          : _testServer,
                  icon: state.testingServer
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons
                              .wifi_tethering_rounded,
                        ),
                  label: Text(
                    state.testingServer
                        ? 'Probando...'
                        : 'Probar',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    FilledButton.icon(
                  onPressed:
                      state.savingServer ||
                              state.testingServer
                          ? null
                          : _saveServer,
                  icon: state.savingServer
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_rounded,
                        ),
                  label: Text(
                    state.savingServer
                        ? 'Guardando...'
                        : 'Guardar',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const _InformationNote(
            icon: Icons.usb_rounded,
            color: Color(0xFFB77716),
            background:
                Color(0xFFFFF6E6),
            text:
                'Con el teléfono conectado y adb reverse usa http://127.0.0.1:5230. Sin USB utiliza la IP local de tu computadora.',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection(
    SettingsState state,
  ) {
    return _SettingsSection(
      title: 'Permisos del teléfono',
      subtitle:
          'Solo se solicitan cuando una función realmente los necesita.',
      icon: Icons.verified_user_rounded,
      color: const Color(0xFF3478D4),
      iconBackground:
          const Color(0xFFEAF2FD),
      child: Column(
        children: [
          for (var index = 0;
              index <
                  AppPermissionType
                      .values.length;
              index++) ...[
            _PermissionTile(
              type: AppPermissionType
                  .values[index],
              permission:
                  state.permissionFor(
                AppPermissionType
                    .values[index],
              ),
              loading:
                  state.isRequesting(
                AppPermissionType
                    .values[index],
              ),
              onTap: () {
                _handlePermission(
                  AppPermissionType
                      .values[index],
                );
              },
            ),
            if (index <
                AppPermissionType
                        .values.length -
                    1)
              const SizedBox(height: 10),
          ],
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.busy
                  ? null
                  : _openAppSettings,
              icon: const Icon(
                Icons.settings_rounded,
              ),
              label: const Text(
                'Abrir ajustes del teléfono',
              ),
            ),
          ),
          const SizedBox(height: 13),
          const _InformationNote(
            icon: Icons
                .info_outline_rounded,
            color: Color(0xFF3478D4),
            background:
                Color(0xFFEAF2FD),
            text:
                'Las notificaciones internas de DogGo ya funcionan. Los avisos push remotos se conectarán posteriormente con Firebase.',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _SettingsSection(
      title: 'Cuenta y seguridad',
      subtitle:
          'Opciones relacionadas con el acceso a tu cuenta.',
      icon: Icons.lock_rounded,
      color: const Color(0xFF7554B8),
      iconBackground:
          const Color(0xFFF1ECFA),
      child: _ActionTile(
        icon: Icons.lock_reset_rounded,
        title: 'Cambiar contraseña',
        subtitle:
            'Actualiza tu contraseña usando tu clave actual.',
        color: const Color(0xFF7554B8),
        background:
            const Color(0xFFF1ECFA),
        onTap: _openChangePassword,
      ),
    );
  }

  Widget _buildInformationSection() {
    return _SettingsSection(
      title: 'Información',
      subtitle:
          'Información general de la aplicación.',
      icon: Icons.info_outline_rounded,
      color: const Color(0xFF61656C),
      iconBackground:
          const Color(0xFFF0F2F1),
      child: _ActionTile(
        icon: Icons.pets_rounded,
        title: 'Acerca de DogGo',
        subtitle:
            'Conoce el objetivo de la aplicación.',
        color: const Color(0xFF087D68),
        background:
            const Color(0xFFE7F4F1),
        onTap: _showAbout,
      ),
    );
  }
}

class _SettingsSection
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconBackground;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconBackground,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE8EAE9),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF20212D),
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF777880),
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PermissionTile
    extends StatelessWidget {
  final AppPermissionType type;
  final AppPermissionInfo permission;
  final bool loading;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.type,
    required this.permission,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor(permission.status);
    final background =
        _statusBackground(
      permission.status,
    );

    return Material(
      color: const Color(0xFFF7F8F7),
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  const Color(0xFFE7E9E8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _permissionIcon(type),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      type.title,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF20212D),
                        fontSize: 13.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      type.description,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF73747D),
                        fontSize: 11,
                        height: 1.3,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                SizedBox(
                  width: 21,
                  height: 21,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: color,
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    permission
                        .status.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _permissionIcon(
    AppPermissionType type,
  ) {
    switch (type) {
      case AppPermissionType.camera:
        return Icons
            .photo_camera_rounded;
      case AppPermissionType.location:
        return Icons.my_location_rounded;
      case AppPermissionType.notifications:
        return Icons
            .notifications_active_rounded;
    }
  }

  static Color _statusColor(
    AppPermissionStatus status,
  ) {
    if (status.isGranted) {
      return const Color(0xFF087D68);
    }

    if (status.mustOpenSettings) {
      return const Color(0xFFB64238);
    }

    if (status ==
        AppPermissionStatus.unavailable) {
      return const Color(0xFF666A70);
    }

    return const Color(0xFFB77716);
  }

  static Color _statusBackground(
    AppPermissionStatus status,
  ) {
    if (status.isGranted) {
      return const Color(0xFFE7F4F1);
    }

    if (status.mustOpenSettings) {
      return const Color(0xFFFFF0EF);
    }

    if (status ==
        AppPermissionStatus.unavailable) {
      return const Color(0xFFF0F2F1);
    }

    return const Color(0xFFFFF6E6);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F8F7),
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  const Color(0xFFE7E9E8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF20212D),
                        fontSize: 13.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF73747D),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB5B7BA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationNote
    extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  const _InformationNote({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF64656D),
                fontSize: 11.5,
                height: 1.35,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLoading
    extends StatelessWidget {
  const _SettingsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics:
          const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 132,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E9E7),
            borderRadius:
                BorderRadius.circular(26),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (index) {
            return Container(
              height: index == 0
                  ? 250
                  : 190,
              margin: const EdgeInsets.only(
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFE5E9E7),
                borderRadius:
                    BorderRadius.circular(23),
              ),
            );
          },
        ),
      ],
    );
  }
}