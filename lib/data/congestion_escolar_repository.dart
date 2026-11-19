import 'package:uuid/uuid.dart';

import '../models/colegio_congestion.dart';
import 'app_database.dart';

/// Colegios usados como focos de congestión vehicular en el mapa (ver
/// `lib/data/horarios_congestion.dart` para las franjas horarias en que se
/// muestran). Editable desde el panel de administrador: la coordenada se
/// marca tocando el mapa, no se escribe a mano.
class CongestionEscolarRepository {
  CongestionEscolarRepository._();
  static final CongestionEscolarRepository instance = CongestionEscolarRepository._();

  final _uuid = const Uuid();

  Future<List<ColegioCongestion>> listarTodos() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('congestion_escolar', orderBy: 'nombre');
    return filas.map(ColegioCongestion.fromMap).toList();
  }

  Future<void> agregar({
    required String nombre,
    String? calle,
    required double lat,
    required double lon,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert('congestion_escolar', {
      'id': _uuid.v4(),
      'nombre': nombre,
      'calle': calle,
      'lat': lat,
      'lon': lon,
    });
  }

  Future<void> editar({required String id, required String nombre, String? calle}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'congestion_escolar',
      {'nombre': nombre, 'calle': calle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> eliminar(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('congestion_escolar', where: 'id = ?', whereArgs: [id]);
  }
}
