import 'package:flutter/material.dart';

import '../../services/preferencias_ar.dart';

/// Banner que recuerda calibrar la brújula (gesto de figura en 8), con un
/// botón para dejar de mostrarlo. Aparece cada vez que se entra a la vista
/// a menos que el usuario haya tocado "no volver a mostrar" antes.
class AvisoCalibracion extends StatefulWidget {
  const AvisoCalibracion({super.key});

  @override
  State<AvisoCalibracion> createState() => _AvisoCalibracionState();
}

class _AvisoCalibracionState extends State<AvisoCalibracion> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _revisar();
  }

  Future<void> _revisar() async {
    final oculto = await PreferenciasAr.instance.calibracionOculta();
    if (mounted && !oculto) setState(() => _visible = true);
  }

  Future<void> _dejarDeMostrar() async {
    await PreferenciasAr.instance.ocultarCalibracion();
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 86, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.explore_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Si la dirección se ve rara, calibra la brújula moviendo el '
                'teléfono en forma de 8.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _visible = false),
              child: const Text('Cerrar', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            TextButton(
              onPressed: _dejarDeMostrar,
              child: const Text('No volver a mostrar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
