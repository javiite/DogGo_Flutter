import 'package:flutter/material.dart';

import '../services/calificaciones_service.dart';

class CalificarPaseoScreen extends StatefulWidget {
  final int paseoId;
  final String nombrePerro;
  final String nombrePaseador;

  const CalificarPaseoScreen({
    super.key,
    required this.paseoId,
    required this.nombrePerro,
    required this.nombrePaseador,
  });

  @override
  State<CalificarPaseoScreen> createState() => _CalificarPaseoScreenState();
}

class _CalificarPaseoScreenState extends State<CalificarPaseoScreen> {
  final CalificacionesService _calificacionesService = CalificacionesService();
  final TextEditingController _comentarioController = TextEditingController();

  int _puntaje = 5;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    final comentario = _comentarioController.text.trim();

    if (_puntaje < 1 || _puntaje > 5) {
      _mostrarMensaje('Selecciona una calificación válida.');
      return;
    }

    if (comentario.length < 3) {
      _mostrarMensaje('Escribe un comentario un poco más completo.');
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      await _calificacionesService.calificarPaseo(
        paseoId: widget.paseoId,
        puntaje: _puntaje,
        comentario: comentario,
      );

      if (!mounted) return;

      _mostrarMensaje('Calificación enviada correctamente.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo enviar la calificación: $e');
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  String get _textoPuntaje {
    switch (_puntaje) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return 'Selecciona';
    }
  }

  Color get _colorPuntaje {
    switch (_puntaje) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Calificar paseo'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPuntajeCard(),
            const SizedBox(height: 16),
            _buildComentarioCard(),
            const SizedBox(height: 18),
            _buildBotonEnviar(),
            const SizedBox(height: 14),
            _buildNota(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F8A70),
            Color(0xFF35A98A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.24),
              ),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Cómo estuvo el paseo?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Perro: ${widget.nombrePerro}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Paseador: ${widget.nombrePaseador}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuntajeCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: _colorPuntaje.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.reviews_rounded,
                  color: _colorPuntaje,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Calificación: $_textoPuntaje',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final valor = index + 1;
              final seleccionado = valor <= _puntaje;

              return IconButton(
                onPressed: _enviando
                    ? null
                    : () {
                        setState(() {
                          _puntaje = valor;
                        });
                      },
                icon: Icon(
                  seleccionado
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 38,
                  color: seleccionado ? _colorPuntaje : Colors.grey.shade400,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            '$_puntaje de 5 estrellas',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComentarioCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextField(
        controller: _comentarioController,
        enabled: !_enviando,
        maxLines: 5,
        maxLength: 250,
        decoration: InputDecoration(
          labelText: 'Comentario',
          hintText: 'Ej. Fue puntual, cuidó bien a mi perro y mandó evidencia.',
          alignLabelWithHint: true,
          filled: true,
          fillColor: const Color(0xFFF4F6F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(
              color: Color(0xFF1F8A70),
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonEnviar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _enviando ? null : _enviarCalificacion,
        icon: _enviando
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(_enviando ? 'Enviando...' : 'Enviar calificación'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F8A70),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  Widget _buildNota() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.blue,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu calificación ayuda a otros dueños a elegir paseadores confiables.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}