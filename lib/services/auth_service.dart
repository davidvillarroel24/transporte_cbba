import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../models/usuario.dart';

class CredencialesInvalidas implements Exception {
  final String mensaje;
  CredencialesInvalidas(this.mensaje);
  @override
  String toString() => mensaje;
}

/// Cuentas locales: todo vive en la misma base SQLite del teléfono. Sirve
/// para probar el flujo de roles cambiando de cuenta en el mismo
/// dispositivo; no es un backend compartido entre dispositivos distintos
/// (eso queda para una etapa posterior con un servidor real).
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _admEmail = 'admin@transporte.com';
  static const _admPassword = '12345678';
  static const _claveSesion = 'sesion_usuario_id';
  final _uuid = const Uuid();

  Usuario? usuarioActual;

  bool get haySesion => usuarioActual != null;

  Future<void> inicializar() async {
    await _asegurarAdminSemilla();
    await _cargarSesionGuardada();
  }

  (String, String) _hashear(String password, [String? saltExistente]) {
    final salt = saltExistente ?? _generarSalt();
    final bytes = utf8.encode('$salt:$password');
    return (sha256.convert(bytes).toString(), salt);
  }

  String _generarSalt() {
    final aleatorio = Random.secure();
    final bytes = List<int>.generate(16, (_) => aleatorio.nextInt(256));
    return base64Url.encode(bytes);
  }

  Future<void> _asegurarAdminSemilla() async {
    final db = await AppDatabase.instance.database;
    final existente = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [_admEmail],
    );
    if (existente.isNotEmpty) return;

    final (hash, salt) = _hashear(_admPassword);
    await db.insert('usuarios', {
      'id': _uuid.v4(),
      'nombre': 'Administrador',
      'email': _admEmail,
      'password_hash': hash,
      'password_salt': salt,
      'rol': RolUsuario.admin.name,
      'creado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _cargarSesionGuardada() async {
    final db = await AppDatabase.instance.database;
    final meta = await db.query('meta', where: 'clave = ?', whereArgs: [_claveSesion]);
    if (meta.isEmpty) return;
    final id = meta.first['valor'] as String?;
    if (id == null) return;
    final filas = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    if (filas.isNotEmpty) {
      usuarioActual = Usuario.fromMap(filas.first);
      notifyListeners();
    }
  }

  Future<void> _guardarSesion(String? usuarioId) async {
    final db = await AppDatabase.instance.database;
    if (usuarioId == null) {
      await db.delete('meta', where: 'clave = ?', whereArgs: [_claveSesion]);
    } else {
      await db.insert(
        'meta',
        {'clave': _claveSesion, 'valor': usuarioId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final correo = email.trim().toLowerCase();
    if (nombre.trim().isEmpty || correo.isEmpty || password.length < 6) {
      throw CredencialesInvalidas(
        'Completa tu nombre, un correo válido y una contraseña de al menos 6 caracteres.',
      );
    }
    final db = await AppDatabase.instance.database;
    final existente = await db.query('usuarios', where: 'email = ?', whereArgs: [correo]);
    if (existente.isNotEmpty) {
      throw CredencialesInvalidas('Ya existe una cuenta registrada con ese correo.');
    }

    final (hash, salt) = _hashear(password);
    final id = _uuid.v4();
    await db.insert('usuarios', {
      'id': id,
      'nombre': nombre.trim(),
      'email': correo,
      'password_hash': hash,
      'password_salt': salt,
      'rol': RolUsuario.usuario.name,
      'creado_en': DateTime.now().toIso8601String(),
    });

    final usuario = Usuario(id: id, nombre: nombre.trim(), email: correo, rol: RolUsuario.usuario);
    usuarioActual = usuario;
    await _guardarSesion(id);
    notifyListeners();
    return usuario;
  }

  Future<Usuario> iniciarSesion({required String email, required String password}) async {
    final correo = email.trim().toLowerCase();
    final db = await AppDatabase.instance.database;
    final filas = await db.query('usuarios', where: 'email = ?', whereArgs: [correo]);
    if (filas.isEmpty) {
      throw CredencialesInvalidas('No existe una cuenta con ese correo.');
    }
    final fila = filas.first;
    final (hashIngresado, _) = _hashear(password, fila['password_salt'] as String);
    if (hashIngresado != fila['password_hash']) {
      throw CredencialesInvalidas('La contraseña no es correcta.');
    }
    final usuario = Usuario.fromMap(fila);
    usuarioActual = usuario;
    await _guardarSesion(usuario.id);
    notifyListeners();
    return usuario;
  }

  Future<void> cerrarSesion() async {
    usuarioActual = null;
    await _guardarSesion(null);
    notifyListeners();
  }

  /// Refresca el usuario en sesión (por ejemplo tras un cambio de rol).
  Future<void> refrescarSesion() async {
    final actual = usuarioActual;
    if (actual == null) return;
    final db = await AppDatabase.instance.database;
    final filas = await db.query('usuarios', where: 'id = ?', whereArgs: [actual.id]);
    if (filas.isNotEmpty) {
      usuarioActual = Usuario.fromMap(filas.first);
      notifyListeners();
    }
  }
}
