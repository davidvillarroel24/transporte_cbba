import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/parada.dart';
import '../services/geocodificacion_service.dart';
import '../widgets/mapa_en_vivo.dart';

/// Pantalla simple: tocar un punto del mapa y confirmarlo. Devuelve una
/// [Parada] (vía Navigator.pop) con el nombre resuelto por geocodificación
/// inversa, o un nombre genérico si la resolución falla o no hay internet.
class ElegirPuntoMapaScreen extends StatefulWidget {
  final String titulo;

  const ElegirPuntoMapaScreen({super.key, required this.titulo});

  @override
  State<ElegirPuntoMapaScreen> createState() => _ElegirPuntoMapaScreenState();
}

class _ElegirPuntoMapaScreenState extends State<ElegirPuntoMapaScreen> {
  LatLng? _punto;
  bool _confirmando = false;

  Future<void> _confirmar() async {
    final punto = _punto;
    if (punto == null) return;
    setState(() => _confirmando = true);
    final nombre = await GeocodificacionService.instance.nombrePara(punto.latitude, punto.longitude);
    if (!mounted) return;
    Navigator.pop(
      context,
      Parada(
        id: 'mapa_punto',
        nombre: nombre ?? 'Punto marcado en el mapa',
        lat: punto.latitude,
        lon: punto.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo), centerTitle: true),
      body: Stack(
        children: [
          MapaEnVivo(
            marcadoresExtra: _punto == null
                ? const []
                : [
                    Marker(
                      point: _punto!,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                    ),
                  ],
            alTocar: (punto) => setState(() => _punto = punto),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Text(
                _punto == null ? 'Toca el mapa para marcar el punto' : 'Punto marcado. Confirmá abajo.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          if (_punto != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: ElevatedButton.icon(
                onPressed: _confirmando ? null : _confirmar,
                icon: _confirmando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: const Text('Confirmar este punto'),
              ),
            ),
        ],
      ),
    );
  }
}
