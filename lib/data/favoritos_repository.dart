import 'package:uuid/uuid.dart';

import '../models/favorito.dart';
import 'app_database.dart';

class FavoritosRepository {
  FavoritosRepository._();
  static final FavoritosRepository instance = FavoritosRepository._();

  final _uuid = const Uuid();

  Future<List<Favorito>> deUsuario(String usuarioId) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'favoritos',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'creado_en DESC',
    );
    return filas.map(Favorito.fromMap).toList();
  }

  Future<void> agregar({
    required String usuarioId,
    required String nombre,
    required double lat,
    required double lon,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert('favoritos', {
      'id': _uuid.v4(),
      'usuario_id': usuarioId,
      'nombre': nombre,
      'lat': lat,
      'lon': lon,
      'creado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<void> quitar(String favoritoId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('favoritos', where: 'id = ?', whereArgs: [favoritoId]);
  }
}
