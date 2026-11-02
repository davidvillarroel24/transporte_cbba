import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/gtfs_repository.dart';
import '../models/parada.dart';
import '../services/location_service.dart';
import '../services/orientacion_navegacion.dart';
import '../services/orientacion_service.dart';
import '../services/preferencias_ar.dart';
import '../widgets/navegacion_camara/aviso_calibracion.dart';
import '../widgets/navegacion_camara/camara_fondo.dart';
import '../widgets/navegacion_camara/hud_lateral.dart';
import '../widgets/navegacion_camara/luces_pista.dart';
import '../widgets/navegacion_camara/modo_asistente.dart';
import '../widgets/navegacion_camara/pin_destino.dart';

/// Pantalla de navegación asistida por cámara: cámara en vivo + indicadores
/// 2D calculados por GPS y sensores, guiando al usuario hacia el punto de
/// abordaje. No es realidad aumentada completa (no usa ARCore ni
/// reconstruye el entorno); es un asistente aproximado por rumbo en línea
/// recta, según lo acordado para este proyecto.
class NavegacionCamaraScreen extends StatefulWidget {
  final Parada destino;
  final String? shapeId;

  const NavegacionCamaraScreen({super.key, required this.destino, this.shapeId});

  @override
  State<NavegacionCamaraScreen> createState() => _NavegacionCamaraScreenState();
}

class _NavegacionCamaraScreenState extends State<NavegacionCamaraScreen> {
  StreamSubscription<Position>? _subUbicacion;
  StreamSubscription<double>? _subRumbo;
  StreamSubscription<bool>? _subVertical;

  Position? _posicion;
  double? _rumboDispositivo;
  bool _telefonoVertical = true;
  bool _pinVisibleManual = true;

  List<LatLng>? _puntosRuta;
  // Punto de abordaje definitivo: el feed GTFS de Cochabamba no tiene
  // paradas fijas reales (los trufis suben/bajan en cualquier punto de su
  // recorrido), así que en vez de confiar en la coordenada aproximada de
  // "parada", se calcula una sola vez, con la primera ubicación GPS buena,
  // el punto más cercano sobre el trayecto real de la línea a donde estás
  // parado. Queda fijo desde ahí: no se recalcula mientras caminás, para
  // que el objetivo no se deslice por la calle.
  LatLng? _objetivo;

  @override
  void initState() {
    super.initState();
    _cargarPreferenciaPin();
    _cargarRuta();
    _subUbicacion = LocationService.instance.flujoUbicacion().listen((pos) {
      if (!mounted) return;
      setState(() => _posicion = pos);
      _intentarFijarObjetivo();
    });
    _subRumbo = OrientacionService.instance.rumboDispositivo().listen((rumbo) {
      if (mounted) setState(() => _rumboDispositivo = rumbo);
    });
    _subVertical = OrientacionService.instance.telefonoVertical().listen((vertical) {
      if (mounted) setState(() => _telefonoVertical = vertical);
    });
  }

  Future<void> _cargarRuta() async {
    final shapeId = widget.shapeId;
    final puntos = (shapeId != null && shapeId.isNotEmpty)
        ? await GtfsRepository.instance.puntosDeForma(shapeId)
        : const <LatLng>[];
    if (!mounted) return;
    setState(() => _puntosRuta = puntos);
    _intentarFijarObjetivo();
  }

  void _intentarFijarObjetivo() {
    if (_objetivo != null) return;
    final posicion = _posicion;
    final puntosRuta = _puntosRuta;
    if (posicion == null || puntosRuta == null) return;
    final actual = LatLng(posicion.latitude, posicion.longitude);
    final objetivo = puntosRuta.isEmpty
        ? LatLng(widget.destino.lat, widget.destino.lon)
        : puntoMasCercanoEnRuta(puntosRuta, actual);
    setState(() => _objetivo = objetivo);
  }

  Future<void> _cargarPreferenciaPin() async {
    final visible = await PreferenciasAr.instance.pinVisible();
    if (mounted) setState(() => _pinVisibleManual = visible);
  }

  Future<void> _alternarPinVisible() async {
    final nuevo = !_pinVisibleManual;
    await PreferenciasAr.instance.establecerPinVisible(nuevo);
    if (mounted) setState(() => _pinVisibleManual = nuevo);
  }

  @override
  void dispose() {
    _subUbicacion?.cancel();
    _subRumbo?.cancel();
    _subVertical?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final objetivo = _objetivo;
    final posicion = _posicion;
    final rumboDispositivo = _rumboDispositivo;

    double? distanciaMetros;
    double? diferenciaRumbo;
    if (posicion != null && objetivo != null) {
      distanciaMetros = Geolocator.distanceBetween(
        posicion.latitude,
        posicion.longitude,
        objetivo.latitude,
        objetivo.longitude,
      );
      if (rumboDispositivo != null) {
        final rumboObjetivo = rumboHacia(
          LatLng(posicion.latitude, posicion.longitude),
          objetivo,
        );
        diferenciaRumbo = diferenciaAngular(rumboObjetivo, rumboDispositivo);
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const CamaraFondo(),
          if (!_telefonoVertical)
            const _AvisoAcostado()
          else if (distanciaMetros != null && diferenciaRumbo != null) ...[
            if (_pinVisibleManual && pinDebeSerVisible(distanciaMetros, diferenciaRumbo)) ...[
              LucesPista(
                puntoDeFuga: Offset(
                  posicionXPin(MediaQuery.of(context).size.width, diferenciaRumbo),
                  MediaQuery.of(context).size.height / 2,
                ),
              ),
              PinDestino(distanciaMetros: distanciaMetros, diferenciaAngular: diferenciaRumbo),
              Positioned(
                left: 16,
                right: 16,
                bottom: 110,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${distanciaMetros.round()} m · ${widget.destino.nombre}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ] else if (_pinVisibleManual)
              ModoAsistente(diferenciaAngular: diferenciaRumbo),
          ] else
            const Positioned(
              bottom: 110,
              left: 16,
              right: 16,
              child: Center(
                child: Text(
                  'Buscando ubicación y brújula...',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          if (rumboDispositivo != null)
            HudLateral(
              rumboDispositivo: rumboDispositivo,
              destino: objetivo ?? LatLng(widget.destino.lat, widget.destino.lon),
            ),
          const AvisoCalibracion(),
          // Lectura temporal para diagnosticar el reporte de izquierda/derecha
          // invertido: mostrar los valores crudos en vez de adivinar a ciegas.
          if (rumboDispositivo != null && diferenciaRumbo != null)
            Positioned(
              top: 60,
              left: 10,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'rumbo: ${rumboDispositivo.toStringAsFixed(0)}°  '
                    'dif: ${diferenciaRumbo.toStringAsFixed(0)}°',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: _BotonCirculo(
                icono: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: _BotonCirculo(
                icono: _pinVisibleManual ? Icons.visibility : Icons.visibility_off,
                onPressed: _alternarPinVisible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoAcostado extends StatelessWidget {
  const _AvisoAcostado();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_rotation_outlined, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'Levantá el teléfono como si fueras a sacar una foto para ver '
              'la guía hacia la parada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonCirculo extends StatelessWidget {
  final IconData icono;
  final VoidCallback onPressed;

  const _BotonCirculo({required this.icono, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icono, color: Colors.white),
        ),
      ),
    );
  }
}
