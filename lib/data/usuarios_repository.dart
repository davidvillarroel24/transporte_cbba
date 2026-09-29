import '../models/usuario.dart';
import 'app_database.dart';

/// Gestión de usuarios y roles, usada por el panel de administración.
class UsuariosRepository {
  UsuariosRepository._();
  static final UsuariosRepository instance = UsuariosRepository._();

  Future<List<Usuario>> listarTodos() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('usuarios', orderBy: 'nombre');
    return filas.map(Usuario.fromMap).toList();
  }

  Future<void> cambiarRol(String usuarioId, RolUsuario nuevoRol) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'usuarios',
      {'rol': nuevoRol.name},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }
}
