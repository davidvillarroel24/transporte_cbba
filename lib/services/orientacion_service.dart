import 'dart:async';
import 'dart:collection';

import 'package:flutter_device_compass/flutter_device_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Envuelve los sensores del teléfono que necesita la navegación asistida
/// por cámara: la brújula (rumbo del dispositivo) y el acelerómetro
/// (¿está el teléfono de pie, como mirando por la cámara, o acostado sobre
/// una mesa?).
class OrientacionService {
  OrientacionService._();
  static final OrientacionService instance = OrientacionService._();

  static const _muestrasSuavizado = 5;

  Stream<double>? _rumbo;
  Stream<bool>? _vertical;

  /// Rumbo del dispositivo en grados (0-360, 0 = norte). Filtra las
  /// lecturas nulas que la brújula entrega cuando el sensor no está
  /// disponible o aún no tiene una lectura válida.
  Stream<double> rumboDispositivo() {
    final existente = _rumbo;
    if (existente != null) return existente;
    final nuevo = FlutterCompass.events
        ?.map((evento) {
          // El código nativo del plugin (BearingCalculator.kt) calcula el
          // rumbo con las APIs estándar de Android (SensorManager.getOrientation),
          // que ya entregan la convención correcta: 0°=norte, creciendo en
          // sentido horario. No hace falta ninguna corrección acá.
          final crudo = evento.heading;
          if (crudo == null) return null;
          return crudo % 360;
        })
        .where((rumbo) => rumbo != null)
        .cast<double>()
        .asBroadcastStream() ?? const Stream<double>.empty();
    _rumbo = nuevo;
    return nuevo;
  }

  /// true cuando el teléfono está sostenido en vertical (como mirando por
  /// la cámara); false cuando está acostado sobre una superficie plana.
  /// Se promedia una ventana de lecturas para no parpadear por el ruido
  /// del sensor mientras el usuario camina.
  Stream<bool> telefonoVertical() {
    final existente = _vertical;
    if (existente != null) return existente;
    final ventana = Queue<bool>();
    final controlador = StreamController<bool>.broadcast();
    StreamSubscription<AccelerometerEvent>? suscripcion;

    controlador.onListen = () {
      suscripcion ??= accelerometerEventStream().listen((evento) {
        // Un teléfono quieto siempre mide ~9.8 m/s² de gravedad. La clave
        // es en qué eje aparece: acostado (boca arriba o abajo) domina Z;
        // de pie, mirando a través de la cámara, domina Y.
        final vertical = evento.y.abs() > evento.z.abs();
        ventana.add(vertical);
        if (ventana.length > _muestrasSuavizado) ventana.removeFirst();
        final mayoria = ventana.where((v) => v).length > ventana.length / 2;
        controlador.add(mayoria);
      }, onError: (_) {
        // Dispositivo sin acelerómetro: no bloqueamos la función, se asume
        // vertical para no ocultar la navegación permanentemente.
        controlador.add(true);
      });
    };
    controlador.onCancel = () {
      suscripcion?.cancel();
      suscripcion = null;
    };

    _vertical = controlador.stream;
    return controlador.stream;
  }
}
