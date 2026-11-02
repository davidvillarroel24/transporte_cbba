import 'package:flutter/material.dart';

/// Línea de perspectiva tipo "luces de pista de aterrizaje" desde la parte
/// inferior de la pantalla hasta el punto de fuga (la posición del pin),
/// con una secuencia de iluminación que recorre los segmentos.
class LucesPista extends StatefulWidget {
  final Offset puntoDeFuga;

  const LucesPista({super.key, required this.puntoDeFuga});

  @override
  State<LucesPista> createState() => _LucesPistaState();
}

class _LucesPistaState extends State<LucesPista> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controlador,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _PintorLucesPista(
              puntoDeFuga: widget.puntoDeFuga,
              progreso: _controlador.value,
            ),
          );
        },
      ),
    );
  }
}

class _PintorLucesPista extends CustomPainter {
  final Offset puntoDeFuga;
  final double progreso;
  static const _segmentos = 9;

  _PintorLucesPista({required this.puntoDeFuga, required this.progreso});

  @override
  void paint(Canvas canvas, Size size) {
    final origen = Offset(size.width / 2, size.height);
    final ondaEn = progreso * _segmentos;

    for (var i = 0; i < _segmentos; i++) {
      final t0 = i / _segmentos;
      final t1 = (i + 0.6) / _segmentos;
      final p0 = Offset.lerp(origen, puntoDeFuga, t0)!;
      final p1 = Offset.lerp(origen, puntoDeFuga, t1)!;

      // Más angosto y tenue cuanto más cerca del punto de fuga (perspectiva).
      final anchoBase = 10 * (1 - t0 * 0.8);

      final distanciaOnda = (ondaEn - i).abs();
      final brillo = (1 - (distanciaOnda / 2.5)).clamp(0.0, 1.0);
      final opacidad = 0.18 + 0.65 * brillo;

      final pintura = Paint()
        ..color = Colors.amberAccent.withOpacity(opacidad)
        ..strokeWidth = anchoBase
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p0, p1, pintura);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorLucesPista oldDelegate) {
    return oldDelegate.progreso != progreso || oldDelegate.puntoDeFuga != puntoDeFuga;
  }
}
