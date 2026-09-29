import 'package:geolocator/geolocator.dart';

/// Envoltorio simple sobre geolocator: pide permisos y expone la
/// ubicación actual y un flujo en vivo para dibujar el punto del
/// usuario sobre el mapa.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Stream<Position>? _flujo;

  Future<bool> asegurarPermiso() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) return false;

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse;
  }

  Future<Position?> ubicacionActual() async {
    final ok = await asegurarPermiso();
    if (!ok) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Flujo compartido: todas las pantallas que pidan la ubicación en vivo
  /// reciben las mismas actualizaciones del GPS del teléfono.
  Stream<Position> flujoUbicacion() {
    final existente = _flujo;
    if (existente != null) return existente;
    final nuevo = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).asBroadcastStream();
    _flujo = nuevo;
    return nuevo;
  }
}
