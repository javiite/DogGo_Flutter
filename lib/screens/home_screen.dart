import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/paseos_service.dart';
import '../services/perros_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../services/notificaciones_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'login_screen.dart';
import 'mis_perros_screen.dart';
import 'mis_paseos_screen.dart';
import 'notificaciones_screen.dart';
import 'paseadores_screen.dart';
import 'perfil_screen.dart';
import 'chat_paseo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cargando = true;
  bool _cargandoPerros = false;
  bool _cargandoPaseos = false;

  String _nombre = 'Usuario';
  String _rol = 'Usuario';
  String? _baseUrl;
  String? _errorPerros;
  String? _errorPaseos;

  List<dynamic> _perros = [];
  List<dynamic> _paseos = [];

  DateTime _mesCalendario = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  final GlobalKey _inicioKey = GlobalKey();
  final GlobalKey _agendaKey = GlobalKey();
  final GlobalKey _mascotasKey = GlobalKey();
  final GlobalKey _guiasKey = GlobalKey();

  int _navIndex = 0;

  final NotificacionesService _notificacionesService = NotificacionesService();

  Timer? _notificacionesTimer;
  int _notificacionesNoLeidas = 0;
  int? _ultimaNotificacionMostradaId;
  bool _revisandoNotificaciones = false;

  final List<_TipData> _consejos = const [
    _TipData(
      icon: Icons.restaurant_menu_rounded,
      categoria: 'Nutrición',
      titulo: 'Alimentación según tamaño y edad',
      descripcion:
          'La alimentación ideal depende del tamaño, edad, actividad y condición física de cada perro.',
      lectura: '5 min',
      puntos: [
        'Cuida porciones para evitar sobrepeso.',
        'Evita chocolate, cebolla, uvas y comida grasosa.',
        'Ajusta la comida si tu perro tiene paseos largos.',
      ],
      recomendacion:
          'Revisa la etiqueta del alimento y mantén horarios constantes.',
    ),
    _TipData(
      icon: Icons.directions_run_rounded,
      categoria: 'Ejercicio',
      titulo: 'Frecuencia ideal de paseos',
      descripcion:
          'Los paseos reducen ansiedad, mejoran socialización y mantienen una rutina saludable.',
      lectura: '4 min',
      puntos: [
        'Perros activos pueden necesitar dos salidas al día.',
        'Perros mayores requieren paseos más cortos.',
        'Evita horas de mucho calor.',
      ],
      recomendacion:
          'Agenda paseos constantes para que tu perro tenga una rutina clara.',
    ),
    _TipData(
      icon: Icons.vaccines_rounded,
      categoria: 'Salud',
      titulo: 'Vacunas y prevención básica',
      descripcion:
          'Mantener vacunas y desparasitación al día hace más seguros los paseos con otros perros.',
      lectura: '4 min',
      puntos: [
        'Lleva registro de vacunas.',
        'Pregunta por desparasitación interna y externa.',
        'Evita mezclar cachorros sin esquema completo.',
      ],
      recomendacion:
          'Guarda notas de salud para que el paseador conozca cuidados importantes.',
    ),
    _TipData(
      icon: Icons.water_drop_rounded,
      categoria: 'Hidratación',
      titulo: 'Agua antes y después del paseo',
      descripcion:
          'Una buena hidratación ayuda a evitar agotamiento, golpes de calor y estrés durante caminatas largas.',
      lectura: '3 min',
      puntos: [
        'Lleva agua si el paseo dura más de 30 minutos.',
        'Evita correr justo después de comer.',
        'Observa jadeo excesivo o cansancio repentino.',
      ],
      recomendacion:
          'Para días calurosos, agenda paseos temprano o al atardecer.',
    ),
    _TipData(
      icon: Icons.clean_hands_rounded,
      categoria: 'Higiene',
      titulo: 'Cuidado de patas y pelaje',
      descripcion:
          'Después de caminar, revisar patas y pelaje ayuda a detectar heridas, espinas o irritaciones.',
      lectura: '4 min',
      puntos: [
        'Limpia almohadillas si hubo tierra o lluvia.',
        'Revisa uñas y espacios entre dedos.',
        'Cepilla razas de pelo largo con frecuencia.',
      ],
      recomendacion:
          'Agrega notas si tu perro tiene alergias o zonas sensibles.',
    ),
    _TipData(
      icon: Icons.psychology_rounded,
      categoria: 'Conducta',
      titulo: 'Ansiedad y socialización',
      descripcion:
          'Algunos perros necesitan acercamientos graduales para convivir con personas, ruido y otros perros.',
      lectura: '5 min',
      puntos: [
        'No fuerces saludos con perros desconocidos.',
        'Premia conducta tranquila.',
        'Usa paseos cortos si tu perro se estresa fácil.',
      ],
      recomendacion:
          'Comparte indicaciones claras con el paseador antes de cada salida.',
    ),
  ];

  final List<_ProductData> _productos = const [
    _ProductData(
      icon: Icons.health_and_safety_rounded,
      titulo: 'Arnés antipull ajustable',
      descripcion:
          'Mejora el control durante el paseo y reduce jalones sin cargar toda la presión en el cuello.',
      etiqueta1: 'Paseos',
      etiqueta2: 'Seguridad',
      detalle:
          'Útil para perros fuertes, nerviosos o que jalan mucho durante la caminata.',
      url: 'https://www.amazon.com.mx/s?k=arnes+antipull+para+perro',
    ),
    _ProductData(
      icon: Icons.bed_rounded,
      titulo: 'Cama ortopédica',
      descripcion:
          'Buena opción para perros mayores o razas grandes que necesitan mejor soporte al descansar.',
      etiqueta1: 'Descanso',
      etiqueta2: 'Comodidad',
      detalle:
          'Ayuda a cuidar articulaciones y mejora el descanso después de paseos largos.',
      url: 'https://www.amazon.com.mx/s?k=cama+ortopedica+para+perros',
    ),
    _ProductData(
      icon: Icons.cookie_rounded,
      titulo: 'Premios para entrenamiento',
      descripcion:
          'Sirven para reforzar buen comportamiento, practicar comandos y premiar después del paseo.',
      etiqueta1: 'Nutrición',
      etiqueta2: 'Entrenamiento',
      detalle: 'Busca opciones sin exceso de sal, colorantes o conservadores.',
      url: 'https://www.amazon.com.mx/s?k=snacks+naturales+para+perro',
    ),
    _ProductData(
      icon: Icons.water_drop_rounded,
      titulo: 'Botella portátil con bebedero',
      descripcion:
          'Ideal para paseos largos, parques o traslados. Permite dar agua sin cargar recipientes extra.',
      etiqueta1: 'Hidratación',
      etiqueta2: 'Exterior',
      detalle:
          'Muy útil en Monterrey por el calor; evita caminar sin agua en horarios pesados.',
      url: 'https://www.amazon.com.mx/s?k=botella+portatil+perro+bebedero',
    ),
    _ProductData(
      icon: Icons.light_mode_rounded,
      titulo: 'Collar o placa reflejante',
      descripcion:
          'Aumenta visibilidad cuando el paseo es muy temprano, de noche o en zonas con poca luz.',
      etiqueta1: 'Visibilidad',
      etiqueta2: 'Noche',
      detalle:
          'Ayuda a que autos, ciclistas y personas vean mejor al perro durante el recorrido.',
      url: 'https://www.amazon.com.mx/s?k=collar+reflejante+para+perro',
    ),
    _ProductData(
      icon: Icons.cleaning_services_rounded,
      titulo: 'Bolsas biodegradables',
      descripcion:
          'Básicas para mantener limpios parques, calles y fraccionamientos durante cada paseo.',
      etiqueta1: 'Higiene',
      etiqueta2: 'Paseos',
      detalle:
          'Conviene traer un rollo extra en la correa o mochila del paseador.',
      url: 'https://www.amazon.com.mx/s?k=bolsas+biodegradables+para+perro',
    ),
  ];

  final List<_BreedData> _razas = const [
    _BreedData(
      nombre: 'Golden Retriever',
      resumen: 'Mediano–Grande · 25–34 kg',
      detalle:
          'Sociable, activo e inteligente. Necesita ejercicio constante, convivencia y estimulación.',
      imageUrl: 'https://loremflickr.com/900/600/goldenretriever,dog/all',
    ),
    _BreedData(
      nombre: 'Poodle',
      resumen: 'Pequeño–Grande · 3–32 kg',
      detalle:
          'Muy inteligente y fácil de entrenar. Requiere cepillado frecuente y actividad mental.',
      imageUrl: 'https://loremflickr.com/900/600/poodle,dog/all',
    ),
    _BreedData(
      nombre: 'Labrador Retriever',
      resumen: 'Grande · 25–36 kg',
      detalle:
          'Sociable, energético y juguetón. Le convienen paseos largos y control de alimentación.',
      imageUrl: 'https://loremflickr.com/900/600/labrador,dog/all',
    ),
    _BreedData(
      nombre: 'French Bulldog',
      resumen: 'Pequeño · 8–14 kg',
      detalle:
          'Perro de compañía. Puede ser sensible al calor, por eso conviene evitar paseos intensos.',
      imageUrl: 'https://loremflickr.com/900/600/frenchbulldog,dog/all',
    ),
    _BreedData(
      nombre: 'Pastor Alemán',
      resumen: 'Grande · 22–40 kg',
      detalle:
          'Activo, protector y entrenable. Necesita socialización, obediencia y ejercicio diario.',
      imageUrl: 'https://loremflickr.com/900/600/germanshepherd,dog/all',
    ),
    _BreedData(
      nombre: 'Husky Siberiano',
      resumen: 'Mediano · 16–27 kg',
      detalle:
          'Energético, resistente y sociable. Requiere paseos largos y manejo cuidadoso del calor.',
      imageUrl: 'https://loremflickr.com/900/600/husky,dog/all',
    ),
    _BreedData(
      nombre: 'Chihuahua',
      resumen: 'Pequeño · 1–3 kg',
      detalle:
          'Alerta y leal. Sus paseos pueden ser cortos, pero necesita socialización constante.',
      imageUrl: 'https://loremflickr.com/900/600/chihuahua,dog/all',
    ),
    _BreedData(
      nombre: 'Beagle',
      resumen: 'Mediano · 9–14 kg',
      detalle:
          'Curioso, olfativo y juguetón. Conviene usar correa segura porque sigue rastros fácilmente.',
      imageUrl: 'https://loremflickr.com/900/600/beagle,dog/all',
    ),
    _BreedData(
      nombre: 'Border Collie',
      resumen: 'Mediano · 14–20 kg',
      detalle:
          'Muy inteligente y activo. Necesita retos mentales, ejercicio y rutinas con propósito.',
      imageUrl: 'https://loremflickr.com/900/600/bordercollie,dog/all',
    ),
    _BreedData(
      nombre: 'Dachshund',
      resumen: 'Pequeño · 7–14 kg',
      detalle:
          'Valiente y curioso. Conviene cuidar saltos y escaleras por su espalda larga.',
      imageUrl: 'https://loremflickr.com/900/600/dachshund,dog/all',
    ),
    _BreedData(
      nombre: 'Schnauzer',
      resumen: 'Pequeño–Mediano · 5–20 kg',
      detalle:
          'Activo, alerta y familiar. Requiere cepillado, paseos constantes y buena socialización.',
      imageUrl: 'https://loremflickr.com/900/600/schnauzer,dog/all',
    ),
    _BreedData(
      nombre: 'Criollo / Mestizo',
      resumen: 'Variable · Personalidad única',
      detalle:
          'Suelen ser adaptables y resistentes. Lo importante es conocer energía, salud y carácter.',
      imageUrl: 'https://loremflickr.com/900/600/mixedbreed,dog/all',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  @override
  void dispose() {
    _notificacionesTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarSesion() async {
    final nombre = await SessionService.obtenerNombre();
    final rolRaw = await SessionService.obtenerRol();
    final baseUrl = await StorageService.obtenerBaseUrl();
    final rol = _rolBonito(rolRaw);

    if (!mounted) return;

    setState(() {
      _nombre =
          nombre != null && nombre.trim().isNotEmpty ? nombre.trim() : 'Usuario';
      _rol = rol;
      _baseUrl = baseUrl;
      _cargando = false;
    });

    if (_esDuenioValor(rol) || _esAdminValor(rol)) {
      await _cargarPerros();
    }

    await _cargarPaseos();

    await _cargarNotificacionesHome(silencioso: true);
    _iniciarPollingNotificaciones();
  }

  Future<void> _refrescarTodo() async {
    await _cargarSesion();
  }

  Future<void> _cargarPerros() async {
    if (!mounted) return;

    setState(() {
      _cargandoPerros = true;
      _errorPerros = null;
    });

    try {
      final result = await PerrosService.obtenerMisPerros();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _perros = _normalizarLista(result['data']);
          _cargandoPerros = false;
        });
      } else {
        setState(() {
          _errorPerros =
              result['message']?.toString() ?? 'No se pudieron cargar perros.';
          _cargandoPerros = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorPerros = e.toString().replaceFirst('Exception: ', '');
        _cargandoPerros = false;
      });
    }
  }

  Future<void> _cargarPaseos() async {
    if (!mounted) return;

    setState(() {
      _cargandoPaseos = true;
      _errorPaseos = null;
    });

    try {
      final result = await PaseosService.obtenerMisPaseos();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _paseos = _normalizarLista(result['data']);
          _cargandoPaseos = false;
        });
      } else {
        setState(() {
          _errorPaseos =
              result['message']?.toString() ?? 'No se pudieron cargar paseos.';
          _cargandoPaseos = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorPaseos = e.toString().replaceFirst('Exception: ', '');
        _cargandoPaseos = false;
      });
    }
  }

  List<dynamic> _normalizarLista(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      final posible = data['items'] ??
          data['paseos'] ??
          data['perros'] ??
          data['data'] ??
          data['result'] ??
          data['resultado'];

      if (posible is List) return posible;
    }

    return [];
  }

  String _rolBonito(String? rol) {
    final value = rol?.trim().toLowerCase() ?? '';

    if (value == 'duenio' || value == 'dueño' || value == 'dueno') {
      return 'Dueño';
    }

    if (value == 'cliente') return 'Dueño';
    if (value == 'paseador') return 'Paseador';
    if (value == 'admin' || value == 'administrador') return 'Admin';

    return rol?.trim().isNotEmpty == true ? rol!.trim() : 'Usuario';
  }

  bool _esDuenioValor(String rol) {
    final value = rol.toLowerCase();

    return value == 'dueño' ||
        value == 'duenio' ||
        value == 'dueno' ||
        value == 'cliente';
  }

  bool _esAdminValor(String rol) {
    final value = rol.toLowerCase();

    return value == 'admin' || value == 'administrador';
  }

  bool get _esDuenio => _esDuenioValor(_rol);

  bool get _esPaseador => _rol.toLowerCase() == 'paseador';

  bool get _esAdmin => _esAdminValor(_rol);

  Future<void> _abrir(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) {
      await _cargarSesion();
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DogGoTheme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Cerrar sesión',
            style: DogGoTheme.title(size: 22),
          ),
          content: Text(
            '¿Seguro que quieres salir de tu cuenta?',
            style: DogGoTheme.subtitle(size: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: DogGoTheme.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await SessionService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _abrirUrl(String urlTexto) async {
    final url = Uri.parse(urlTexto);

    final ok = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace.'),
        ),
      );
    }
  }

  Future<void> _abrirLugarReal(String busqueda) async {
    String query = busqueda;

    try {
      var permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso != LocationPermission.denied &&
          permiso != LocationPermission.deniedForever) {
        final posicion = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        query = '$busqueda cerca de ${posicion.latitude},${posicion.longitude}';
      }
    } catch (_) {
      query = '$busqueda cerca de mí';
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    final ok = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el mapa.'),
        ),
      );
    }
  }

  Map<String, dynamic> _mapaSeguro(dynamic valor) {
    if (valor is Map<String, dynamic>) return valor;
    if (valor is Map) return Map<String, dynamic>.from(valor);

    return {};
  }

  dynamic _valorMapa(Map<String, dynamic> mapa, List<String> keys) {
    for (final key in keys) {
      if (mapa.containsKey(key) && mapa[key] != null) {
        return mapa[key];
      }
    }

    return null;
  }

  String _textoSeguro(dynamic valor, [String fallback = 'Sin dato']) {
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

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _nombrePerro(Map<String, dynamic> perro) {
    return _textoSeguro(
      _valorMapa(
        perro,
        [
          'nombre',
          'Nombre',
          'nombrePerro',
          'NombrePerro',
        ],
      ),
      'Perro',
    );
  }

  String _razaPerro(Map<String, dynamic> perro) {
    return _textoSeguro(
      _valorMapa(perro, ['raza', 'Raza']),
      'Sin raza',
    );
  }

  String _edadPerro(Map<String, dynamic> perro) {
    final edad = _valorMapa(perro, ['edad', 'Edad']);

    if (edad == null) return 'Sin edad';

    final texto = edad.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return 'Sin edad';
    if (texto == '1') return '1 año';
    if (texto.toLowerCase().contains('año')) return texto;

    return '$texto años';
  }

  String _tamanoPerro(Map<String, dynamic> perro) {
    return _textoSeguro(
      _valorMapa(
        perro,
        [
          'tamano',
          'Tamano',
          'tamanio',
          'Tamanio',
          'tamaño',
          'Tamaño',
        ],
      ),
      'Sin tamaño',
    );
  }

  String _notasPerro(Map<String, dynamic> perro) {
    return _textoSeguro(
      _valorMapa(
        perro,
        [
          'notas',
          'Notas',
          'nota',
          'Nota',
          'descripcion',
          'Descripcion',
        ],
      ),
      'Sin notas especiales',
    );
  }

  String _fotoPerro(Map<String, dynamic> perro) {
    final raw = _textoSeguro(
      _valorMapa(
        perro,
        [
          'fotoUrl',
          'FotoUrl',
          'foto',
          'Foto',
          'urlFoto',
          'UrlFoto',
          'imagenUrl',
          'ImagenUrl',
          'imagen',
          'Imagen',
          'fotoPerroUrl',
          'FotoPerroUrl',
        ],
      ),
      '',
    );

    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return '';

    if (raw.startsWith('/')) return '$base$raw';

    return '$base/$raw';
  }

  DateTime? _fechaPaseo(Map<String, dynamic> paseo) {
    final valor = _valorMapa(
      paseo,
      [
        'fechaProgramada',
        'FechaProgramada',
        'fechaInicio',
        'FechaInicio',
        'fecha',
        'Fecha',
        'createdAt',
        'CreatedAt',
      ],
    );

    if (valor == null) return null;
    if (valor is DateTime) return valor;

    return DateTime.tryParse(valor.toString());
  }

  String _estadoPaseo(Map<String, dynamic> paseo) {
    return _textoSeguro(
      _valorMapa(paseo, ['estado', 'Estado', 'status', 'Status']),
      'Sin estado',
    );
  }

  String _perroPaseo(Map<String, dynamic> paseo) {
    final directo = _valorMapa(
      paseo,
      [
        'perroNombre',
        'PerroNombre',
        'nombrePerro',
        'NombrePerro',
      ],
    );

    if (directo != null) return _textoSeguro(directo, 'Paseo DogGo');

    final perro = _valorMapa(paseo, ['perro', 'Perro']);

    if (perro is Map) {
      return _textoSeguro(
        perro['nombre'] ?? perro['Nombre'],
        'Paseo DogGo',
      );
    }

    return 'Paseo DogGo';
  }

  String _paseadorPaseo(Map<String, dynamic> paseo) {
    final directo = _valorMapa(
      paseo,
      [
        'paseadorNombre',
        'PaseadorNombre',
        'nombrePaseador',
        'NombrePaseador',
      ],
    );

    if (directo != null) {
      return _textoSeguro(directo, _esPaseador ? 'Dueño' : 'Paseador');
    }

    final paseador = _valorMapa(paseo, ['paseador', 'Paseador']);

    if (paseador is Map) {
      final usuario = paseador['usuario'] ?? paseador['Usuario'];

      if (usuario is Map) {
        final nombre = '${usuario['nombre'] ?? usuario['Nombre'] ?? ''} '
                '${usuario['apellido'] ?? usuario['Apellido'] ?? ''}'
            .trim();

        if (nombre.isNotEmpty) return nombre;
      }

      return _textoSeguro(
        paseador['nombre'] ?? paseador['Nombre'],
        _esPaseador ? 'Dueño' : 'Paseador',
      );
    }

    return _esPaseador ? 'Dueño' : 'Paseador';
  }

  String _horaPaseo(Map<String, dynamic> paseo) {
    final fecha = _fechaPaseo(paseo);

    if (fecha == null) return '--:--';

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String _diaMesTexto(DateTime fecha) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${fecha.day} de ${meses[fecha.month - 1]}';
  }

  String _mesTexto(DateTime fecha) {
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  bool _mismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Map<String, dynamic>> _paseosDeDia(DateTime dia) {
    final lista = <Map<String, dynamic>>[];

    for (final item in _paseos) {
      final paseo = _mapaSeguro(item);
      final fecha = _fechaPaseo(paseo);

      if (fecha != null && _mismoDia(fecha, dia)) {
        lista.add(paseo);
      }
    }

    lista.sort((a, b) {
      final fa = _fechaPaseo(a);
      final fb = _fechaPaseo(b);

      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;

      return fa.compareTo(fb);
    });

    return lista;
  }

  List<Map<String, dynamic>> _proximosPaseos() {
    final ahora = DateTime.now();

    final lista = _paseos.map(_mapaSeguro).where((paseo) {
      final fecha = _fechaPaseo(paseo);
      final estado = _estadoPaseo(paseo).toLowerCase();

      if (fecha == null) return false;

      final noFinalizado = !estado.contains('finalizado') &&
          !estado.contains('cancelado') &&
          !estado.contains('rechazado');

      return noFinalizado &&
          fecha.isAfter(ahora.subtract(const Duration(hours: 4)));
    }).toList();

    lista.sort((a, b) {
      final fa = _fechaPaseo(a);
      final fb = _fechaPaseo(b);

      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;

      return fa.compareTo(fb);
    });

    return lista.take(3).toList();
  }

  Color _colorEstado(String estado) {
    final e = estado.toLowerCase();

    if (e.contains('curso')) return DogGoTheme.green;
    if (e.contains('finalizado')) return DogGoTheme.teal;
    if (e.contains('cancelado') || e.contains('rechazado')) {
      return DogGoTheme.red;
    }
    if (e.contains('pendiente')) return DogGoTheme.orange;

    return DogGoTheme.teal;
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mesCalendario = DateTime(
        _mesCalendario.year,
        _mesCalendario.month + delta,
      );
    });
  }

  Future<void> _scrollTo(GlobalKey key, int index) async {
    setState(() {
      _navIndex = index;
    });

    final contextKey = key.currentContext;

    if (contextKey == null) return;

    await Scrollable.ensureVisible(
      contextKey,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      alignment: .04,
    );
  }
  void _iniciarPollingNotificaciones() {
    _notificacionesTimer?.cancel();

    _notificacionesTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) {
        if (!mounted) return;
        _cargarNotificacionesHome();
      },
    );
  }

  Future<void> _cargarNotificacionesHome({bool silencioso = false}) async {
    if (_revisandoNotificaciones) return;

    _revisandoNotificaciones = true;

    try {
      final lista = await _notificacionesService.obtenerNotificaciones();

      lista.sort((a, b) {
        final fechaA = DateTime.tryParse(
              _fechaNotificacion(a)?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final fechaB = DateTime.tryParse(
              _fechaNotificacion(b)?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return fechaB.compareTo(fechaA);
      });

      final noLeidas = lista.where((item) => !_notificacionLeida(item)).toList();

      if (!mounted) return;

      setState(() {
        _notificacionesNoLeidas = noLeidas.length;
      });

      if (noLeidas.isEmpty) return;

      final nueva = noLeidas.first;
      final nuevaId = _idNotificacion(nueva);

      if (silencioso) {
        _ultimaNotificacionMostradaId = nuevaId;
        return;
      }

      if (nuevaId != null && nuevaId == _ultimaNotificacionMostradaId) return;

      _ultimaNotificacionMostradaId = nuevaId;
      _mostrarAvisoNotificacion(nueva);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _notificacionesNoLeidas = 0;
      });
    } finally {
      _revisandoNotificaciones = false;
    }
  }

  void _mostrarAvisoNotificacion(Map<String, dynamic> notificacion) {
    if (!mounted) return;

    final titulo = _tituloNotificacion(notificacion);
    final mensaje = _mensajeNotificacion(notificacion);

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
        backgroundColor: DogGoTheme.ink,
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: DogGoTheme.teal.withOpacity(.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: DogGoTheme.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mensaje,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.82),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Abrir',
          textColor: DogGoTheme.tealLight,
          onPressed: () => _abrirNotificacionDesdeHome(notificacion),
        ),
      ),
    );
  }

  Future<void> _abrirNotificacionDesdeHome(
    Map<String, dynamic> notificacion,
  ) async {
    final id = _idNotificacion(notificacion);
    final tipo = _tipoNotificacion(notificacion).toLowerCase();
    final referenciaId = _referenciaNotificacion(notificacion);

    try {
      if (id != null && !_notificacionLeida(notificacion)) {
        await _notificacionesService.marcarComoLeida(id);
      }
    } catch (_) {}

    if (!mounted) return;

    if ((tipo.contains('chat') || tipo.contains('mensaje')) &&
        referenciaId != null &&
        referenciaId > 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPaseoScreen(
            paseoId: referenciaId,
            nombrePerro: _nombrePerroNotificacion(notificacion),
            nombreOtroUsuario: _otroUsuarioNotificacion(notificacion),
          ),
        ),
      );
    } else {
      await _abrir(const MisPaseosScreen());
    }

    if (mounted) {
      await _cargarNotificacionesHome(silencioso: true);
    }
  }

  Future<void> _abrirNotificacionesHome() async {
    await _abrir(const NotificacionesScreen());

    if (mounted) {
      await _cargarNotificacionesHome(silencioso: true);
    }
  }

  int? _idNotificacion(Map<String, dynamic> item) {
    final valor = item['id'] ??
        item['Id'] ??
        item['notificacionId'] ??
        item['NotificacionId'];

    if (valor is int) return valor;
    if (valor is num) return valor.toInt();

    return int.tryParse(valor?.toString() ?? '');
  }

  int? _referenciaNotificacion(Map<String, dynamic> item) {
    final valor = item['referenciaId'] ??
        item['ReferenciaId'] ??
        item['paseoId'] ??
        item['PaseoId'] ??
        item['idReferencia'] ??
        item['IdReferencia'];

    if (valor is int) return valor;
    if (valor is num) return valor.toInt();

    return int.tryParse(valor?.toString() ?? '');
  }

  dynamic _fechaNotificacion(Map<String, dynamic> item) {
    return item['fecha'] ??
        item['Fecha'] ??
        item['fechaCreacion'] ??
        item['FechaCreacion'] ??
        item['createdAt'] ??
        item['CreatedAt'] ??
        item['timestamp'] ??
        item['Timestamp'];
  }

  String _tituloNotificacion(Map<String, dynamic> item) {
    return _textoSeguro(
      item['titulo'] ??
          item['Titulo'] ??
          item['title'] ??
          item['Title'] ??
          item['asunto'] ??
          item['Asunto'],
      'Notificación',
    );
  }

  String _mensajeNotificacion(Map<String, dynamic> item) {
    return _textoSeguro(
      item['mensaje'] ??
          item['Mensaje'] ??
          item['descripcion'] ??
          item['Descripcion'] ??
          item['body'] ??
          item['Body'] ??
          item['texto'] ??
          item['Texto'],
      'Tienes una nueva actividad en DogGo.',
    );
  }

  String _tipoNotificacion(Map<String, dynamic> item) {
    return _textoSeguro(
      item['tipo'] ?? item['Tipo'] ?? item['type'] ?? item['Type'],
      'General',
    );
  }

  String _nombrePerroNotificacion(Map<String, dynamic> item) {
    return _textoSeguro(
      item['nombrePerro'] ??
          item['NombrePerro'] ??
          item['perroNombre'] ??
          item['PerroNombre'],
      'Paseo DogGo',
    );
  }

  String _otroUsuarioNotificacion(Map<String, dynamic> item) {
    return _textoSeguro(
      item['nombreUsuario'] ??
          item['NombreUsuario'] ??
          item['otroUsuario'] ??
          item['OtroUsuario'] ??
          item['emisorNombre'] ??
          item['EmisorNombre'] ??
          item['remitente'] ??
          item['Remitente'],
      'Usuario',
    );
  }

  bool _notificacionLeida(Map<String, dynamic> item) {
    final valor = item['leida'] ??
        item['Leida'] ??
        item['vista'] ??
        item['Vista'] ??
        item['read'] ??
        item['Read'] ??
        item['isRead'] ??
        item['IsRead'];

    if (valor is bool) return valor;

    final texto = valor?.toString().toLowerCase();

    return texto == 'true' || texto == '1' || texto == 'sí' || texto == 'si';
  }

  void _mostrarPaseosDia(DateTime dia) {
    final paseos = _paseosDeDia(dia);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .78,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: DogGoTheme.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _diaMesTexto(dia),
                    style: DogGoTheme.title(size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paseos.isEmpty
                        ? 'No tienes paseos registrados este día.'
                        : '${paseos.length} paseo(s) registrado(s).',
                    textAlign: TextAlign.center,
                    style: DogGoTheme.subtitle(size: 14),
                  ),
                  const SizedBox(height: 18),
                  if (paseos.isEmpty)
                    _EmptyDayCard(
                      onTap: () {
                        Navigator.pop(context);
                        if (_esPaseador) {
                          _abrir(const MisPaseosScreen());
                        } else {
                          _abrir(const PaseadoresScreen());
                        }
                      },
                    )
                  else
                    Column(
                      children: paseos
                          .map(
                            (paseo) => _PaseoAgendaTile(
                              hora: _horaPaseo(paseo),
                              titulo: _perroPaseo(paseo),
                              subtitulo: _paseadorPaseo(paseo),
                              estado: _estadoPaseo(paseo),
                              color: _colorEstado(_estadoPaseo(paseo)),
                              onTap: () {
                                Navigator.pop(context);
                                _abrir(const MisPaseosScreen());
                              },
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _abrir(const MisPaseosScreen());
                      },
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Ver mis paseos'),
                      style: DogGoTheme.primaryButton(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarConsejo(_TipData item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .82,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: DogGoTheme.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _IconTile(
                    icon: item.icon,
                    color: DogGoTheme.teal,
                    background: DogGoTheme.tealLight,
                    size: 76,
                    iconSize: 38,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.categoria.toUpperCase(),
                    style: DogGoTheme.label(size: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.titulo,
                    textAlign: TextAlign.center,
                    style: DogGoTheme.title(size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.descripcion,
                    textAlign: TextAlign.center,
                    style: DogGoTheme.subtitle(size: 15),
                  ),
                  const SizedBox(height: 18),
                  _AdviceBox(
                    title: 'Puntos importantes',
                    children: item.puntos
                        .map((punto) => _AdviceBullet(text: punto))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _RecommendationBox(text: item.recomendacion),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: DogGoTheme.primaryButton(),
                      child: const Text('Entendido'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarRaza(_BreedData raza) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .80,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: DogGoTheme.softShadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            raza.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const _DogImagePlaceholder();
                            },
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(.38),
                                  Colors.black.withOpacity(.05),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          bottom: 18,
                          right: 18,
                          child: Text(
                            raza.nombre,
                            style: DogGoTheme.title(
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      children: [
                        Text(
                          raza.resumen,
                          textAlign: TextAlign.center,
                          style: DogGoTheme.body(
                            size: 14,
                            color: DogGoTheme.teal,
                            weight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          raza.detalle,
                          textAlign: TextAlign.center,
                          style: DogGoTheme.subtitle(size: 15),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: DogGoTheme.primaryButton(),
                            child: const Text('Cerrar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(26),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: DogGoTheme.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                _MenuRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  onTap: () {
                    Navigator.pop(context);
                    _abrirNotificacionesHome();
                  },
                ),
                _MenuRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Mi perfil',
                  onTap: () {
                    Navigator.pop(context);
                    _abrir(const PerfilScreen());
                  },
                ),
                _MenuRow(
                  icon: Icons.route_rounded,
                  title: 'Mis paseos',
                  onTap: () {
                    Navigator.pop(context);
                    _abrir(const MisPaseosScreen());
                  },
                ),
                if (_esDuenio || _esAdmin)
                  _MenuRow(
                    icon: Icons.pets_rounded,
                    title: 'Mis perros',
                    onTap: () {
                      Navigator.pop(context);
                      _abrir(const MisPerrosScreen());
                    },
                  ),
                const Divider(height: 18),
                _MenuRow(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar sesión',
                  danger: true,
                  onTap: () {
                    Navigator.pop(context);
                    _cerrarSesion();
                  },
                ),
              ],
            ),
          ),
        );
      },
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

    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      extendBody: false,
      bottomNavigationBar: _buildBottomNavigation(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refrescarTodo,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: DogGoTheme.cream2,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                toolbarHeight: 78,
                titleSpacing: 0,
                title: _buildTopBar(),
              ),

              if (_navIndex == 0) ...[
                SliverToBoxAdapter(
                  child: _AnimatedHomeSection(
                    delay: const Duration(milliseconds: 40),
                    child: KeyedSubtree(
                      key: _inicioKey,
                      child: Column(
                        children: [
                          _buildHero(),
                          _buildMainActions(),
                          _buildOperacionHoy(),
                          _buildResumen(),
                          _buildHomeOverview(),
                          _buildGuiasIntro(),
                          _buildConsejos(),
                          _buildProductos(),
                          _buildLugares(),
                          _buildCuriosidades(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              if (_navIndex == 1) ...[
                SliverToBoxAdapter(
                  child: _AnimatedHomeSection(
                    delay: const Duration(milliseconds: 40),
                    child: KeyedSubtree(
                      key: _agendaKey,
                      child: _buildAgendaTab(),
                    ),
                  ),
                ),
              ],

              if (_navIndex == 2) ...[
                SliverToBoxAdapter(
                  child: _AnimatedHomeSection(
                    delay: const Duration(milliseconds: 40),
                    child: KeyedSubtree(
                      key: _mascotasKey,
                      child: _buildPanelTab(),
                    ),
                  ),
                ),
              ],

              if (_navIndex == 3) ...[
                SliverToBoxAdapter(
                  child: _AnimatedHomeSection(
                    delay: const Duration(milliseconds: 40),
                    child: KeyedSubtree(
                      key: _esPaseador ? _guiasKey : _mascotasKey,
                      child: _esPaseador
                          ? Column(
                              children: [
                                _buildGuiasIntro(),
                                _buildConsejos(),
                                _buildProductos(),
                                _buildLugares(),
                                _buildCuriosidades(),
                              ],
                            )
                          : _buildMascotasTab(),
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: DogGoTheme.border.withOpacity(.85),
              ),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.tealLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    'AGENDA DOGGO',
                    style: DogGoTheme.label(size: 11),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Agenda y seguimiento de paseos',
                  style: DogGoTheme.title(size: 27),
                ),
                const SizedBox(height: 10),
                Text(
                  'Aquí ves únicamente tu calendario, próximos paseos y estados. Ya no se mezcla con el inicio.',
                  style: DogGoTheme.subtitle(size: 14.5),
                ),
              ],
            ),
          ),
        ),
        _buildCalendarioPaseos(),
        if (!_esPaseador) _buildPaseosOwnerPanel(),
      ],
    );
  }

  Widget _buildPanelTab() {
    if (_esPaseador) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: DogGoTheme.card,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: DogGoTheme.border.withOpacity(.85),
                ),
                boxShadow: DogGoTheme.softShadow(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: DogGoTheme.orangeLight,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      'PANEL DE PASEADOR',
                      style: DogGoTheme.body(
                        size: 11,
                        color: DogGoTheme.orange,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Panel operativo',
                    style: DogGoTheme.title(size: 27),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Accesos directos para revisar paseos asignados y actualizar tu perfil profesional.',
                    style: DogGoTheme.subtitle(size: 14.5),
                  ),
                ],
              ),
            ),
          ),
          _buildPaseadorPreview(),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: DogGoTheme.border.withOpacity(.85),
              ),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.tealLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    'PASEOS DOGGO',
                    style: DogGoTheme.label(size: 11),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tus paseos',
                  style: DogGoTheme.title(size: 27),
                ),
                const SizedBox(height: 10),
                Text(
                  'Desde aquí puedes solicitar un paseo, ver próximos servicios y abrir tu historial.',
                  style: DogGoTheme.subtitle(size: 14.5),
                ),
              ],
            ),
          ),
        ),
        _buildPaseosOwnerPanel(),
      ],
    );
  }

  Widget _buildMascotasTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: DogGoTheme.border.withOpacity(.85),
              ),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.orangeLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    'MASCOTAS',
                    style: DogGoTheme.body(
                      size: 11,
                      color: DogGoTheme.orange,
                      weight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Perfil rápido de tus mascotas',
                  style: DogGoTheme.title(size: 27),
                ),
                const SizedBox(height: 10),
                Text(
                  'Consulta fotos, edad, raza, tamaño y notas importantes de tus perros registrados.',
                  style: DogGoTheme.subtitle(size: 14.5),
                ),
              ],
            ),
          ),
        ),
        _buildMascotasPreview(),
      ],
    );
  }

  Widget _buildPaseosOwnerPanel() {
    final proximos = _proximosPaseos();
    final activos = _paseos.map(_mapaSeguro).where((paseo) {
      return _estadoPaseo(paseo).toLowerCase().contains('curso');
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: DogGoTheme.border.withOpacity(.85)),
          boxShadow: DogGoTheme.softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitleRow(
              title: 'Solicitar y revisar paseos',
              actionText: 'Historial',
              onAction: () => _abrir(const MisPaseosScreen()),
            ),
            const SizedBox(height: 8),
            Text(
              'Botón directo para pedir paseo y tarjetas con tus próximos movimientos.',
              style: DogGoTheme.subtitle(size: 14),
            ),
            const SizedBox(height: 16),
            _OwnerActionRow(
              icon: Icons.add_location_alt_rounded,
              title: 'Solicitar paseo',
              subtitle: 'Busca un paseador disponible para tu perro.',
              color: DogGoTheme.teal,
              highlight: true,
              onTap: () => _abrir(const PaseadoresScreen()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricMiniCard(
                    number: '${activos.length}',
                    label: 'En curso',
                    color: DogGoTheme.green,
                    icon: Icons.play_circle_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricMiniCard(
                    number: '${_paseos.length}',
                    label: 'Total',
                    color: DogGoTheme.teal,
                    icon: Icons.route_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Próximos o activos',
              style: DogGoTheme.title(size: 20),
            ),
            const SizedBox(height: 10),
            if (_cargandoPaseos)
              const Center(child: CircularProgressIndicator())
            else if (_errorPaseos != null)
              _CalendarErrorCard(
                mensaje: _errorPaseos!,
                onRetry: _cargarPaseos,
              )
            else if (activos.isEmpty && proximos.isEmpty)
              _NoUpcomingWalksCard(
                onTap: () => _abrir(const PaseadoresScreen()),
              )
            else
              Column(
                children: [
                  ...activos.map(
                    (paseo) => _PaseoAgendaTile(
                      hora: _horaPaseo(paseo),
                      titulo: _perroPaseo(paseo),
                      subtitulo: _paseadorPaseo(paseo),
                      estado: _estadoPaseo(paseo),
                      color: _colorEstado(_estadoPaseo(paseo)),
                      onTap: () => _abrir(const MisPaseosScreen()),
                    ),
                  ),
                  ...proximos.map(
                    (paseo) => _PaseoAgendaTile(
                      hora: _horaPaseo(paseo),
                      titulo: _perroPaseo(paseo),
                      subtitulo: _paseadorPaseo(paseo),
                      estado: _estadoPaseo(paseo),
                      color: _colorEstado(_estadoPaseo(paseo)),
                      onTap: () => _abrir(const MisPaseosScreen()),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeOverview() {
    final proximos = _proximosPaseos();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_esDuenio || _esAdmin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DogGoTheme.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: DogGoTheme.border.withOpacity(.85),
                ),
                boxShadow: DogGoTheme.softShadow(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _IconTile(
                        icon: Icons.home_repair_service_rounded,
                        color: DogGoTheme.teal,
                        background: DogGoTheme.tealLight,
                        size: 58,
                        iconSize: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Centro rápido del dueño',
                              style: DogGoTheme.title(size: 23),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Solicita paseos, revisa mascotas y consulta tu actividad reciente.',
                              style: DogGoTheme.subtitle(size: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _OwnerActionRow(
                    icon: Icons.add_location_alt_rounded,
                    title: 'Solicitar paseo',
                    subtitle: 'Busca un paseador disponible y agenda una salida.',
                    color: DogGoTheme.teal,
                    highlight: true,
                    onTap: () => _abrir(const PaseadoresScreen()),
                  ),
                  const SizedBox(height: 10),
                  _OwnerActionRow(
                    icon: Icons.pets_rounded,
                    title: 'Mis mascotas',
                    subtitle: 'Revisa fotos, edad, raza, tamaño y notas.',
                    color: DogGoTheme.orange,
                    onTap: () => _abrir(const MisPerrosScreen()),
                  ),
                  const SizedBox(height: 10),
                  _OwnerActionRow(
                    icon: Icons.calendar_month_rounded,
                    title: 'Agenda de paseos',
                    subtitle: 'Consulta próximos paseos, estados y horarios.',
                    color: DogGoTheme.purple,
                    onTap: () => setState(() => _navIndex = 1),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DogGoTheme.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: DogGoTheme.border.withOpacity(.85),
                ),
                boxShadow: DogGoTheme.softShadow(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _IconTile(
                        icon: Icons.workspace_premium_rounded,
                        color: DogGoTheme.teal,
                        background: DogGoTheme.tealLight,
                        size: 58,
                        iconSize: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Centro del paseador',
                              style: DogGoTheme.title(size: 23),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Accede a tus paseos, agenda y perfil profesional.',
                              style: DogGoTheme.subtitle(size: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _OwnerActionRow(
                    icon: Icons.route_rounded,
                    title: 'Paseos asignados',
                    subtitle: 'Acepta, inicia, finaliza y revisa tus servicios.',
                    color: DogGoTheme.teal,
                    highlight: true,
                    onTap: () => _abrir(const MisPaseosScreen()),
                  ),
                  const SizedBox(height: 10),
                  _OwnerActionRow(
                    icon: Icons.person_rounded,
                    title: 'Mi perfil profesional',
                    subtitle: 'Actualiza foto, zona, experiencia y contacto.',
                    color: DogGoTheme.purple,
                    onTap: () => _abrir(const PerfilScreen()),
                  ),
                  const SizedBox(height: 10),
                  _OwnerActionRow(
                    icon: Icons.calendar_month_rounded,
                    title: 'Ver agenda',
                    subtitle: 'Consulta calendario y próximos paseos.',
                    color: DogGoTheme.orange,
                    onTap: () => setState(() => _navIndex = 1),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DogGoTheme.cream2,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: DogGoTheme.border.withOpacity(.85)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.035),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vista rápida',
                  style: DogGoTheme.title(size: 22),
                ),
                const SizedBox(height: 7),
                Text(
                  proximos.isEmpty
                      ? _esPaseador
                          ? 'Todavía no tienes paseos próximos asignados.'
                          : 'Todavía no hay paseos próximos. Puedes solicitar uno desde aquí.'
                      : 'Estos son tus próximos movimientos en DogGo.',
                  style: DogGoTheme.subtitle(size: 13.5),
                ),
                const SizedBox(height: 14),
                if (proximos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DogGoTheme.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: DogGoTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: DogGoTheme.tealLight,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                _esPaseador
                                    ? Icons.event_available_rounded
                                    : Icons.add_location_alt_rounded,
                                color: DogGoTheme.teal,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _esPaseador
                                    ? 'Revisa tus paseos asignados cuando tengas nuevos servicios.'
                                    : 'Solicita un paseo para que aparezca aquí tu próximo servicio.',
                                style: DogGoTheme.body(
                                  size: 13.5,
                                  color: DogGoTheme.ink,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _esPaseador
                                ? _abrir(const MisPaseosScreen())
                                : _abrir(const PaseadoresScreen()),
                            icon: Icon(
                              _esPaseador
                                  ? Icons.route_rounded
                                  : Icons.add_location_alt_rounded,
                            ),
                            label: Text(
                              _esPaseador
                                  ? 'Ver paseos asignados'
                                  : 'Solicitar paseo',
                            ),
                            style: DogGoTheme.primaryButton(),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: proximos
                        .map(
                          (paseo) => _PaseoAgendaTile(
                            hora: _horaPaseo(paseo),
                            titulo: _perroPaseo(paseo),
                            subtitulo: _paseadorPaseo(paseo),
                            estado: _estadoPaseo(paseo),
                            color: _colorEstado(_estadoPaseo(paseo)),
                            onTap: () => _abrir(const MisPaseosScreen()),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitarPaseoPrincipal() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _abrir(const PaseadoresScreen()),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: DogGoTheme.teal.withOpacity(.18),
              ),
              boxShadow: DogGoTheme.softShadow(),
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: DogGoTheme.teal,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: DogGoTheme.teal.withOpacity(.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_location_alt_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solicitar paseo',
                        style: DogGoTheme.title(size: 23),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Encuentra paseadores disponibles y agenda una salida para tu perro.',
                        style: DogGoTheme.subtitle(size: 13.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: DogGoTheme.tealLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: DogGoTheme.teal,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2.withOpacity(.96),
        border: Border(
          bottom: BorderSide(
            color: DogGoTheme.border.withOpacity(.8),
          ),
        ),
      ),
      child: Row(
        children: [
          const DogGoLogo(size: 46),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: _esPaseador
                  ? DogGoTheme.purple.withOpacity(.12)
                  : DogGoTheme.tealLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _esPaseador
                    ? DogGoTheme.purple.withOpacity(.18)
                    : DogGoTheme.teal.withOpacity(.16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _esPaseador
                      ? Icons.directions_walk_rounded
                      : Icons.pets_rounded,
                  size: 15,
                  color: _esPaseador ? DogGoTheme.purple : DogGoTheme.teal,
                ),
                const SizedBox(width: 5),
                Text(
                  _rol,
                  style: DogGoTheme.body(
                    size: 11.5,
                    color: _esPaseador ? DogGoTheme.purple : DogGoTheme.teal,
                    weight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _TopBarButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: _notificacionesNoLeidas,
            onTap: _abrirNotificacionesHome,
          ),
          const SizedBox(width: 10),
          _TopBarButton(
            icon: Icons.menu_rounded,
            onTap: _mostrarMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final titulo = _esPaseador
        ? '¿Listo para tus paseos de hoy?'
        : '¿Cómo están tus peludos hoy?';

    final subtitulo = _esPaseador
        ? 'Revisa tus paseos asignados, agenda y seguimiento desde un solo lugar.'
        : 'Agenda paseos, revisa tu calendario y mantén a tus mascotas al día.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: DogGoTheme.border.withOpacity(.88),
          ),
          boxShadow: DogGoTheme.softShadow(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: -14,
              child: Transform.rotate(
                angle: -.22,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: DogGoTheme.tealLight.withOpacity(.85),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Icon(
                    _esPaseador
                        ? Icons.directions_walk_rounded
                        : Icons.pets_rounded,
                    color: DogGoTheme.teal.withOpacity(.72),
                    size: 58,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.tealLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    'BIENVENIDO DE VUELTA',
                    style: DogGoTheme.label(size: 11),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(right: 64),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hola, ',
                          style: DogGoTheme.title(size: 34),
                        ),
                        TextSpan(
                          text: '$_nombre.\n',
                          style: DogGoTheme.title(
                            size: 34,
                            color: DogGoTheme.teal,
                          ),
                        ),
                        TextSpan(
                          text: titulo,
                          style: DogGoTheme.title(size: 32),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subtitulo,
                  style: DogGoTheme.subtitle(size: 16),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusPill(
                      icon: _esPaseador
                          ? Icons.directions_walk_rounded
                          : Icons.pets_rounded,
                      text: _rol,
                      color: DogGoTheme.teal,
                    ),
                    const _StatusPill(
                      icon: Icons.check_circle_rounded,
                      text: 'DogGo activo',
                      color: DogGoTheme.green,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickHomeAction(
              icon: _esPaseador ? Icons.route_rounded : Icons.search_rounded,
              title: _esPaseador ? 'Mis paseos' : 'Buscar',
              subtitle: _esPaseador ? 'Asignados' : 'Paseador',
              color: DogGoTheme.teal,
              onTap: () => _esPaseador
                  ? _abrir(const MisPaseosScreen())
                  : _abrir(const PaseadoresScreen()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickHomeAction(
              icon: Icons.calendar_month_rounded,
              title: 'Agenda',
              subtitle: 'Calendario',
              color: DogGoTheme.orange,
              onTap: () => _scrollTo(_agendaKey, 1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickHomeAction(
              icon: Icons.person_rounded,
              title: 'Perfil',
              subtitle: 'Cuenta',
              color: DogGoTheme.purple,
              onTap: () => _abrir(const PerfilScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperacionHoy() {
    final titulo = _esPaseador ? 'Operación de hoy' : 'Panel rápido de cuidado';
    final descripcion = _esPaseador
        ? 'Ten a la mano tus paseos, horarios y acciones principales para operar sin perder tiempo.'
        : 'Agenda un nuevo paseo o revisa el calendario para mantener la rutina de tus mascotas.';
    final accionPrincipal = _esPaseador ? 'Ver paseos' : 'Agendar paseo';
    final iconoPrincipal =
        _esPaseador ? Icons.route_rounded : Icons.add_location_alt_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DogGoTheme.teal,
          borderRadius: BorderRadius.circular(30),
          boxShadow: DogGoTheme.softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: DogGoTheme.title(
                          size: 21,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _esPaseador
                            ? '${_proximosPaseos().length} próximo(s) en agenda'
                            : '${_perros.length} mascota(s) registrada(s)',
                        style: DogGoTheme.body(
                          size: 12.5,
                          color: Colors.white.withOpacity(.82),
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              descripcion,
              style: DogGoTheme.body(
                size: 14,
                color: Colors.white.withOpacity(.9),
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _esPaseador
                          ? _abrir(const MisPaseosScreen())
                          : _abrir(const PaseadoresScreen()),
                      icon: Icon(iconoPrincipal, size: 18),
                      label: Text(accionPrincipal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: DogGoTheme.teal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _scrollTo(_agendaKey, 1),
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text('Agenda'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(.82),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return _DogGoBottomNav(
      currentIndex: _navIndex,
      thirdLabel: _esPaseador ? 'Panel' : 'Paseadores',
      thirdIcon: _esPaseador
          ? Icons.dashboard_customize_rounded
          : Icons.search_rounded,
      fourthLabel: _esPaseador ? 'Mi perfil' : 'Mascotas',
      fourthIcon: _esPaseador
          ? Icons.person_rounded
          : Icons.pets_rounded,
      onInicio: () => setState(() => _navIndex = 0),
      onAgenda: () => setState(() => _navIndex = 1),
      onThird: () {
        if (_esPaseador) {
          setState(() => _navIndex = 2);
        } else {
          _abrir(const PaseadoresScreen());
        }
      },
      onFourth: () {
        if (_esPaseador) {
          _abrir(const PerfilScreen());
        } else {
          setState(() => _navIndex = 3);
        }
      },
    );
  }

  Widget _buildCalendarioPaseos() {
    final proximos = _proximosPaseos();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: DogGoTheme.border.withOpacity(.85),
          ),
          boxShadow: DogGoTheme.softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitleRow(
              title: 'Calendario de paseos',
              actionText: 'Ver todos',
              onAction: () => _abrir(const MisPaseosScreen()),
            ),
            const SizedBox(height: 7),
            Text(
              'Consulta tus paseos programados, activos y terminados por día.',
              style: DogGoTheme.subtitle(size: 14),
            ),
            const SizedBox(height: 18),
            if (_cargandoPaseos)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight.withOpacity(.7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorPaseos != null)
              _CalendarErrorCard(
                mensaje: _errorPaseos!,
                onRetry: _cargarPaseos,
              )
            else ...[
              _CalendarHeader(
                mes: _mesTexto(_mesCalendario),
                onPrev: () => _cambiarMes(-1),
                onNext: () => _cambiarMes(1),
              ),
              const SizedBox(height: 14),
              _CalendarGrid(
                mes: _mesCalendario,
                paseosDelDia: _paseosDeDia,
                colorEstado: (dia) {
                  final paseos = _paseosDeDia(dia);

                  if (paseos.isEmpty) return null;

                  final tieneEnCurso = paseos.any(
                    (p) => _estadoPaseo(p).toLowerCase().contains('curso'),
                  );

                  if (tieneEnCurso) return DogGoTheme.green;

                  final tienePendiente = paseos.any(
                    (p) => _estadoPaseo(p).toLowerCase().contains('pendiente'),
                  );

                  if (tienePendiente) return DogGoTheme.orange;

                  final tieneCancelado = paseos.any(
                    (p) {
                      final estado = _estadoPaseo(p).toLowerCase();
                      return estado.contains('cancelado') ||
                          estado.contains('rechazado');
                    },
                  );

                  if (tieneCancelado) return DogGoTheme.red;

                  return DogGoTheme.teal;
                },
                onTapDia: _mostrarPaseosDia,
              ),
              const SizedBox(height: 18),
              const _CalendarLegend(),
              const SizedBox(height: 18),
              Text(
                'Próximos paseos',
                style: DogGoTheme.title(size: 20),
              ),
              const SizedBox(height: 10),
              if (proximos.isEmpty)
                _NoUpcomingWalksCard(
                  onTap: () => _esPaseador
                      ? _abrir(const MisPaseosScreen())
                      : _abrir(const PaseadoresScreen()),
                )
              else
                Column(
                  children: proximos
                      .map(
                        (paseo) => _PaseoAgendaTile(
                          hora: _horaPaseo(paseo),
                          titulo: _perroPaseo(paseo),
                          subtitulo: _paseadorPaseo(paseo),
                          estado: _estadoPaseo(paseo),
                          color: _colorEstado(_estadoPaseo(paseo)),
                          onTap: () => _abrir(const MisPaseosScreen()),
                        ),
                      )
                      .toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMascotasPreview() {
    if (!(_esDuenio || _esAdmin)) {
      return _buildPaseadorPreview();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(30),
          boxShadow: DogGoTheme.softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitleRow(
              title: 'Tus mascotas',
              actionText: '+ Añadir',
              onAction: () => _abrir(const MisPerrosScreen()),
            ),
            const SizedBox(height: 7),
            Text(
              _perros.isEmpty
                  ? 'Agrega tus perros para tener sus fotos y datos a la mano.'
                  : 'Desliza para ver la foto y datos principales de cada mascota.',
              style: DogGoTheme.subtitle(size: 14),
            ),
            const SizedBox(height: 18),
            if (_cargandoPerros)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight.withOpacity(.7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorPerros != null)
              _MascotasErrorCard(
                mensaje: _errorPerros!,
                onRetry: _cargarPerros,
              )
            else if (_perros.isEmpty)
              _MascotasEmptyCard(
                onTap: () => _abrir(const MisPerrosScreen()),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 525,
                    child: PageView.builder(
                      physics: const BouncingScrollPhysics(),
                      controller: PageController(viewportFraction: .93),
                      itemCount: _perros.length > 6 ? 6 : _perros.length,
                      itemBuilder: (context, index) {
                        final perro = _mapaSeguro(_perros[index]);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _DogPreviewLargeCard(
                            nombre: _nombrePerro(perro),
                            raza: _razaPerro(perro),
                            edad: _edadPerro(perro),
                            tamano: _tamanoPerro(perro),
                            notas: _notasPerro(perro),
                            fotoUrl: _fotoPerro(perro),
                            onTap: () => _abrir(const MisPerrosScreen()),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _abrir(const MisPerrosScreen()),
                      icon: const Icon(Icons.pets_rounded),
                      label: const Text('Ver todos mis perros'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DogGoTheme.teal,
                        side: const BorderSide(color: DogGoTheme.teal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildPaseadorPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(30),
          boxShadow: DogGoTheme.softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitleRow(
              title: 'Panel de paseador',
              actionText: 'Abrir',
              onAction: () => _abrir(const MisPaseosScreen()),
            ),
            const SizedBox(height: 14),
            _PaseadorActionCard(
              icon: Icons.route_rounded,
              title: 'Paseos asignados',
              subtitle: 'Acepta, inicia, finaliza y comparte ubicación.',
              onTap: () => _abrir(const MisPaseosScreen()),
            ),
            const SizedBox(height: 10),
            _PaseadorActionCard(
              icon: Icons.badge_rounded,
              title: 'Perfil profesional',
              subtitle: 'Actualiza foto, zona, tarifa y experiencia.',
              onTap: () => _abrir(const PerfilScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 34, 0, 0),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      color: DogGoTheme.teal,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(26),
          boxShadow: DogGoTheme.softShadow(),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ResumenItem(
                numero: _esPaseador
                    ? '${_proximosPaseos().length}'
                    : '${_perros.length}',
                texto: _esPaseador ? 'Próximos' : 'Mascotas',
              ),
            ),
            Expanded(
              child: _ResumenItem(
                numero: '${_paseos.length}',
                texto: 'Paseos',
              ),
            ),
            const Expanded(
              child: _ResumenItem(
                numero: 'Activo',
                texto: 'DogGo',
                active: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGuiasIntro() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: DogGoTheme.border.withOpacity(.85),
        ),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: DogGoTheme.orangeLight,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              'CENTRO DE GUÍAS DOGGO',
              style: DogGoTheme.body(
                size: 11,
                color: DogGoTheme.orange,
                weight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Guías, lugares y recomendaciones para cuidar mejor a tu mascota',
            style: DogGoTheme.title(size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            'Aquí tienes consejos de cuidado, productos útiles, lugares cercanos y datos de razas populares. Todo reunido en una sola sección para que no parezca solo una parte más del Home.',
            style: DogGoTheme.subtitle(size: 14.5),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _StatusPill(
                icon: Icons.health_and_safety_rounded,
                text: 'Cuidado',
                color: DogGoTheme.teal,
              ),
              _StatusPill(
                icon: Icons.shopping_bag_rounded,
                text: 'Recomendaciones',
                color: DogGoTheme.orange,
              ),
              _StatusPill(
                icon: Icons.place_rounded,
                text: 'Lugares',
                color: DogGoTheme.green,
              ),
              _StatusPill(
                icon: Icons.pets_rounded,
                text: 'Razas',
                color: DogGoTheme.purple,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  Widget _buildConsejos() {
    return _PatternSection(
      eyebrow: 'CUIDADO Y BIENESTAR',
      title: 'Consejos para tu mejor amigo',
      subtitle:
          'Guías rápidas con información útil para alimentación, ejercicio, salud e higiene.',
      child: Column(
        children: _consejos
            .map(
              (item) => _TipCard(
                item: item,
                onTap: () => _mostrarConsejo(item),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildProductos() {
    return _PlainSection(
      eyebrow: 'PARA TU MASCOTA',
      title: 'Recomendaciones útiles',
      subtitle:
          'Accesorios para mejorar paseos, descanso, entrenamiento y cuidado diario.',
      child: Column(
        children: _productos
            .map(
              (item) => _ProductCard(
                item: item,
                onTap: () => _abrirUrl(item.url),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLugares() {
    final lugares = [
      _PlaceData(
        icon: Icons.local_hospital_rounded,
        title: 'Veterinarias',
        subtitle: 'Atención médica cercana para consultas, vacunas y emergencias.',
        query: 'veterinarias para perros',
        tag1: 'Veterinaria',
        tag2: 'Cerca',
        imageUrl: 'https://loremflickr.com/900/600/veterinary,dog/all',
      ),
      _PlaceData(
        icon: Icons.park_rounded,
        title: 'Parques caninos',
        subtitle: 'Espacios dog friendly para caminar, jugar y socializar.',
        query: 'parques para perros',
        tag1: 'Parque',
        tag2: 'Dog friendly',
        imageUrl: 'https://loremflickr.com/900/600/dogpark,dog/all',
      ),
      _PlaceData(
        icon: Icons.storefront_rounded,
        title: 'Tiendas de mascotas',
        subtitle: 'Comida, premios, juguetes, correas y accesorios básicos.',
        query: 'tiendas para mascotas',
        tag1: 'Tienda',
        tag2: 'Accesorios',
        imageUrl: 'https://loremflickr.com/900/600/petstore,dog/all',
      ),
      _PlaceData(
        icon: Icons.content_cut_rounded,
        title: 'Estética canina',
        subtitle: 'Baño, corte, cepillado y cuidado de pelaje.',
        query: 'estetica canina',
        tag1: 'Grooming',
        tag2: 'Higiene',
        imageUrl: 'https://loremflickr.com/900/600/doggrooming,dog/all',
      ),
      _PlaceData(
        icon: Icons.coffee_rounded,
        title: 'Cafés pet friendly',
        subtitle: 'Lugares para convivir con tu perro en salidas tranquilas.',
        query: 'cafes pet friendly',
        tag1: 'Pet friendly',
        tag2: 'Salida',
        imageUrl: 'https://loremflickr.com/900/600/petfriendly,dog/all',
      ),
    ];

    return _PatternSection(
      eyebrow: 'MONTERREY Y ÁREA METRO',
      title: 'Lugares para tu mascota',
      subtitle:
          'Encuentra veterinarias, parques, tiendas y espacios dog friendly cerca de ti.',
      child: SizedBox(
        height: 390,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          itemCount: lugares.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final lugar = lugares[index];

            return _PlaceCard(
              data: lugar,
              onTap: () => _abrirLugarReal(lugar.query),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCuriosidades() {
    return _PlainSection(
      eyebrow: 'RAZAS POPULARES',
      title: 'Conoce más sobre cada raza',
      subtitle: 'Toca una tarjeta para ver detalles y cuidados generales.',
      child: SizedBox(
        height: 318,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          itemCount: _razas.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final raza = _razas[index];

            return _BreedImageCard(
              data: raza,
              onTap: () => _mostrarRaza(raza),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedHomeSection extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedHomeSection({
    required this.child,
    required this.delay,
  });

  @override
  State<_AnimatedHomeSection> createState() => _AnimatedHomeSectionState();
}

class _AnimatedHomeSectionState extends State<_AnimatedHomeSection> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;

      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, .055),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
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
    final mostrarBadge = badgeCount > 0;

    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DogGoTheme.border.withOpacity(.85),
                ),
              ),
              child: Icon(
                icon,
                color: DogGoTheme.ink,
                size: 25,
              ),
            ),
            if (mostrarBadge)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 19,
                    minHeight: 19,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.red,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: DogGoTheme.card,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
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

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: DogGoTheme.body(
              size: 12,
              color: DogGoTheme.ink,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}



class _MetricMiniCard extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  final IconData icon;

  const _MetricMiniCard({
    required this.number,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: DogGoTheme.title(size: 21),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: DogGoTheme.subtitle(size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DogGoBottomNav extends StatelessWidget {
  final int currentIndex;
  final String thirdLabel;
  final IconData thirdIcon;
  final VoidCallback onInicio;
  final VoidCallback onAgenda;
  final VoidCallback onThird;
  final String fourthLabel;
  final IconData fourthIcon;
  final VoidCallback onFourth;

  const _DogGoBottomNav({
    required this.currentIndex,
    required this.thirdLabel,
    required this.thirdIcon,
    required this.onInicio,
    required this.onAgenda,
    required this.onThird,
    required this.fourthLabel,
    required this.fourthIcon,
    required this.onFourth,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        height: 88,
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: DogGoTheme.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.16),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavButton(
                icon: Icons.home_rounded,
                label: 'Inicio',
                active: currentIndex == 0,
                onTap: onInicio,
              ),
            ),
            Expanded(
              child: _BottomNavButton(
                icon: Icons.calendar_month_rounded,
                label: 'Agenda',
                active: currentIndex == 1,
                onTap: onAgenda,
              ),
            ),
            Expanded(
              child: _BottomNavButton(
                icon: thirdIcon,
                label: thirdLabel,
                active: currentIndex == 2,
                onTap: onThird,
              ),
            ),
            Expanded(
              child: _BottomNavButton(
                icon: fourthIcon,
                label: fourthLabel,
                active: currentIndex == 3,
                onTap: onFourth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? DogGoTheme.teal : DogGoTheme.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: active ? DogGoTheme.tealLight : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: active ? 23 : 21,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: DogGoTheme.body(
                    size: 10,
                    color: color,
                    weight: active ? FontWeight.w900 : FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _QuickHomeAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickHomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(.10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color.withOpacity(.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color,
                size: 25,
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.body(
                  size: 13,
                  color: DogGoTheme.ink,
                  weight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.subtitle(size: 11.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final String mes;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalendarHeader({
    required this.mes,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight.withOpacity(.65),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: DogGoTheme.teal,
            ),
          ),
          Expanded(
            child: Text(
              mes,
              textAlign: TextAlign.center,
              style: DogGoTheme.body(
                size: 16,
                color: DogGoTheme.ink,
                weight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: DogGoTheme.teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime mes;
  final List<Map<String, dynamic>> Function(DateTime dia) paseosDelDia;
  final Color? Function(DateTime dia) colorEstado;
  final void Function(DateTime dia) onTapDia;

  const _CalendarGrid({
    required this.mes,
    required this.paseosDelDia,
    required this.colorEstado,
    required this.onTapDia,
  });

  @override
  Widget build(BuildContext context) {
    final primerDia = DateTime(mes.year, mes.month, 1);
    final diasMes = DateTime(mes.year, mes.month + 1, 0).day;
    final offset = primerDia.weekday - 1;
    final totalCeldas = (math.max(35, offset + diasMes) / 7).ceil() * 7;
    final hoy = DateTime.now();

    const diasSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Column(
      children: [
        Row(
          children: diasSemana
              .map(
                (dia) => Expanded(
                  child: Center(
                    child: Text(
                      dia,
                      style: DogGoTheme.body(
                        size: 12,
                        color: DogGoTheme.muted,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCeldas,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
          ),
          itemBuilder: (context, index) {
            final numeroDia = index - offset + 1;
            final enMes = numeroDia >= 1 && numeroDia <= diasMes;

            if (!enMes) {
              return const SizedBox.shrink();
            }

            final fecha = DateTime(mes.year, mes.month, numeroDia);
            final paseos = paseosDelDia(fecha);
            final color = colorEstado(fecha);
            final esHoy = fecha.year == hoy.year &&
                fecha.month == hoy.month &&
                fecha.day == hoy.day;

            return _CalendarDayCell(
              dia: numeroDia,
              esHoy: esHoy,
              cantidad: paseos.length,
              color: color,
              onTap: () => onTapDia(fecha),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int dia;
  final bool esHoy;
  final int cantidad;
  final Color? color;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.dia,
    required this.esHoy,
    required this.cantidad,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tienePaseos = cantidad > 0;
    final baseColor = color ?? DogGoTheme.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: tienePaseos
                ? baseColor.withOpacity(.12)
                : esHoy
                    ? DogGoTheme.tealLight.withOpacity(.55)
                    : DogGoTheme.cream2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: esHoy
                  ? DogGoTheme.teal
                  : tienePaseos
                      ? baseColor.withOpacity(.32)
                      : DogGoTheme.border.withOpacity(.7),
              width: esHoy ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$dia',
                  style: DogGoTheme.body(
                    size: 13,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w900,
                  ),
                ),
              ),
              if (tienePaseos)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: const [
        _LegendItem(color: DogGoTheme.orange, text: 'Pendiente'),
        _LegendItem(color: DogGoTheme.green, text: 'En curso'),
        _LegendItem(color: DogGoTheme.teal, text: 'Finalizado'),
        _LegendItem(color: DogGoTheme.red, text: 'Cancelado'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: DogGoTheme.subtitle(size: 11.5),
        ),
      ],
    );
  }
}

class _PaseoAgendaTile extends StatelessWidget {
  final String hora;
  final String titulo;
  final String subtitulo;
  final String estado;
  final Color color;
  final VoidCallback onTap;

  const _PaseoAgendaTile({
    required this.hora,
    required this.titulo,
    required this.subtitulo,
    required this.estado,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.82),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      hora,
                      style: DogGoTheme.body(
                        size: 12,
                        color: color,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.body(
                          size: 14.5,
                          color: DogGoTheme.ink,
                          weight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(size: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 104),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      estado,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.body(
                        size: 10.5,
                        color: Colors.white,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarErrorCard extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _CalendarErrorCard({
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.red.withOpacity(.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DogGoTheme.red.withOpacity(.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: DogGoTheme.red,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'No se pudo cargar el calendario',
            style: DogGoTheme.title(size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 12.5),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
class _NoUpcomingWalksCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NoUpcomingWalksCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.cream2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: DogGoTheme.teal,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay próximos paseos por ahora.',
                  style: DogGoTheme.body(
                    size: 13.5,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DogGoTheme.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyDayCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.tealLight.withOpacity(.62),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: DogGoTheme.teal,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                'Día libre',
                style: DogGoTheme.title(size: 20),
              ),
              const SizedBox(height: 5),
              Text(
                'Puedes revisar tus paseos o agendar uno nuevo.',
                textAlign: TextAlign.center,
                style: DogGoTheme.subtitle(size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DogPreviewLargeCard extends StatelessWidget {
  final String nombre;
  final String raza;
  final String edad;
  final String tamano;
  final String notas;
  final String fotoUrl;
  final VoidCallback onTap;

  const _DogPreviewLargeCard({
    required this.nombre,
    required this.raza,
    required this.edad,
    required this.tamano,
    required this.notas,
    required this.fotoUrl,
    required this.onTap,
  });

  bool get _tieneFoto {
    return fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: DogGoTheme.border.withOpacity(.9),
            ),
            boxShadow: DogGoTheme.softShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: 235,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _tieneFoto
                          ? Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const _DogImagePlaceholder();
                              },
                            )
                          : const _DogImagePlaceholder(),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.94),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          tamano,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DogGoTheme.body(
                            size: 12,
                            color: DogGoTheme.teal,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.title(size: 26),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        raza,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(size: 14.5),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: _DogMiniInfo(
                              icon: Icons.cake_rounded,
                              title: 'Edad',
                              value: edad,
                              color: DogGoTheme.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DogMiniInfo(
                              icon: Icons.straighten_rounded,
                              title: 'Tamaño',
                              value: tamano,
                              color: DogGoTheme.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DogNoteBox(notas: notas),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: DogGoTheme.tealLight,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Text(
                            'Ver perfil completo →',
                            style: DogGoTheme.body(
                              size: 13.5,
                              color: DogGoTheme.teal,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DogMiniInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DogMiniInfo({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: DogGoTheme.subtitle(size: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.body(
                    size: 12,
                    color: DogGoTheme.ink,
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

class _DogNoteBox extends StatelessWidget {
  final String notas;

  const _DogNoteBox({
    required this.notas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight.withOpacity(.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DogGoTheme.orange.withOpacity(.12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sticky_note_2_rounded,
            color: DogGoTheme.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notas,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.body(
                size: 11.8,
                color: DogGoTheme.ink,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DogImagePlaceholder extends StatelessWidget {
  const _DogImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DogGoTheme.tealLight,
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: DogGoTheme.teal.withOpacity(.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.pets_rounded,
              size: 62,
              color: DogGoTheme.teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceBox extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AdviceBox({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight.withOpacity(.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DogGoTheme.teal.withOpacity(.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DogGoTheme.body(
              size: 15,
              color: DogGoTheme.ink,
              weight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _AdviceBullet extends StatelessWidget {
  final String text;

  const _AdviceBullet({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: DogGoTheme.teal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: DogGoTheme.subtitle(
                size: 13.2,
                color: DogGoTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationBox extends StatelessWidget {
  final String text;

  const _RecommendationBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DogGoTheme.orange.withOpacity(.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: DogGoTheme.orange,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: DogGoTheme.body(
                size: 13.2,
                color: DogGoTheme.ink,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotasEmptyCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MascotasEmptyCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DogGoTheme.tealLight.withOpacity(.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: DogGoTheme.teal.withOpacity(.15),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.pets_rounded,
              size: 84,
              color: DogGoTheme.teal,
            ),
            const SizedBox(height: 14),
            Text(
              'Agrega tu primer perro',
              style: DogGoTheme.title(size: 24),
            ),
            const SizedBox(height: 5),
            Text(
              'Fotos, raza, edad, tamaño y notas',
              textAlign: TextAlign.center,
              style: DogGoTheme.subtitle(size: 13),
            ),
            const SizedBox(height: 14),
            Text(
              'Ir a Mis perros →',
              style: DogGoTheme.body(
                size: 14,
                color: DogGoTheme.teal,
                weight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotasErrorCard extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _MascotasErrorCard({
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.red.withOpacity(.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DogGoTheme.red.withOpacity(.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: DogGoTheme.red,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'No se pudieron cargar tus perros',
            style: DogGoTheme.title(size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 12.5),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;

  const _SectionTitleRow({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: DogGoTheme.title(size: 22),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: DogGoTheme.teal,
            backgroundColor: DogGoTheme.tealLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            actionText,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String numero;
  final String texto;
  final bool active;

  const _ResumenItem({
    required this.numero,
    required this.texto,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          active ? '● $numero' : numero,
          textAlign: TextAlign.center,
          style: DogGoTheme.title(
            size: active ? 19 : 22,
            color: active ? DogGoTheme.green : DogGoTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: DogGoTheme.subtitle(size: 12),
        ),
      ],
    );
  }
}

class _PatternSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  const _PatternSection({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 38, 22, 28),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        image: DecorationImage(
          image: _PawPatternImage(),
          repeat: ImageRepeat.repeat,
          opacity: .08,
        ),
      ),
      child: Column(
        children: [
          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: DogGoTheme.label(size: 11),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 29),
          ),
          const SizedBox(height: 11),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 15.5),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}

class _PlainSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  const _PlainSection({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: DogGoTheme.cream,
      padding: const EdgeInsets.fromLTRB(22, 38, 22, 28),
      child: Column(
        children: [
          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: DogGoTheme.label(size: 11),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 29),
          ),
          const SizedBox(height: 11),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 15.5),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}

class _TipData {
  final IconData icon;
  final String categoria;
  final String titulo;
  final String descripcion;
  final String lectura;
  final List<String> puntos;
  final String recomendacion;

  const _TipData({
    required this.icon,
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.lectura,
    required this.puntos,
    required this.recomendacion,
  });
}

class _TipCard extends StatelessWidget {
  final _TipData item;
  final VoidCallback onTap;

  const _TipCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _WebCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(
                icon: item.icon,
                color: DogGoTheme.teal,
                background: DogGoTheme.tealLight,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Tag(text: item.categoria),
                    const SizedBox(height: 7),
                    Text(
                      item.lectura,
                      style: DogGoTheme.subtitle(size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            item.titulo,
            style: DogGoTheme.title(size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            item.descripcion,
            style: DogGoTheme.subtitle(size: 15),
          ),
          const SizedBox(height: 16),
          _MiniChecklist(items: item.puntos),
          const SizedBox(height: 15),
          _RecommendationInline(text: item.recomendacion),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Ver guía completa →',
              style: DogGoTheme.body(
                size: 13.5,
                color: DogGoTheme.teal,
                weight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChecklist extends StatelessWidget {
  final List<String> items;

  const _MiniChecklist({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final visibles = items.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight.withOpacity(.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DogGoTheme.teal.withOpacity(.10),
        ),
      ),
      child: Column(
        children: visibles
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: DogGoTheme.teal,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: DogGoTheme.body(
                          size: 12.6,
                          color: DogGoTheme.ink,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RecommendationInline extends StatelessWidget {
  final String text;

  const _RecommendationInline({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.tips_and_updates_rounded,
          color: DogGoTheme.orange,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 12.7,
              color: DogGoTheme.ink,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductData {
  final IconData icon;
  final String titulo;
  final String descripcion;
  final String etiqueta1;
  final String etiqueta2;
  final String detalle;
  final String url;

  const _ProductData({
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.etiqueta1,
    required this.etiqueta2,
    required this.detalle,
    required this.url,
  });
}

class _ProductCard extends StatelessWidget {
  final _ProductData item;
  final VoidCallback onTap;

  const _ProductCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _WebCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(
                icon: item.icon,
                color: DogGoTheme.orange,
                background: DogGoTheme.orangeLight,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.titulo,
                  style: DogGoTheme.title(size: 21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.descripcion,
            style: DogGoTheme.subtitle(size: 15),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DogGoTheme.cream2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: DogGoTheme.teal,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.detalle,
                    style: DogGoTheme.body(
                      size: 12.8,
                      color: DogGoTheme.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(text: item.etiqueta1, teal: false),
              _Tag(text: item.etiqueta2, teal: false),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Ver opciones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DogGoTheme.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 64,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .31),
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }
}

class _PlaceData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String query;
  final String tag1;
  final String tag2;
  final String imageUrl;

  const _PlaceData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.query,
    required this.tag1,
    required this.tag2,
    required this.imageUrl,
  });
}

class _PlaceCard extends StatelessWidget {
  final _PlaceData data;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = math.min(268.0, screenWidth * .74);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: DogGoTheme.border.withOpacity(.85),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.055),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          data.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: DogGoTheme.tealLight,
                              child: Center(
                                child: Icon(
                                  data.icon,
                                  color: DogGoTheme.teal,
                                  size: 56,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(.46),
                                Colors.black.withOpacity(.05),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.92),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                data.icon,
                                color: DogGoTheme.teal,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                data.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DogGoTheme.title(
                                  size: 19,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: DogGoTheme.subtitle(size: 13.2),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _Tag(text: data.tag1),
                            _Tag(text: data.tag2),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 43,
                          decoration: BoxDecoration(
                            color: DogGoTheme.tealLight,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(
                              'Abrir en mapa →',
                              style: DogGoTheme.body(
                                size: 13,
                                color: DogGoTheme.teal,
                                weight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _BreedData {
  final String nombre;
  final String resumen;
  final String detalle;
  final String imageUrl;

  const _BreedData({
    required this.nombre,
    required this.resumen,
    required this.detalle,
    required this.imageUrl,
  });
}
class _BreedImageCard extends StatelessWidget {
  final _BreedData data;
  final VoidCallback onTap;

  const _BreedImageCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 235,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: DogGoTheme.border.withOpacity(.85),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.055),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          data.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const _DogImagePlaceholder();
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(.42),
                                Colors.black.withOpacity(.05),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 13,
                        child: Text(
                          data.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: DogGoTheme.title(
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.resumen,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DogGoTheme.body(
                            size: 12.5,
                            color: DogGoTheme.teal,
                            weight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.detalle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: DogGoTheme.subtitle(size: 12.5),
                        ),
                        const Spacer(),
                        Text(
                          'Ver detalles →',
                          style: DogGoTheme.body(
                            size: 13,
                            color: DogGoTheme.orange,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool highlight;
  final VoidCallback onTap;

  const _OwnerActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlight ? color : color.withOpacity(.08);
    final foreground = highlight ? Colors.white : color;
    final textColor = highlight ? Colors.white : DogGoTheme.ink;
    final subtitleColor =
        highlight ? Colors.white.withOpacity(.86) : DogGoTheme.muted;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlight
                  ? Colors.white.withOpacity(.18)
                  : color.withOpacity(.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: highlight
                      ? Colors.white.withOpacity(.18)
                      : Colors.white.withOpacity(.9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: foreground,
                  size: 28,
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
                        size: 16,
                        color: textColor,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: DogGoTheme.body(
                        size: 12.8,
                        color: subtitleColor,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: highlight ? Colors.white : DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaseadorActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaseadorActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _WebCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          _IconTile(
            icon: icon,
            color: DogGoTheme.teal,
            background: DogGoTheme.tealLight,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DogGoTheme.title(size: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: DogGoTheme.subtitle(size: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _WebCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const _WebCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(24),
    this.margin = const EdgeInsets.only(bottom: 18),
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: DogGoTheme.border.withOpacity(.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.055),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool teal;

  const _Tag({
    required this.text,
    this.teal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: teal ? DogGoTheme.tealLight : DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: DogGoTheme.body(
          size: 11,
          color: teal ? DogGoTheme.teal : DogGoTheme.orange,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? DogGoTheme.red : DogGoTheme.ink;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: DogGoTheme.body(
          size: 15,
          color: color,
          weight: FontWeight.w800,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _PawPatternImage extends ImageProvider<_PawPatternImage> {
  @override
  ImageStreamCompleter loadImage(
    _PawPatternImage key,
    ImageDecoderCallback decode,
  ) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()
      ..color = DogGoTheme.teal
      ..style = ui.PaintingStyle.fill;

    for (var x = 0.0; x < 90; x += 45) {
      for (var y = 0.0; y < 90; y += 45) {
        canvas.drawCircle(ui.Offset(x + 14, y + 22), 5, paint);
        canvas.drawCircle(ui.Offset(x + 24, y + 16), 4.5, paint);
        canvas.drawCircle(ui.Offset(x + 34, y + 22), 5, paint);
        canvas.drawOval(
          ui.Rect.fromCenter(
            center: ui.Offset(x + 24, y + 32),
            width: 24,
            height: 18,
          ),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    final imageFuture = picture.toImage(90, 90);

    return OneFrameImageStreamCompleter(
      imageFuture.then((image) => ImageInfo(image: image)),
    );
  }

  @override
  Future<_PawPatternImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_PawPatternImage>(this);
  }
}