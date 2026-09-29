import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

/// Mapa gratuito (teselas de OpenStreetMap, sin API key) con un punto
/// que sigue la ubicación real del usuario en vivo. Puede recibir
/// marcadores y polilíneas adicionales para dibujar paradas y recorridos
/// de líneas reales del GTFS.
class MapaEnVivo extends StatefulWidget {
  final List<Marker> marcadoresExtra;
  final List<Polyline> lineasExtra;
  final bool interactivo;
  final LatLng centroInicial;
  final double zoomInicial;
  final void Function(LatLng punto)? alTocar;
  final void Function(LatLng punto)? alMantenerPresionado;

  const MapaEnVivo({
    super.key,
    this.marcadoresExtra = const [],
    this.lineasExtra = const [],
    this.interactivo = true,
    this.centroInicial = const LatLng(-17.3895, -66.1568),
    this.zoomInicial = 14,
    this.alTocar,
    this.alMantenerPresionado,
  });

  @override
  State<MapaEnVivo> createState() => MapaEnVivoState();
}

class MapaEnVivoState extends State<MapaEnVivo> {
  final MapController _controlador = MapController();
  StreamSubscription<Position>? _suscripcion;
  Position? _posicion;
  bool _yaCentrado = false;
  bool _sinPermiso = false;

  @override
  void initState() {
    super.initState();
    _iniciarUbicacion();
  }

  Future<void> _iniciarUbicacion() async {
    final actual = await LocationService.instance.ubicacionActual();
    if (!mounted) return;
    if (actual == null) {
      setState(() => _sinPermiso = true);
    } else {
      setState(() => _posicion = actual);
      centrarEnMiUbicacion();
    }

    _suscripcion = LocationService.instance.flujoUbicacion().listen((pos) {
      if (!mounted) return;
      setState(() {
        _posicion = pos;
        _sinPermiso = false;
      });
      if (!_yaCentrado) centrarEnMiUbicacion();
    });
  }

  void centrarEnMiUbicacion() {
    final pos = _posicion;
    if (pos == null) return;
    _yaCentrado = true;
    _controlador.move(LatLng(pos.latitude, pos.longitude), widget.zoomInicial);
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marcadores = <Marker>[...widget.marcadoresExtra];
    final pos = _posicion;
    if (pos != null) {
      marcadores.add(
        Marker(
          point: LatLng(pos.latitude, pos.longitude),
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCenter: pos != null
                ? LatLng(pos.latitude, pos.longitude)
                : widget.centroInicial,
            initialZoom: widget.zoomInicial,
            interactionOptions: InteractionOptions(
              flags: widget.interactivo
                  ? InteractiveFlag.all
                  : InteractiveFlag.none,
            ),
            onTap: widget.alTocar == null ? null : (_, punto) => widget.alTocar!(punto),
            onLongPress: widget.alMantenerPresionado == null
                ? null
                : (_, punto) => widget.alMantenerPresionado!(punto),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'bo.maestrito.transporte',
            ),
            if (widget.lineasExtra.isNotEmpty)
              PolylineLayer(polylines: widget.lineasExtra),
            MarkerLayer(markers: marcadores),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (_sinPermiso)
          Positioned(
            left: 10,
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Activa la ubicación para verte en el mapa',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
