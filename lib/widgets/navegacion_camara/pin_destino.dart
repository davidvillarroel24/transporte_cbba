import 'package:flutter/material.dart';

import '../../services/orientacion_navegacion.dart';

/// Distancia máxima a la que el pin del punto de abordaje se muestra.
const double distanciaMaximaPinMetros = 20;

/// true si, dadas la distancia al destino y la diferencia de rumbo, el pin
/// debería estar visible: hay que estar cerca Y mirando hacia el destino.
bool pinDebeSerVisible(double distanciaMetros, double diferenciaAngular) {
  return distanciaMetros <= distanciaMaximaPinMetros &&
      dentroDelCampoDeVision(diferenciaAngular);
}

/// Posición horizontal en pantalla para una diferencia angular dada,
/// compartida entre el pin y las luces de pista (que apuntan al mismo
/// punto de fuga).
double posicionXPin(double anchoPantalla, double diferenciaAngular) {
  final fraccion = (diferenciaAngular / (fovGrados / 2)).clamp(-1.0, 1.0);
  return anchoPantalla / 2 + fraccion * (anchoPantalla / 2);
}

/// Pin del punto de abordaje: crece a medida que uno se acerca, y se ubica
/// horizontalmente según hacia qué lado del campo de visión cae el destino.
/// Solo debe incluirse en el árbol de widgets cuando [pinDebeSerVisible] es
/// true; la propia pantalla decide eso para poder mostrar el modo asistente
/// en su lugar cuando no corresponde.
class PinDestino extends StatelessWidget {
  final double distanciaMetros;
  final double diferenciaAngular;

  const PinDestino({
    super.key,
    required this.distanciaMetros,
    required this.diferenciaAngular,
  });

  double _tamano(double altoPantalla) {
    final maximo = altoPantalla / 5;
    final minimo = maximo * 0.35;
    final cercania = 1 - (distanciaMetros / distanciaMaximaPinMetros).clamp(0.0, 1.0);
    return minimo + (maximo - minimo) * cercania;
  }

  @override
  Widget build(BuildContext context) {
    final tamano = MediaQuery.of(context).size;
    final alto = _tamano(tamano.height);
    final x = posicionXPin(tamano.width, diferenciaAngular);
    return Positioned(
      left: (x - alto / 2).clamp(0.0, tamano.width - alto),
      top: tamano.height / 2 - alto,
      child: Icon(
        Icons.location_on,
        size: alto,
        color: Colors.redAccent,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
      ),
    );
  }
}
