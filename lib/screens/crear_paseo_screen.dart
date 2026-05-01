import 'package:flutter/material.dart';

import '../services/paseadores_service.dart';
import '../services/perros_service.dart';
import '../services/paseos_service.dart';
import 'seleccionar_ubicacion_screen.dart';

class CrearPaseoScreen extends StatefulWidget {
  final Map<String, dynamic>? paseador;

  const CrearPaseoScreen({
    super.key,
    this.paseador,
  });

  @override
  State<CrearPaseoScreen> createState() => _CrearPaseoScreenState();
}

class _CrearPaseoScreenState extends State<CrearPaseoScreen> {
  List<dynamic> _perros = [];
  List<dynamic> _paseadores = [];

  bool _cargandoPerros = true;
  bool _cargandoPaseadores = false;
  bool _guardando = false;

  int? _perroIdSeleccionado;
  int? _paseadorIdSeleccionado;
  Map<String, dynamic>? _paseadorSeleccionado;

  int _duracion = 30;
  DateTime? _fechaSeleccionada;

  double? _latitudRecogida;
  double? _longitudRecogida;
  String? _ubicacionTexto;

  final TextEditingController _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.paseador != null) {
      _paseadorSeleccionado = _mapaSeguro(widget.paseador);
      _paseadorIdSeleccionado = _idPaseador(_paseadorSeleccionado!);
    }

    _cargarPerros();

    if (widget.paseador == null) {
      _cargarPaseadores();
    }
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _mapaSeguro(dynamic valor) {
    if (valor is Map<String, dynamic>) return valor;
    if (valor is Map) return Map<String, dynamic>.from(valor);
    return {};
  }

  dynamic _valor(Map<String, dynamic> mapa, List<String> keys) {
    for (final key in keys) {
      if (mapa.containsKey(key) && mapa[key] != null) {
        return mapa[key];
      }
    }

    return null;
  }

  int? _intSeguro(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  int? _idPaseador(Map<String, dynamic> paseador) {
    return _intSeguro(
      _valor(
        paseador,
        [
          'id',
          'Id',
          'paseadorId',
          'PaseadorId',
          'idPaseador',
          'IdPaseador',
        ],
      ),
    );
  }

  int? _idPerro(Map<String, dynamic> perro) {
    return _intSeguro(
      _valor(
        perro,
        [
          'id',
          'Id',
          'perroId',
          'PerroId',
          'idPerro',
          'IdPerro',
        ],
      ),
    );
  }

  Map<String, dynamic> _usuarioDe(Map<String, dynamic> paseador) {
    return _mapaSeguro(
      _valor(
        paseador,
        [
          'usuario',
          'Usuario',
          'user',
          'User',
          'datosUsuario',
          'DatosUsuario',
        ],
      ),
    );
  }

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _nombrePaseador(Map<String, dynamic>? paseador) {
    if (paseador == null || paseador.isEmpty) {
      return 'Selecciona un paseador';
    }

    final usuario = _usuarioDe(paseador);

    final nombreCompleto = _textoSeguro(
      _valor(
        paseador,
        [
          'nombreCompleto',
          'NombreCompleto',
          'paseadorNombreCompleto',
          'PaseadorNombreCompleto',
        ],
      ),
      '',
    );

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    final nombre = _textoSeguro(
      _valor(
            paseador,
            [
              'nombre',
              'Nombre',
              'paseadorNombre',
              'PaseadorNombre',
              'nombrePaseador',
              'NombrePaseador',
            ],
          ) ??
          _valor(
            usuario,
            [
              'nombre',
              'Nombre',
              'name',
              'Name',
            ],
          ),
      '',
    );

    final apellido = _textoSeguro(
      _valor(
            paseador,
            [
              'apellido',
              'Apellido',
              'paseadorApellido',
              'PaseadorApellido',
              'apellidoPaseador',
              'ApellidoPaseador',
            ],
          ) ??
          _valor(
            usuario,
            [
              'apellido',
              'Apellido',
              'lastName',
              'LastName',
            ],
          ),
      '',
    );

    final completo = '$nombre $apellido'.trim();

    return completo.isEmpty ? 'Paseador seleccionado' : completo;
  }

  String _zonaPaseador(Map<String, dynamic>? paseador) {
    if (paseador == null || paseador.isEmpty) {
      return 'Sin zona';
    }

    return _textoSeguro(
      _valor(
        paseador,
        [
          'zonaServicio',
          'ZonaServicio',
          'zona',
          'Zona',
          'zonas',
          'Zonas',
        ],
      ),
      'Sin zona',
    );
  }

  String _tarifaPaseador(Map<String, dynamic>? paseador) {
    if (paseador == null || paseador.isEmpty) {
      return 'Tarifa no disponible';
    }

    final tarifa = _valor(
      paseador,
      [
        'tarifaPorHora',
        'TarifaPorHora',
        'tarifa',
        'Tarifa',
        'precioHora',
        'PrecioHora',
      ],
    );

    if (tarifa == null) return 'Tarifa no disponible';

    final numero = double.tryParse(tarifa.toString());

    if (numero == null) {
      return '\$${tarifa.toString()} / hora';
    }

    return '\$${numero.toStringAsFixed(2)} / hora';
  }

  Future<void> _cargarPerros() async {
    setState(() {
      _cargandoPerros = true;
    });

    try {
      final result = await PerrosService.obtenerMisPerros();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        setState(() {
          _perros = data is List ? data : [];
          _cargandoPerros = false;
        });
      } else {
        setState(() {
          _cargandoPerros = false;
        });

        _mostrarMensaje(
          result['message']?.toString() ?? 'No se pudieron cargar tus perros.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoPerros = false;
      });

      _mostrarMensaje('Error de conexión: $e');
    }
  }

  Future<void> _cargarPaseadores() async {
    setState(() {
      _cargandoPaseadores = true;
    });

    try {
      final result = await PaseadoresService.obtenerPaseadores();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        setState(() {
          _paseadores = data is List ? data : [];
          _cargandoPaseadores = false;
        });
      } else {
        setState(() {
          _cargandoPaseadores = false;
        });

        _mostrarMensaje(
          result['message']?.toString() ??
              'No se pudieron cargar los paseadores.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoPaseadores = false;
      });

      _mostrarMensaje('Error al cargar paseadores: $e');
    }
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora,
      lastDate: DateTime(2030),
    );

    if (fecha == null) return;
    if (!mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora == null) return;

    setState(() {
      _fechaSeleccionada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _seleccionarUbicacion() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SeleccionarUbicacionScreen(),
      ),
    );

    if (!mounted) return;

    if (resultado == null) return;

    if (resultado is! Map) {
      _mostrarMensaje('No se pudo leer la ubicación seleccionada.');
      return;
    }

    final latitud = _leerDouble(
      resultado,
      [
        'latitud',
        'lat',
        'latitude',
        'latitudRecogida',
      ],
    );

    final longitud = _leerDouble(
      resultado,
      [
        'longitud',
        'lng',
        'lon',
        'longitude',
        'longitudRecogida',
      ],
    );

    final texto = _leerTexto(
      resultado,
      [
        'ubicacionTexto',
        'direccionRecogida',
        'direccion',
        'texto',
        'descripcion',
        'nombre',
      ],
    );

    if (latitud == null || longitud == null) {
      _mostrarMensaje('La ubicación seleccionada no tiene coordenadas válidas.');
      return;
    }

    setState(() {
      _latitudRecogida = latitud;
      _longitudRecogida = longitud;
      _ubicacionTexto =
          texto.isNotEmpty ? texto : 'Ubicación seleccionada en el mapa';
    });
  }

  double? _leerDouble(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) continue;

      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();

      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }

    return null;
  }

  String _leerTexto(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) continue;

      final texto = value.toString().trim();

      if (texto.isNotEmpty) {
        return texto;
      }
    }

    return '';
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  String _formatearCoordenadas() {
    if (_latitudRecogida == null || _longitudRecogida == null) {
      return '';
    }

    return '${_latitudRecogida!.toStringAsFixed(6)}, ${_longitudRecogida!.toStringAsFixed(6)}';
  }

  Future<void> _crearPaseo() async {
    final paseadorId = _paseadorIdSeleccionado ??
        (_paseadorSeleccionado == null
            ? null
            : _idPaseador(_paseadorSeleccionado!));

    if (paseadorId == null) {
      _mostrarMensaje('Selecciona un paseador.');
      return;
    }

    if (_perroIdSeleccionado == null) {
      _mostrarMensaje('Selecciona un perro.');
      return;
    }

    if (_fechaSeleccionada == null) {
      _mostrarMensaje('Selecciona fecha y hora.');
      return;
    }

    if (_latitudRecogida == null || _longitudRecogida == null) {
      _mostrarMensaje('Selecciona la ubicación de recogida en el mapa.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final result = await PaseosService.crearPaseo(
        paseadorId: paseadorId,
        perroId: _perroIdSeleccionado!,
        fechaProgramada: _fechaSeleccionada!,
        duracionMinutos: _duracion,
        latitudRecogida: _latitudRecogida,
        longitudRecogida: _longitudRecogida,
        ubicacionTexto: _ubicacionTexto,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _mostrarMensaje(
          result['message']?.toString() ?? 'Paseo creado correctamente.',
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(
          result['message']?.toString() ?? 'No se pudo crear el paseo.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombrePaseador = _nombrePaseador(_paseadorSeleccionado);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Crear paseo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EDE3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7E0D5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NUEVO PASEO',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF14A89A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agenda un paseo',
                  style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paseador: $nombrePaseador',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.paseador == null)
            _FormCard(
              titulo: 'Selecciona un paseador',
              child: _cargandoPaseadores
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _paseadores.isEmpty
                      ? const Text(
                          'No hay paseadores disponibles.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          value: _paseadorIdSeleccionado,
                          items: _paseadores.map((paseadorRaw) {
                            final paseador = _mapaSeguro(paseadorRaw);
                            final id = _idPaseador(paseador);

                            if (id == null) {
                              return null;
                            }

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(_nombrePaseador(paseador)),
                            );
                          }).whereType<DropdownMenuItem<int>>().toList(),
                          onChanged: _guardando
                              ? null
                              : (value) {
                                  if (value == null) return;

                                  final encontrado = _paseadores
                                      .map(_mapaSeguro)
                                      .where(
                                        (p) => _idPaseador(p) == value,
                                      )
                                      .cast<Map<String, dynamic>?>()
                                      .firstWhere(
                                        (p) => p != null,
                                        orElse: () => null,
                                      );

                                  setState(() {
                                    _paseadorIdSeleccionado = value;
                                    _paseadorSeleccionado = encontrado;
                                  });
                                },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8F4EC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
            )
          else
            _FormCard(
              titulo: 'Paseador seleccionado',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4EC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF14A89A).withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF14A89A).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF14A89A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombrePaseador,
                            style: const TextStyle(
                              color: Color(0xFF25324A),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_zonaPaseador(_paseadorSeleccionado)} · ${_tarifaPaseador(_paseadorSeleccionado)}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Selecciona tu perro',
            child: _cargandoPerros
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _perros.isEmpty
                    ? const Text(
                        'No tienes perros registrados todavía.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        value: _perroIdSeleccionado,
                        items: _perros.map((perroRaw) {
                          final perro = _mapaSeguro(perroRaw);
                          final id = _idPerro(perro);

                          if (id == null) {
                            return null;
                          }

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              _textoSeguro(
                                _valor(
                                  perro,
                                  [
                                    'nombre',
                                    'Nombre',
                                    'nombrePerro',
                                    'NombrePerro',
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).whereType<DropdownMenuItem<int>>().toList(),
                        onChanged: _guardando
                            ? null
                            : (value) {
                                setState(() {
                                  _perroIdSeleccionado = value;
                                });
                              },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8F4EC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Duración',
            child: Column(
              children: [
                Slider(
                  value: _duracion.toDouble(),
                  min: 30,
                  max: 120,
                  divisions: 3,
                  label: '$_duracion min',
                  onChanged: _guardando
                      ? null
                      : (value) {
                          setState(() {
                            _duracion = value.toInt();
                          });
                        },
                ),
                Text(
                  '$_duracion minutos',
                  style: const TextStyle(
                    color: Color(0xFF25324A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Fecha y hora',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _fechaSeleccionada == null
                      ? 'No seleccionada'
                      : _formatearFecha(_fechaSeleccionada!),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _guardando ? null : _seleccionarFecha,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Seleccionar fecha'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Ubicación de recogida',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4EC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _latitudRecogida == null
                          ? const Color(0xFFE7E2D9)
                          : const Color(0xFF14A89A).withOpacity(0.45),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14A89A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF14A89A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _latitudRecogida == null
                            ? const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sin ubicación seleccionada',
                                    style: TextStyle(
                                      color: Color(0xFF25324A),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Elige en el mapa dónde debe recoger al perro el paseador.',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ubicacionTexto ??
                                        'Ubicación seleccionada en el mapa',
                                    style: const TextStyle(
                                      color: Color(0xFF25324A),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatearCoordenadas(),
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _guardando ? null : _seleccionarUbicacion,
                  icon: const Icon(Icons.map_rounded),
                  label: Text(
                    _latitudRecogida == null
                        ? 'Seleccionar en mapa'
                        : 'Cambiar ubicación',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormCard(
            titulo: 'Notas',
            child: TextField(
              controller: _notasController,
              enabled: !_guardando,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Indica algo importante para el paseo...',
                filled: true,
                fillColor: const Color(0xFFF8F4EC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _guardando ? null : _crearPaseo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14A89A),
                disabledBackgroundColor:
                    const Color(0xFF14A89A).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Confirmar paseo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _FormCard({
    required this.titulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF25324A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}