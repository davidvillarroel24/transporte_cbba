import 'package:flutter/material.dart';

import '../../services/orientacion_navegacion.dart';

/// Se muestra cuando el destino está fuera del campo de visión de la
/// cámara: un trazo de energía (recto, con una curva hacia el lado del giro
/// cerca de la punta) y un mensaje de texto indicando hacia dónde girar.
/// No pretende conocer calles reales, solo el rumbo en línea recta hacia
/// el destino.
class ModoAsistente extends StatefulWidget {
  final double diferenciaAngular;

  const ModoAsistente({super.key, required this.diferenciaAngular});

  @override
  State<ModoAsistente> createState() => _ModoAsistenteState();
}

class _ModoAsistenteState extends State<ModoAsistente> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  String get _mensaje {
    switch (sectorDesdeAngulo(widget.diferenciaAngular)) {
      case SectorGiro.deFrente:
        return 'Seguí de frente';
      case SectorGiro.derecha:
        return 'En cuanto puedas, girá a la derecha';
      case SectorGiro.izquierda:
        return 'En cuanto puedas, girá a la izquierda';
      case SectorGiro.detras:
        return 'El destino está detrás tuyo, date la vuelta';
    }
  }

  IconData get _icono {
    switch (sectorDesdeAngulo(widget.diferenciaAngular)) {
      case SectorGiro.deFrente:
        return Icons.arrow_upward;
      case SectorGiro.derecha:
        return Icons.arrow_forward;
      case SectorGiro.izquierda:
        return Icons.arrow_back;
      case SectorGiro.detras:
        return Icons.u_turn_left;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sector = sectorDesdeAngulo(widget.diferenciaAngular);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controlador,
              builder: (context, _) => CustomPaint(
                painter: _PintorTrazoEnergia(sector: sector, fase: _controlador.value),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 110,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.72),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icono, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _mensaje,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dibuja el trazo de energía: recto desde abajo hasta la mitad del tramo,
/// curvando hacia el lado del giro en el último tercio, y rematado con una
/// punta de flecha. Un pulso de brillo cian recorre el trazo en bucle,
/// estilo "luces de pilón de energía".
class _PintorTrazoEnergia extends CustomPainter {
  final SectorGiro sector;
  final double fase;

  _PintorTrazoEnergia({required this.sector, required this.fase});

  static const _colorBase = Color(0xFF0DF0E8);

  @override
  void paint(Canvas canvas, Size size) {
    final origen = Offset(size.width / 2, size.height - 20);
    // El trazo llega como máximo a la mitad de la pantalla, no a toda su
    // altura: representa un tramo de camino corto, no una flecha infinita.
    final alturaTrazo = (size.height / 2 - 20).clamp(60.0, size.height);
    final cimaRecta = Offset(size.width / 2, origen.dy - alturaTrazo * 0.55);

    double desvioCurva;
    switch (sector) {
      case SectorGiro.derecha:
        desvioCurva = size.width * 0.22;
        break;
      case SectorGiro.izquierda:
        desvioCurva = -size.width * 0.22;
        break;
      case SectorGiro.detras:
      case SectorGiro.deFrente:
        desvioCurva = 0;
        break;
    }
    final punta = Offset(cimaRecta.dx + desvioCurva, origen.dy - alturaTrazo);
    final controlCurva = Offset(cimaRecta.dx, punta.dy);

    final trazo = Path()
      ..moveTo(origen.dx, origen.dy)
      ..lineTo(cimaRecta.dx, cimaRecta.dy)
      ..quadraticBezierTo(controlCurva.dx, controlCurva.dy, punta.dx, punta.dy);

    final metrica = trazo.computeMetrics().first;
    final largoTotal = metrica.length;
    // El trazo termina donde empieza la flecha, para que no la sobrepase.
    final largoLinea = (largoTotal - _largoFlecha).clamp(0.0, largoTotal);

    // Estela de base: gruesa y transparente donde nace (abajo), afinándose
    // y volviéndose más sólida a medida que se acerca a la flecha.
    const pasos = 24;
    for (var i = 0; i < pasos; i++) {
      final t0 = i / pasos;
      final t1 = (i + 1) / pasos;
      final segmento = metrica.extractPath(largoLinea * t0, largoLinea * t1);
      final tMedio = (t0 + t1) / 2;
      final pintura = Paint()
        ..color = _colorBase.withOpacity(_lerp(0.18, 0.75, tMedio))
        ..style = PaintingStyle.stroke
        ..strokeWidth = _lerp(16, 3, tMedio)
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(segmento, pintura);
    }

    // Pulso de energía: un segmento brillante que recorre el trazo en
    // bucle, con un leve resplandor (glow) detrás.
    const largoPulso = 70.0;
    final inicioPulso = fase * (largoLinea + largoPulso) - largoPulso;
    final desde = inicioPulso.clamp(0.0, largoLinea);
    final hasta = (inicioPulso + largoPulso).clamp(0.0, largoLinea);
    if (hasta > desde) {
      final segmentoPulso = metrica.extractPath(desde, hasta);
      final pinturaGlow = Paint()
        ..color = _colorBase.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(segmentoPulso, pinturaGlow);

      final pinturaNucleo = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(segmentoPulso, pinturaNucleo);
    }

    // Punta de flecha al final del trazo, orientada según la tangente de
    // la curva en ese punto.
    final tangente = metrica.getTangentForOffset(largoTotal);
    if (tangente != null) {
      _dibujarFlecha(canvas, tangente.position, tangente.vector);
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static const _largoFlecha = 20.0;

  void _dibujarFlecha(Canvas canvas, Offset punta, Offset direccion) {
    final largo = direccion.distance;
    if (largo == 0) return;
    final unidad = direccion / largo;
    final normal = Offset(-unidad.dy, unidad.dx);
    const anchoFlecha = 14.0;

    final base = punta - unidad * _largoFlecha;
    final izquierda = base + normal * anchoFlecha / 2;
    final derecha = base - normal * anchoFlecha / 2;

    final path = Path()
      ..moveTo(punta.dx, punta.dy)
      ..lineTo(izquierda.dx, izquierda.dy)
      ..lineTo(derecha.dx, derecha.dy)
      ..close();

    final pinturaGlow = Paint()
      ..color = _colorBase.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, pinturaGlow);

    final pinturaFlecha = Paint()..color = Colors.white;
    canvas.drawPath(path, pinturaFlecha);
  }

  @override
  bool shouldRepaint(covariant _PintorTrazoEnergia oldDelegate) =>
      oldDelegate.sector != sector || oldDelegate.fase != fase;
}
