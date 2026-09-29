import 'package:flutter/material.dart';

import '../data/gtfs_importer.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _etapa = 'Preparando...';
  double _fraccion = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await GtfsImporter.importarSiHaceFalta(
      onProgreso: (etapa, fraccion) {
        if (!mounted) return;
        setState(() {
          _etapa = etapa;
          _fraccion = fraccion;
        });
      },
    );

    setState(() => _etapa = 'Cargando tu sesión');
    await AuthService.instance.inicializar();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AuthService.instance.haySesion
            ? const MainNavigation()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F2F2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_maestrito.png',
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                "Maestrito",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Transporte público\nCochabamba",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _fraccion > 0 ? _fraccion : null,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _etapa,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
