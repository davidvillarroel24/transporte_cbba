import 'linea.dart';
import 'parada.dart';

class ResultadoRuta {
  final Linea linea;
  final Parada paradaOrigen;
  final Parada paradaDestino;
  final int tiempoMinutos;
  final double? tarifa;
  final int viajesEncontrados;
  final String? shapeId;

  const ResultadoRuta({
    required this.linea,
    required this.paradaOrigen,
    required this.paradaDestino,
    required this.tiempoMinutos,
    required this.tarifa,
    required this.viajesEncontrados,
    required this.shapeId,
  });

  String get tarifaTexto {
    final valor = tarifa;
    if (valor == null || valor <= 0) return 'No registrada en los datos';
    return 'Bs. ${valor.toStringAsFixed(2)}';
  }
}
