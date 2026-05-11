import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/perros_service.dart';
import '../services/storage_service.dart';
import '../theme/doggo_theme.dart';
import 'seleccionar_ubicacion_screen.dart';

class CrearPaseoScreen extends StatefulWidget {
  final Map<String, dynamic> paseador;

  const CrearPaseoScreen({
    super.key,
    required this.paseador,
  });

  @override
  State<CrearPaseoScreen> createState() => _CrearPaseoScreenState();
}

class _CrearPaseoScreenState extends State<CrearPaseoScreen> {
  bool _cargando = true;
  bool _guardando = false;
  bool _cargandoUbicacionPredeterminada = false;

  String? _baseUrl;
  String? _error;

  List<Map<String, dynamic>> _perros = [];
  Map<String, dynamic>? _perroSeleccionado;

  int _duracionMinutos = 30;
  DateTime? _fechaProgramada;

  double? _latitudRecogida;
  double? _longitudRecogida;
  String? _direccionRecogida;
  String? _referenciasRecogida;

  Map<String, dynamic>? _ubicacionPredeterminada;

  final TextEditingController _notasController = TextEditingController();

  final List<int> _duraciones = const [30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final baseUrl = await StorageService.obtenerBaseUrl();
      final perrosResult = await PerrosService.obtenerMisPerros();

      final perros =
          _normalizarLista(perrosResult).where((item) => item.isNotEmpty).toList();

      Map<String, dynamic>? predeterminada;

      try {
        predeterminada = await _obtenerUbicacionPredeterminada();
      } catch (_) {
        predeterminada = null;
      }

      if (!mounted) return;

      setState(() {
        _baseUrl = baseUrl;
        _perros = perros;
        _perroSeleccionado = perros.isNotEmpty ? perros.first : null;
        _ubicacionPredeterminada = predeterminada;

        if (predeterminada != null) {
          final lat = _toDouble(_valorMapa(predeterminada, [
            'latitudRecogida',
            'LatitudRecogida',
            'latitud',
            'Latitud',
            'lat',
            'Lat',
          ]));

          final lng = _toDouble(_valorMapa(predeterminada, [
            'longitudRecogida',
            'LongitudRecogida',
            'longitud',
            'Longitud',
            'lng',
            'Lng',
            'lon',
            'Lon',
          ]));

          final direccion = _textoSeguro(
            _valorMapa(predeterminada, [
              'direccionRecogida',
              'DireccionRecogida',
              'direccion',
              'Direccion',
              'ubicacionTexto',
              'UbicacionTexto',
            ]),
            '',
          );

          if (lat != null && lng != null) {
            _latitudRecogida = lat;
            _longitudRecogida = lng;
            _direccionRecogida =
                direccion.isNotEmpty ? direccion : 'Ubicación predeterminada';
            _referenciasRecogida = _direccionRecogida;
          }
        }

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _obtenerUbicacionPredeterminada() async {
    final endpoints = [
      '/api/perfil',
      '/api/Perfil',
      '/api/usuarios/perfil',
      '/api/Usuarios/perfil',
      '/api/auth/me',
      '/api/Auth/me',
      '/api/usuarios/me',
      '/api/Usuarios/me',
    ];

    for (final endpoint in endpoints) {
      try {
        final respuesta = await ApiService.getAuth(endpoint);
        final statusCode = respuesta['statusCode'];

        if (statusCode is int && statusCode >= 200 && statusCode < 300) {
          dynamic body = respuesta['body'];

          if (body is Map) {
            body = body['data'] ??
                body['perfil'] ??
                body['usuario'] ??
                body['duenioPerfil'] ??
                body['dueñoPerfil'] ??
                body;

            if (body is Map) {
              final mapa = Map<String, dynamic>.from(body);

              final posiblePerfil = _valorMapa(mapa, [
                'duenioPerfil',
                'DuenioPerfil',
                'dueñoPerfil',
                'DueñoPerfil',
                'perfilDuenio',
                'PerfilDuenio',
                'perfilDueño',
                'PerfilDueño',
              ]);

              if (posiblePerfil is Map) {
                return Map<String, dynamic>.from(posiblePerfil);
              }

              final lat = _toDouble(_valorMapa(mapa, [
                'latitudRecogida',
                'LatitudRecogida',
                'latitud',
                'Latitud',
                'lat',
                'Lat',
              ]));

              final lng = _toDouble(_valorMapa(mapa, [
                'longitudRecogida',
                'LongitudRecogida',
                'longitud',
                'Longitud',
                'lng',
                'Lng',
                'lon',
                'Lon',
              ]));

              final direccion = _textoSeguro(
                _valorMapa(mapa, [
                  'direccionRecogida',
                  'DireccionRecogida',
                  'direccion',
                  'Direccion',
                  'ubicacionTexto',
                  'UbicacionTexto',
                ]),
                '',
              );

              if (lat != null || lng != null || direccion.isNotEmpty) {
                return mapa;
              }
            }
          }
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _normalizarLista(dynamic respuesta) {
    dynamic datos = respuesta;

    if (respuesta is Map) {
      final body = respuesta['body'];
      datos = body ?? respuesta;

      if (datos is Map) {
        datos = datos['data'] ??
            datos['perros'] ??
            datos['items'] ??
            datos['resultado'] ??
            datos['result'] ??
            datos['value'];
      }
    }

    if (datos is! List) return [];

    return datos
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  dynamic _valorMapa(Map<String, dynamic> mapa, List<String> keys) {
    for (final key in keys) {
      if (mapa.containsKey(key) && mapa[key] != null) {
        return mapa[key];
      }
    }

    return null;
  }

  String _textoSeguro(dynamic valor, [String fallback = '']) {
    if (valor == null) return fallback;

    if (valor is Map) {
      final nombre = valor['nombre'] ??
          valor['Nombre'] ??
          valor['nombreCompleto'] ??
          valor['NombreCompleto'] ??
          valor['titulo'] ??
          valor['Titulo'];

      if (nombre != null) return _textoSeguro(nombre, fallback);
    }

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;

    return texto;
  }

  int? _toInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is double) return valor.toInt();
    if (valor is num) return valor.toInt();

    return int.tryParse(valor.toString());
  }

  double? _toDouble(dynamic valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is num) return valor.toDouble();

    return double.tryParse(valor.toString());
  }

  int get _paseadorId {
    return _toInt(_valorMapa(widget.paseador, [
          'id',
          'Id',
          'paseadorId',
          'PaseadorId',
        ])) ??
        0;
  }

  String get _nombrePaseador {
    final usuario = _valorMapa(widget.paseador, ['usuario', 'Usuario']);

    if (usuario is Map) {
      final nombre = _textoSeguro(usuario['nombre'] ?? usuario['Nombre'], '');
      final apellido =
          _textoSeguro(usuario['apellido'] ?? usuario['Apellido'], '');

      final completo = '$nombre $apellido'.trim();
      if (completo.isNotEmpty) return completo;
    }

    final nombreDirecto = _textoSeguro(
      _valorMapa(widget.paseador, [
        'nombre',
        'Nombre',
        'nombreCompleto',
        'NombreCompleto',
        'paseadorNombre',
        'PaseadorNombre',
      ]),
      '',
    );

    return nombreDirecto.isNotEmpty ? nombreDirecto : 'Paseador DogGo';
  }

  String get _fotoPaseador {
    final usuario = _valorMapa(widget.paseador, ['usuario', 'Usuario']);

    String raw = '';

    if (usuario is Map) {
      raw = _textoSeguro(
        usuario['fotoUrl'] ??
            usuario['FotoUrl'] ??
            usuario['imagenUrl'] ??
            usuario['ImagenUrl'],
        '',
      );
    }

    if (raw.isEmpty) {
      raw = _textoSeguro(
        _valorMapa(widget.paseador, [
          'fotoUrl',
          'FotoUrl',
          'imagenUrl',
          'ImagenUrl',
          'foto',
          'Foto',
        ]),
        '',
      );
    }

    return _armarUrlImagen(raw);
  }

  double get _tarifaPorHora {
    return _toDouble(_valorMapa(widget.paseador, [
          'tarifaPorHora',
          'TarifaPorHora',
          'tarifa',
          'Tarifa',
          'precioHora',
          'PrecioHora',
        ])) ??
        0.0;
  }

  double get _total {
    final horas = _duracionMinutos / 60.0;
    return _tarifaPorHora * horas;
  }

  String _nombrePerro(Map<String, dynamic> perro) {
    return _textoSeguro(
      _valorMapa(perro, [
        'nombre',
        'Nombre',
        'nombrePerro',
        'NombrePerro',
      ]),
      'Perro',
    );
  }

  String _razaPerro(Map<String, dynamic> perro) {
    return _textoSeguro(
      _valorMapa(perro, ['raza', 'Raza']),
      'Sin raza',
    );
  }

  int _idPerro(Map<String, dynamic> perro) {
    return _toInt(_valorMapa(perro, ['id', 'Id', 'perroId', 'PerroId'])) ?? 0;
  }

  String _fotoPerro(Map<String, dynamic> perro) {
    final raw = _textoSeguro(
      _valorMapa(perro, [
        'fotoUrl',
        'FotoUrl',
        'imagenUrl',
        'ImagenUrl',
        'foto',
        'Foto',
        'urlFoto',
        'UrlFoto',
        'fotoPerroUrl',
        'FotoPerroUrl',
      ]),
      '',
    );

    return _armarUrlImagen(raw);
  }

  String _armarUrlImagen(String raw) {
    final value = raw.trim();

    if (value.isEmpty || value.toLowerCase() == 'null') return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return '';

    if (value.startsWith('/')) return '$base$value';

    return '$base/$value';
  }

  String _duracionTexto(int minutos) {
    if (minutos == 60) return '1 hora';
    if (minutos == 90) return '1.5 hrs';
    return '$minutos min';
  }

  String _duracionSubtitulo(int minutos) {
    if (minutos == 30) return 'Paseo rápido';
    if (minutos == 45) return 'Rutina completa';
    if (minutos == 60) return 'Paseo largo';
    return 'Actividad alta';
  }

  IconData _duracionIcono(int minutos) {
    if (minutos == 30) return Icons.flash_on_rounded;
    if (minutos == 45) return Icons.directions_walk_rounded;
    if (minutos == 60) return Icons.route_rounded;
    return Icons.local_fire_department_rounded;
  }

  String _moneda(num valor) {
    return '\$${valor.toDouble().toStringAsFixed(2)}';
  }

  String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Toca para programar';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio a las $hora:$minuto';
  }

  Future<void> _seleccionarFechaHora() async {
    final ahora = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaProgramada ?? ahora,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: ahora.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: DogGoTheme.teal,
                ),
          ),
          child: child!,
        );
      },
    );

    if (fecha == null) return;

    if (!mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _fechaProgramada ?? ahora.add(const Duration(hours: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: DogGoTheme.teal,
                ),
          ),
          child: child!,
        );
      },
    );

    if (hora == null) return;

    setState(() {
      _fechaProgramada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _abrirMapaSeleccion() async {
    final ubicacionInicial =
        _latitudRecogida != null && _longitudRecogida != null
            ? LatLng(_latitudRecogida!, _longitudRecogida!)
            : null;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarUbicacionScreen(
          ubicacionInicial: ubicacionInicial,
          textoInicial: _direccionRecogida,
        ),
      ),
    );

    if (result == null) return;

    final lat = _toDouble(
      result['latitud'] ?? result['Latitud'] ?? result['lat'] ?? result['Lat'],
    );

    final lng = _toDouble(
      result['longitud'] ??
          result['Longitud'] ??
          result['lng'] ??
          result['Lng'] ??
          result['lon'] ??
          result['Lon'],
    );

    final texto = _textoSeguro(
      result['direccionRecogida'] ??
          result['DireccionRecogida'] ??
          result['ubicacionTexto'] ??
          result['UbicacionTexto'] ??
          result['texto'] ??
          result['Texto'],
      'Ubicación seleccionada',
    );

    if (lat == null || lng == null) {
      _snack('No se pudo leer la ubicación seleccionada.');
      return;
    }

    setState(() {
      _latitudRecogida = lat;
      _longitudRecogida = lng;
      _direccionRecogida = texto;
      _referenciasRecogida = texto;
    });
  }

  Future<void> _usarUbicacionActual() async {
    setState(() {
      _cargandoUbicacionPredeterminada = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('El GPS está desactivado. Enciéndelo.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Los permisos de ubicación están denegados permanentemente.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _latitudRecogida = position.latitude;
        _longitudRecogida = position.longitude;
        _direccionRecogida = 'Ubicación actual';
        _referenciasRecogida = 'Ubicación actual';
      });

      _snack('Ubicación actual seleccionada.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _cargandoUbicacionPredeterminada = false;
        });
      }
    }
  }

  void _usarUbicacionPredeterminada() {
    final data = _ubicacionPredeterminada;

    if (data == null) {
      _snack('No tienes ubicación predeterminada guardada.');
      return;
    }

    final lat = _toDouble(_valorMapa(data, [
      'latitudRecogida',
      'LatitudRecogida',
      'latitud',
      'Latitud',
      'lat',
      'Lat',
    ]));

    final lng = _toDouble(_valorMapa(data, [
      'longitudRecogida',
      'LongitudRecogida',
      'longitud',
      'Longitud',
      'lng',
      'Lng',
      'lon',
      'Lon',
    ]));

    final direccion = _textoSeguro(
      _valorMapa(data, [
        'direccionRecogida',
        'DireccionRecogida',
        'direccion',
        'Direccion',
        'ubicacionTexto',
        'UbicacionTexto',
      ]),
      'Ubicación predeterminada',
    );

    if (lat == null || lng == null) {
      _snack('Tu ubicación predeterminada no tiene coordenadas.');
      return;
    }

    setState(() {
      _latitudRecogida = lat;
      _longitudRecogida = lng;
      _direccionRecogida = direccion;
      _referenciasRecogida = direccion;
    });

    _snack('Ubicación predeterminada seleccionada.');
  }

  bool get _tieneUbicacion {
    return _latitudRecogida != null && _longitudRecogida != null;
  }

  Future<void> _confirmarPaseo() async {
    if (_guardando) return;

    final perro = _perroSeleccionado;

    if (perro == null || _idPerro(perro) <= 0) {
      _snack('Selecciona un perro.');
      return;
    }

    if (_paseadorId <= 0) {
      _snack('No se pudo identificar al paseador.');
      return;
    }

    if (_fechaProgramada == null) {
      _snack('Selecciona fecha y hora del paseo.');
      return;
    }

    if (!_tieneUbicacion) {
      _snack('Selecciona el punto de recogida.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    final body = {
      'paseadorId': _paseadorId,
      'PaseadorId': _paseadorId,
      'perroId': _idPerro(perro),
      'PerroId': _idPerro(perro),
      'perrosIds': [_idPerro(perro)],
      'PerrosIds': [_idPerro(perro)],
      'duracionMinutos': _duracionMinutos,
      'DuracionMinutos': _duracionMinutos,
      'esProgramado': true,
      'EsProgramado': true,
      'fechaProgramada': _fechaProgramada!.toIso8601String(),
      'FechaProgramada': _fechaProgramada!.toIso8601String(),
      'latitudRecogida': _latitudRecogida,
      'LatitudRecogida': _latitudRecogida,
      'longitudRecogida': _longitudRecogida,
      'LongitudRecogida': _longitudRecogida,
      'direccionRecogida': _direccionRecogida ?? 'Ubicación seleccionada',
      'DireccionRecogida': _direccionRecogida ?? 'Ubicación seleccionada',
      'referenciasRecogida': _notasController.text.trim().isNotEmpty
          ? _notasController.text.trim()
          : (_referenciasRecogida ?? ''),
      'ReferenciasRecogida': _notasController.text.trim().isNotEmpty
          ? _notasController.text.trim()
          : (_referenciasRecogida ?? ''),
      'precio': _total,
      'Precio': _total,
    };

    final endpoints = [
      '/api/paseos/solicitar',
      '/api/Paseos/solicitar',
      '/api/paseos/programar',
      '/api/Paseos/programar',
      '/api/paseos',
      '/api/Paseos',
    ];

    try {
      Map<String, dynamic>? ultimaRespuesta;
      String? ultimoMensaje;

      for (final endpoint in endpoints) {
        try {
          final respuesta = await ApiService.postAuth(endpoint, body);
          final statusCode = respuesta['statusCode'];
          final responseBody = respuesta['body'];

          ultimaRespuesta = respuesta;

          if (statusCode is int && statusCode >= 200 && statusCode < 300) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Paseo programado correctamente.'),
                backgroundColor: DogGoTheme.teal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );

            Navigator.pop(context, true);
            return;
          }

          if (responseBody is Map) {
            ultimoMensaje = responseBody['message']?.toString() ??
                responseBody['mensaje']?.toString() ??
                responseBody['error']?.toString();
          } else if (responseBody != null) {
            ultimoMensaje = responseBody.toString();
          }
        } catch (e) {
          ultimoMensaje = e.toString().replaceFirst('Exception: ', '');
          continue;
        }
      }

      final statusCode = ultimaRespuesta?['statusCode'];
      throw Exception(
        ultimoMensaje ??
            'No se pudo crear el paseo. Código: ${statusCode ?? 'sin respuesta'}',
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _snack(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DogGoTheme.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: DogGoTheme.cream,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: DogGoTheme.cream,
        appBar: AppBar(
          backgroundColor: DogGoTheme.cream,
          elevation: 0,
          foregroundColor: DogGoTheme.ink,
          title: const Text('Programar Paseo'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _ErrorCard(
              mensaje: _error!,
              onRetry: _inicializar,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        backgroundColor: DogGoTheme.cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DogGoTheme.ink,
        centerTitle: true,
        title: Text(
          'Programar Paseo',
          style: DogGoTheme.title(size: 20),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: BoxDecoration(
            color: DogGoTheme.cream.withOpacity(.96),
            border: Border(
              top: BorderSide(
                color: DogGoTheme.border.withOpacity(.8),
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _guardando ? null : _confirmarPaseo,
              style: DogGoTheme.primaryButton(),
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Confirmar y programar · ${_moneda(_total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(),
              const SizedBox(height: 24),
              Text(
                'Paseador seleccionado',
                style: DogGoTheme.title(size: 22),
              ),
              const SizedBox(height: 12),
              _PaseadorSeleccionadoCard(
                nombre: _nombrePaseador,
                fotoUrl: _fotoPaseador,
                tarifa: _tarifaPorHora,
              ),
              const SizedBox(height: 26),
              Text(
                '¿A quién paseamos?',
                style: DogGoTheme.title(size: 22),
              ),
              const SizedBox(height: 12),
              if (_perros.isEmpty)
                _SinPerrosCard()
              else
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _perros.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final perro = _perros[index];
                      final selected =
                          _idPerro(perro) == _idPerro(_perroSeleccionado ?? {});

                      return _PerroSeleccionCard(
                        nombre: _nombrePerro(perro),
                        raza: _razaPerro(perro),
                        fotoUrl: _fotoPerro(perro),
                        selected: selected,
                        onTap: () {
                          setState(() {
                            _perroSeleccionado = perro;
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 28),
              Text(
                'Duración del paseo',
                style: DogGoTheme.title(size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Elige la duración ideal. El costo se calcula automáticamente con la tarifa del paseador.',
                style: DogGoTheme.subtitle(size: 13.5),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _duraciones.map((minutos) {
                      final selected = minutos == _duracionMinutos;
                      final precio = _tarifaPorHora * (minutos / 60.0);

                      return SizedBox(
                        width: itemWidth,
                        child: _DurationOptionCard(
                          icon: _duracionIcono(minutos),
                          title: _duracionTexto(minutos),
                          subtitle: _duracionSubtitulo(minutos),
                          price: _moneda(precio),
                          selected: selected,
                          onTap: () {
                            setState(() {
                              _duracionMinutos = minutos;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 22),
              _PrecioCard(
                tarifaPorHora: _tarifaPorHora,
                duracionMinutos: _duracionMinutos,
                total: _total,
              ),
              const SizedBox(height: 28),
              Text(
                '¿Cuándo?',
                style: DogGoTheme.title(size: 22),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.calendar_month_rounded,
                iconColor: DogGoTheme.purple,
                iconBackground: DogGoTheme.purple.withOpacity(.14),
                title: 'Fecha y hora',
                subtitle: _fechaTexto(_fechaProgramada),
                selected: _fechaProgramada != null,
                onTap: _seleccionarFechaHora,
              ),
              const SizedBox(height: 28),
              Text(
                'Punto de encuentro',
                style: DogGoTheme.title(size: 22),
              ),
              const SizedBox(height: 12),
              _MapPreviewCard(
                direccion: _direccionRecogida,
                latitud: _latitudRecogida,
                longitud: _longitudRecogida,
                onTap: _abrirMapaSeleccion,
              ),
              const SizedBox(height: 12),
              if (_ubicacionPredeterminada != null)
                _SmallActionRow(
                  icon: Icons.home_work_rounded,
                  title: 'Usar mi ubicación predeterminada',
                  subtitle: 'Usa la dirección guardada en tu perfil.',
                  onTap: _usarUbicacionPredeterminada,
                ),
              const SizedBox(height: 10),
              _SmallActionRow(
                icon: Icons.my_location_rounded,
                title: 'Usar mi ubicación actual',
                subtitle: _cargandoUbicacionPredeterminada
                    ? 'Obteniendo ubicación...'
                    : 'Toma la ubicación del teléfono.',
                loading: _cargandoUbicacionPredeterminada,
                onTap: _cargandoUbicacionPredeterminada ? null : _usarUbicacionActual,
              ),
              const SizedBox(height: 28),
              Text(
                'Notas para el paseador (Opcional)',
                style: DogGoTheme.title(size: 21),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notasController,
                minLines: 3,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ej. Cansa rápido, llevarle agua...',
                  hintStyle: DogGoTheme.subtitle(size: 14),
                  filled: true,
                  fillColor: DogGoTheme.card,
                  contentPadding: const EdgeInsets.all(18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: DogGoTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: DogGoTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: DogGoTheme.teal,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ResumenSolicitudCard(
                perro: _perroSeleccionado == null
                    ? 'Selecciona perro'
                    : _nombrePerro(_perroSeleccionado!),
                duracion: _duracionTexto(_duracionMinutos),
                fecha: _fechaProgramada == null
                    ? 'Toca para programar'
                    : _fechaTexto(_fechaProgramada),
                tarifa: _tarifaPorHora,
                total: _total,
                ubicacionLista: _tieneUbicacion,
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(30),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -20,
            child: Transform.rotate(
              angle: -.16,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevo paseo DogGo',
                      style: DogGoTheme.body(
                        size: 13,
                        color: Colors.white.withOpacity(.9),
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Programa la salida de tu perro',
                      style: DogGoTheme.title(
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Elige perro, horario y punto de recogida.',
                      style: DogGoTheme.body(
                        size: 14,
                        color: Colors.white.withOpacity(.9),
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaseadorSeleccionadoCard extends StatelessWidget {
  final String nombre;
  final String fotoUrl;
  final double tarifa;

  const _PaseadorSeleccionadoCard({
    required this.nombre,
    required this.fotoUrl,
    required this.tarifa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Row(
        children: [
          _AvatarImage(
            url: fotoUrl,
            icon: Icons.person_rounded,
            size: 62,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.title(size: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${tarifa.toStringAsFixed(2)} / hora',
                  style: DogGoTheme.body(
                    size: 13,
                    color: DogGoTheme.muted,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            color: DogGoTheme.teal,
            size: 30,
          ),
        ],
      ),
    );
  }
}

class _PerroSeleccionCard extends StatelessWidget {
  final String nombre;
  final String raza;
  final String fotoUrl;
  final bool selected;
  final VoidCallback onTap;

  const _PerroSeleccionCard({
    required this.nombre,
    required this.raza,
    required this.fotoUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? DogGoTheme.red : DogGoTheme.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 132,
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? DogGoTheme.softShadow() : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: fotoUrl.isNotEmpty
                  ? Image.network(
                      fotoUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const _DogFallbackImage();
                      },
                    )
                  : const _DogFallbackImage(),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 11, 8, 12),
              child: Column(
                children: [
                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.body(
                      size: 14,
                      color: selected ? DogGoTheme.red : DogGoTheme.ink,
                      weight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    raza,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.subtitle(size: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const _DurationOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? DogGoTheme.teal : DogGoTheme.card;
    final fg = selected ? Colors.white : DogGoTheme.ink;
    final muted = selected ? Colors.white.withOpacity(.82) : DogGoTheme.muted;

      return Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(
              minHeight: 122,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? DogGoTheme.teal : DogGoTheme.border,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: DogGoTheme.teal.withOpacity(.26),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(.035),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  right: -18,
                  top: -18,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(.16)
                              : DogGoTheme.tealLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          color: selected ? Colors.white : DogGoTheme.teal,
                          size: 23,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : DogGoTheme.border.withOpacity(.9),
                            width: 1.5,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: DogGoTheme.teal,
                                size: 18,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.title(
                      size: 18,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.body(
                      size: 12.2,
                      color: muted,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.body(
                      size: 14,
                      color: selected ? Colors.white : DogGoTheme.orange,
                      weight: FontWeight.w900,
                    ),
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

class _PrecioCard extends StatelessWidget {
  final double tarifaPorHora;
  final int duracionMinutos;
  final double total;

  const _PrecioCard({
    required this.tarifaPorHora,
    required this.duracionMinutos,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final horas = duracionMinutos / 60.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight.withOpacity(.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DogGoTheme.orange.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.78),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: DogGoTheme.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Costo estimado',
                  style: DogGoTheme.title(size: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  '\$${tarifaPorHora.toStringAsFixed(2)} / hora × ${horas.toStringAsFixed(horas % 1 == 0 ? 0 : 1)} h',
                  style: DogGoTheme.subtitle(size: 13),
                ),
              ],
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: DogGoTheme.title(
              size: 22,
              color: DogGoTheme.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? iconColor : DogGoTheme.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.body(
                        size: 16,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(size: 13),
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

class _MapPreviewCard extends StatelessWidget {
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final VoidCallback onTap;

  const _MapPreviewCard({
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.onTap,
  });

  bool get _selected => latitud != null && longitud != null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color:
                  _selected ? DogGoTheme.teal.withOpacity(.55) : DogGoTheme.border,
              width: _selected ? 1.4 : 1,
            ),
            boxShadow: DogGoTheme.softShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 126,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MapPreviewPainter(),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _selected ? 'Mapa seleccionado' : 'Toca para elegir',
                          style: DogGoTheme.body(
                            size: 12,
                            color: DogGoTheme.teal,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.88),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          _selected
                              ? Icons.location_on_rounded
                              : Icons.add_location_alt_rounded,
                          color: DogGoTheme.teal,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: DogGoTheme.tealLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: DogGoTheme.teal,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lugar de recogida',
                            style: DogGoTheme.body(
                              size: 16,
                              color: DogGoTheme.ink,
                              weight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selected
                                ? (direccion?.trim().isNotEmpty == true
                                    ? direccion!.trim()
                                    : '${latitud!.toStringAsFixed(5)}, ${longitud!.toStringAsFixed(5)}')
                                : 'Toca para abrir el mapa y elegir dirección',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.subtitle(size: 13),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onTap;

  const _SmallActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: DogGoTheme.teal,
                        ),
                      )
                    : Icon(
                        icon,
                        color: DogGoTheme.teal,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.body(
                        size: 14.5,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: DogGoTheme.subtitle(size: 12.5),
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

class _ResumenSolicitudCard extends StatelessWidget {
  final String perro;
  final String duracion;
  final String fecha;
  final double tarifa;
  final double total;
  final bool ubicacionLista;

  const _ResumenSolicitudCard({
    required this.perro,
    required this.duracion,
    required this.fecha,
    required this.tarifa,
    required this.total,
    required this.ubicacionLista,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight.withOpacity(.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DogGoTheme.orange.withOpacity(.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.78),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: DogGoTheme.orange,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de solicitud',
                  style: DogGoTheme.title(size: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '$perro · $duracion · $fecha',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.subtitle(size: 12.5),
                ),
                const SizedBox(height: 5),
                Text(
                  '\$${tarifa.toStringAsFixed(2)} / hora · Total \$${total.toStringAsFixed(2)}',
                  style: DogGoTheme.body(
                    size: 13,
                    color: DogGoTheme.orange,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ubicacionLista
                      ? 'Ubicación de recogida lista'
                      : 'Falta seleccionar ubicación',
                  style: DogGoTheme.body(
                    size: 12.5,
                    color: ubicacionLista ? DogGoTheme.green : DogGoTheme.red,
                    weight: FontWeight.w900,
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

class _SinPerrosCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pets_rounded,
            color: DogGoTheme.teal,
            size: 48,
          ),
          const SizedBox(height: 10),
          Text(
            'No tienes perros registrados',
            style: DogGoTheme.title(size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega un perro antes de solicitar un paseo.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: DogGoTheme.red,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No se pudo cargar',
            style: DogGoTheme.title(size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: DogGoTheme.primaryButton(),
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String url;
  final IconData icon;
  final double size;

  const _AvatarImage({
    required this.url,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(size * .30),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  icon,
                  color: DogGoTheme.teal,
                  size: size * .55,
                );
              },
            )
          : Icon(
              icon,
              color: DogGoTheme.teal,
              size: size * .55,
            ),
    );
  }
}

class _DogFallbackImage extends StatelessWidget {
  const _DogFallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DogGoTheme.tealLight,
      child: const Center(
        child: Icon(
          Icons.pets_rounded,
          color: DogGoTheme.teal,
          size: 48,
        ),
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = DogGoTheme.teal.withOpacity(.10)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(.65)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final mainRoadPaint = Paint()
      ..color = DogGoTheme.teal.withOpacity(.20)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-20, size.height * .72),
      Offset(size.width + 20, size.height * .25),
      mainRoadPaint,
    );

    canvas.drawLine(
      Offset(size.width * .18, -10),
      Offset(size.width * .72, size.height + 10),
      roadPaint,
    );

    canvas.drawLine(
      Offset(-10, size.height * .38),
      Offset(size.width + 10, size.height * .58),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * .68, -10),
      Offset(size.width * .68, size.height + 10),
      Paint()
        ..color = DogGoTheme.teal.withOpacity(.16)
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );

    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(.28)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 7; i++) {
      final x = (size.width / 7) * i + 12;
      final y = size.height * (.18 + .08 * math.sin(i));
      canvas.drawCircle(Offset(x, y), 5, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}