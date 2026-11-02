import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Campo de visión horizontal asumido de la cámara del teléfono, en grados.
/// Se usa como umbral: el pin y las luces de pista solo se muestran cuando
/// la diferencia de rumbo cabe dentro de la mitad de este ángulo a cada lado.
const double fovGrados = 60;

enum SectorGiro { deFrente, derecha, izquierda, detras }

/// Rumbo inicial (en grados, 0-360, 0 = norte) desde [origen] hacia [destino].
double rumboHacia(LatLng origen, LatLng destino) {
  final lat1 = _aRadianes(origen.latitude);
  final lat2 = _aRadianes(destino.latitude);
  final deltaLon = _aRadianes(destino.longitude - origen.longitude);

  final y = math.sin(deltaLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

  final rumbo = _aGrados(math.atan2(y, x));
  return (rumbo + 360) % 360;
}

/// Diferencia angular entre el rumbo hacia el objetivo y hacia dónde apunta
/// el dispositivo, normalizada a [-180, 180]. Positivo = el objetivo está a
/// la derecha; negativo = a la izquierda.
double diferenciaAngular(double rumboObjetivo, double rumboDispositivo) {
  var diferencia = (rumboObjetivo - rumboDispositivo) % 360;
  if (diferencia > 180) diferencia -= 360;
  if (diferencia < -180) diferencia += 360;
  return diferencia;
}

/// true si el objetivo cae dentro del campo de visión de la cámara, dada su
/// diferencia angular respecto a hacia dónde apunta el dispositivo.
bool dentroDelCampoDeVision(double diferencia) {
  return diferencia.abs() <= fovGrados / 2;
}

/// Mapea la diferencia angular a un sector discreto, para el modo asistente
/// (mensajes de "girá a la derecha/izquierda" o "está detrás tuyo").
SectorGiro sectorDesdeAngulo(double diferencia) {
  final abs = diferencia.abs();
  if (abs <= 15) return SectorGiro.deFrente;
  if (abs >= 135) return SectorGiro.detras;
  return diferencia > 0 ? SectorGiro.derecha : SectorGiro.izquierda;
}

double _aRadianes(double grados) => grados * math.pi / 180;
double _aGrados(double radianes) => radianes * 180 / math.pi;

/// Punto más cercano a [punto] sobre la polilínea [puntos] (p. ej. la forma
/// de una línea de trufi). Se usa porque el feed GTFS de Cochabamba no tiene
/// paradas fijas reales: las "paradas" importadas son aproximadas, así que
/// el punto que se usa como destino de la navegación se ajusta al trayecto
/// real de la línea en lugar de a esa coordenada aproximada.
LatLng puntoMasCercanoEnRuta(List<LatLng> puntos, LatLng punto) {
  if (puntos.isEmpty) return punto;
  if (puntos.length == 1) return puntos.first;

  LatLng mejor = puntos.first;
  double mejorDistancia = double.infinity;

  for (var i = 0; i < puntos.length - 1; i++) {
    final candidato = _puntoMasCercanoEnSegmento(puntos[i], puntos[i + 1], punto);
    final distancia = _distanciaPlanaAprox(candidato, punto);
    if (distancia < mejorDistancia) {
      mejorDistancia = distancia;
      mejor = candidato;
    }
  }
  return mejor;
}

/// Proyección del punto sobre el segmento a-b, tratando lat/lon como un
/// plano local: suficiente precisión para distancias cortas (metros/pocos
/// kilómetros) como las de un tramo de ruta de trufi.
LatLng _puntoMasCercanoEnSegmento(LatLng a, LatLng b, LatLng punto) {
  final corrLon = math.cos(_aRadianes(a.latitude));
  final ax = a.longitude * corrLon;
  final ay = a.latitude;
  final bx = b.longitude * corrLon;
  final by = b.latitude;
  final px = punto.longitude * corrLon;
  final py = punto.latitude;

  final dx = bx - ax;
  final dy = by - ay;
  final largoCuadrado = dx * dx + dy * dy;
  if (largoCuadrado == 0) return a;

  var t = ((px - ax) * dx + (py - ay) * dy) / largoCuadrado;
  t = t.clamp(0.0, 1.0);

  final lon = (ax + t * dx) / corrLon;
  final lat = ay + t * dy;
  return LatLng(lat, lon);
}

double _distanciaPlanaAprox(LatLng a, LatLng b) {
  final dLat = a.latitude - b.latitude;
  final dLon = a.longitude - b.longitude;
  return dLat * dLat + dLon * dLon;
}
