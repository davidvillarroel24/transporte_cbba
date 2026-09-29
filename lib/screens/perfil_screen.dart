import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'panel_admin_screen.dart';
import 'panel_verificador_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService.instance.cerrarSesion();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.instance.usuarioActual;
    if (usuario == null) {
      return const Center(child: Text('No hay sesión activa'));
    }

    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final actual = AuthService.instance.usuarioActual ?? usuario;
        return Scaffold(
          appBar: AppBar(title: const Text('Perfil'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.verde.withOpacity(0.15),
                child: Icon(Icons.person, size: 44, color: AppColors.verde),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  actual.nombre,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(actual.email, style: TextStyle(color: AppColors.grisTexto)),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _colorRol(actual.rol).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    actual.rolTexto,
                    style: TextStyle(color: _colorRol(actual.rol), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (actual.esVerificador)
                _OpcionPerfil(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Panel de verificador',
                  subtitulo: 'Revisa y valida los reportes de los usuarios',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PanelVerificadorScreen()),
                  ),
                ),
              if (actual.esAdmin)
                _OpcionPerfil(
                  icono: Icons.admin_panel_settings_outlined,
                  titulo: 'Panel de administración',
                  subtitulo: 'Roles de usuarios y gestión de líneas',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PanelAdminScreen()),
                  ),
                ),
              const SizedBox(height: 10),
              _OpcionPerfil(
                icono: Icons.logout,
                titulo: 'Cerrar sesión',
                subtitulo: null,
                colorTitulo: Colors.red,
                onTap: () => _cerrarSesion(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _colorRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.admin:
        return const Color(0xFF6A1B9A);
      case RolUsuario.verificador:
        return const Color(0xFF1565C0);
      case RolUsuario.usuario:
        return AppColors.verde;
    }
  }
}

class _OpcionPerfil extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Color? colorTitulo;
  final VoidCallback onTap;

  const _OpcionPerfil({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.colorTitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icono, color: colorTitulo),
        title: Text(titulo, style: TextStyle(color: colorTitulo, fontWeight: FontWeight.w600)),
        subtitle: subtitulo == null ? null : Text(subtitulo!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
