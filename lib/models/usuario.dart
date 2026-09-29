enum RolUsuario { usuario, verificador, admin }

RolUsuario rolDesdeTexto(String texto) {
  return RolUsuario.values.firstWhere(
    (r) => r.name == texto,
    orElse: () => RolUsuario.usuario,
  );
}

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final RolUsuario rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  bool get esVerificador => rol == RolUsuario.verificador || rol == RolUsuario.admin;
  bool get esAdmin => rol == RolUsuario.admin;

  factory Usuario.fromMap(Map<String, Object?> mapa) {
    return Usuario(
      id: mapa['id'] as String,
      nombre: mapa['nombre'] as String,
      email: mapa['email'] as String,
      rol: rolDesdeTexto(mapa['rol'] as String),
    );
  }

  String get rolTexto {
    switch (rol) {
      case RolUsuario.admin:
        return 'Administrador';
      case RolUsuario.verificador:
        return 'Verificador';
      case RolUsuario.usuario:
        return 'Usuario';
    }
  }
}
