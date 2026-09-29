import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/incidencia.dart';
import 'app_database.dart';

/// Reportes de estado de calles hechos por los usuarios (calle bloqueada,
/// mantenimiento, árbol caído, cables, fuga de gas, congestionamiento).
/// Quedan visibles para cualquier cuenta del mismo dispositivo hasta que
/// un verificador los valida o los descarta.
class IncidenciasRepository {
  IncidenciasRepository._();
  static final IncidenciasRepository instance = IncidenciasRepository._();

  final _uuid = const Uuid();

  static const _selectBase = '''
    SELECT i.id, i.tipo, i.lat, i.lon, i.comentario, i.estado, i.usuario_id,
           i.creado_en, u.nombre AS reportado_por,
           (SELECT COUNT(*) FROM incidencia_confirmaciones c WHERE c.incidencia_id = i.id) AS confirmaciones
    FROM incidencias i
    LEFT JOIN usuarios u ON u.id = i.usuario_id
  ''';

  Incidencia _desdeFila(Map<String, Object?> f) {
    return Incidencia(
      id: f['id'] as String,
      tipo: tipoIncidenciaDesdeTexto(f['tipo'] as String),
      lat: f['lat'] as double,
      lon: f['lon'] as double,
      comentario: f['comentario'] as String?,
      estado: estadoIncidenciaDesdeTexto(f['estado'] as String),
      usuarioId: f['usuario_id'] as String,
      reportadoPor: (f['reportado_por'] as String?) ?? 'Usuario',
      confirmaciones: (f['confirmaciones'] as int?) ?? 0,
      creadoEn: DateTime.tryParse(f['creado_en'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Future<List<Incidencia>> cercanas(
    double lat,
    double lon, {
    double radioMetros = 1500,
    bool incluirDescartadas = false,
  }) async {
    final deltaGrados = radioMetros / 100000.0;
    final db = await AppDatabase.instance.database;
    final condicionEstado = incluirDescartadas ? '' : "AND i.estado != 'descartado'";
    final filas = await db.rawQuery('''
      $_selectBase
      WHERE i.lat BETWEEN ? AND ? AND i.lon BETWEEN ? AND ?
      $condicionEstado
      ORDER BY i.creado_en DESC
    ''', [lat - deltaGrados, lat + deltaGrados, lon - deltaGrados, lon + deltaGrados]);
    return filas.map(_desdeFila).toList();
  }

  Future<List<Incidencia>> pendientes() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.rawQuery('''
      $_selectBase
      WHERE i.estado = 'noVerificado'
      ORDER BY confirmaciones DESC, i.creado_en ASC
    ''');
    return filas.map(_desdeFila).toList();
  }

  Future<void> crear({
    required TipoIncidencia tipo,
    required double lat,
    required double lon,
    String? comentario,
    required String usuarioId,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert('incidencias', {
      'id': _uuid.v4(),
      'tipo': tipo.name,
      'lat': lat,
      'lon': lon,
      'comentario': comentario,
      'estado': EstadoIncidencia.noVerificado.name,
      'usuario_id': usuarioId,
      'creado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<void> confirmar(String incidenciaId, String usuarioId) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'incidencia_confirmaciones',
      {'incidencia_id': incidenciaId, 'usuario_id': usuarioId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> cambiarEstado(String incidenciaId, EstadoIncidencia estado) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'incidencias',
      {'estado': estado.name},
      where: 'id = ?',
      whereArgs: [incidenciaId],
    );
  }
}
