import 'package:flutter/material.dart';

import '../models/parada.dart';
import 'buscador_lugar.dart';

/// Buscador de destino en la pantalla de inicio: muestra sugerencias en
/// vivo a medida que se escribe (paradas, favoritos, lugares turísticos y
/// direcciones reales). Elegir una sugerencia va directo a buscar la ruta;
/// el botón de abajo también permite entrar a la búsqueda completa sin
/// haber elegido nada todavía.
class BusquedaDestino extends StatelessWidget {
  final VoidCallback alBuscar;
  final ValueChanged<Parada> alSeleccionarDestino;

  const BusquedaDestino({
    super.key,
    required this.alBuscar,
    required this.alSeleccionarDestino,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BuscadorLugar(onSeleccionar: alSeleccionarDestino),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: alBuscar,
            icon: const Icon(Icons.route),
            label: const Text("Buscar ruta"),
          ),
        ),
      ],
    );
  }
}
