import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../mapa_en_vivo.dart';

/// Brújula (esquina superior derecha) y minimapa (esquina inferior
/// izquierda), colapsables con un botón a una regla horizontal de rumbo
/// arriba, estilo HUD de videojuego, para que la vista de cámara no se
/// sienta recargada.
class HudLateral extends StatefulWidget {
  final double rumboDispositivo;
  final LatLng destino;

  const HudLateral({
    super.key,
    required this.rumboDispositivo,
    required this.destino,
  });

  @override
  State<HudLateral> createState() => _HudLateralState();
}

class _HudLateralState extends State<HudLateral> {
  bool _colapsado = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _colapsado
                ? _ReglaRumbo(rumbo: widget.rumboDispositivo)
                : Align(
                    alignment: Alignment.topRight,
                    child: _Brujula(rumbo: widget.rumboDispositivo),
                  ),
          ),
        ),
        if (!_colapsado)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: _Minimapa(destino: widget.destino),
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.topCenter,
              child: _BotonColapsar(
                colapsado: _colapsado,
                onPressed: () => setState(() => _colapsado = !_colapsado),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonColapsar extends StatelessWidget {
  final bool colapsado;
  final VoidCallback onPressed;

  const _BotonColapsar({required this.colapsado, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Icon(
            colapsado ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _Brujula extends StatelessWidget {
  final double rumbo;

  const _Brujula({required this.rumbo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('N', style: TextStyle(color: Colors.white70, fontSize: 10)),
          Transform.rotate(
            // La aguja apunta siempre al norte real, independientemente de
            // hacia dónde gire el teléfono.
            angle: -rumbo * math.pi / 180,
            child: const Icon(Icons.navigation, color: Colors.redAccent, size: 30),
          ),
        ],
      ),
    );
  }
}

/// Regla horizontal de rumbo (estilo "cinta" de un HUD de videojuego): el
/// centro siempre representa hacia dónde apunta el teléfono, con las
/// direcciones cardinales deslizándose a los costados a medida que uno
/// gira. Reemplaza a la brújula y el minimapa cuando están colapsados.
class _ReglaRumbo extends StatelessWidget {
  final double rumbo;

  const _ReglaRumbo({required this.rumbo});

  static const _pixelesPorGrado = 4.0;
  static const _marcas = <(double, String)>[
    (0, 'N'), (45, 'NE'), (90, 'E'), (135, 'SE'),
    (180, 'S'), (225, 'SW'), (270, 'W'), (315, 'NW'),
  ];

  double _diferenciaCiclica(double angulo) {
    var d = (angulo - rumbo) % 360;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width - 20;
    return Container(
      height: 34,
      width: ancho,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final (angulo, etiqueta) in _marcas)
              if (_diferenciaCiclica(angulo).abs() <= 95)
                Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: Offset(_diferenciaCiclica(angulo) * _pixelesPorGrado, 0),
                    child: Text(
                      etiqueta,
                      style: TextStyle(
                        color: etiqueta == 'N' ? Colors.redAccent : Colors.white70,
                        fontWeight: etiqueta.length == 1 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            const Align(
              alignment: Alignment.topCenter,
              child: Icon(Icons.arrow_drop_down, color: Colors.amberAccent, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _Minimapa extends StatelessWidget {
  final LatLng destino;

  const _Minimapa({required this.destino});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 90,
        height: 90,
        child: IgnorePointer(
          child: MapaEnVivo(
            interactivo: false,
            zoomInicial: 16,
            marcadoresExtra: [
              Marker(
                point: destino,
                width: 20,
                height: 20,
                child: const Icon(Icons.location_on, color: Colors.red, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
