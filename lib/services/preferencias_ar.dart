import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';

/// Preferencias chicas de la navegación asistida por cámara, guardadas en
/// la misma tabla `meta` que ya usa la sesión del usuario (sin tablas
/// nuevas): si el aviso de calibración de brújula sigue mostrándose, y si
/// el usuario ocultó el pin manualmente.
class PreferenciasAr {
  PreferenciasAr._();
  static final PreferenciasAr instance = PreferenciasAr._();

  static const _claveCalibracionOculta = 'ar_calibracion_oculta';
  static const _clavePinVisible = 'ar_pin_visible';

  Future<bool> _leerBooleano(String clave, {required bool porDefecto}) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('meta', where: 'clave = ?', whereArgs: [clave]);
    if (filas.isEmpty) return porDefecto;
    return filas.first['valor'] == '1';
  }

  Future<void> _guardarBooleano(String clave, bool valor) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'meta',
      {'clave': clave, 'valor': valor ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> calibracionOculta() => _leerBooleano(_claveCalibracionOculta, porDefecto: false);

  Future<void> ocultarCalibracion() => _guardarBooleano(_claveCalibracionOculta, true);

  Future<bool> pinVisible() => _leerBooleano(_clavePinVisible, porDefecto: true);

  Future<void> establecerPinVisible(bool visible) => _guardarBooleano(_clavePinVisible, visible);
}
