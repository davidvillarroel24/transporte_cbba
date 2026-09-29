import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Correcciones que el admin aplica sobre una línea del GTFS importado
/// (nombre corto, color, o desactivarla), sin modificar los datos
/// originales importados. GtfsRepository las aplica al armar cada Linea.
class LineasAdminRepository {
  LineasAdminRepository._();
  static final LineasAdminRepository instance = LineasAdminRepository._();

  Future<Map<String, Object?>?> overrideDe(String rutaId) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'lineas_override',
      where: 'ruta_id = ?',
      whereArgs: [rutaId],
    );
    return filas.isEmpty ? null : filas.first;
  }

  Future<Set<String>> idsDesactivadas() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'lineas_override',
      where: 'activa = 0',
      columns: ['ruta_id'],
    );
    return filas.map((f) => f['ruta_id'] as String).toSet();
  }

  Future<void> guardar({
    required String rutaId,
    String? nombreCorto,
    String? color,
    required bool activa,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'lineas_override',
      {
        'ruta_id': rutaId,
        'nombre_corto': nombreCorto,
        'color': color,
        'activa': activa ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
