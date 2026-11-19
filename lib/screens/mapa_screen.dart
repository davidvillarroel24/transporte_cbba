import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/congestion_escolar_repository.dart';
import '../data/gtfs_repository.dart';
import '../data/horarios_congestion.dart';
import '../data/incidencias_repository.dart';
import '../data/tarifas_repository.dart';
import '../models/colegio_congestion.dart';
import '../models/incidencia.dart';
import '../models/linea.dart';
import '../models/parada.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mapa_en_vivo.dart';
import 'reportar_incidencia_screen.dart';
import 'resultado_ruta_screen.dart';

enum _ModoMapa { normal, seleccionarLineas, buscarRuta }

/// Pestaña "Mapa": mapa real (OpenStreetMap, gratuito) con la ubicación
/// del usuario en vivo, selector de líneas para dibujar sus recorridos,
/// búsqueda de ruta marcando origen/destino con pines, y una capa con los
/// reportes de estado de calles hechos por los usuarios.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final GlobalKey<MapaEnVivoState> _mapaKey = GlobalKey<MapaEnVivoState>();

  _ModoMapa _modo = _ModoMapa.normal;
  final Map<String, (Linea, List<LatLng>)> _lineasDibujadas = {};
  LatLng? _pinOrigen;
  LatLng? _pinDestino;
  List<Incidencia> _incidencias = const [];
  List<ColegioCongestion> _colegios = const [];
  Timer? _timerCongestion;

  @override
  void initState() {
    super.initState();
    _cargarIncidenciasCercanas();
    _cargarColegiosCongestion();
    // Para que el indicador de congestión aparezca/desaparezca solo si la
    // pantalla queda abierta cruzando uno de los horarios (07:00/14:00/19:00).
    _timerCongestion = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _cargarColegiosCongestion() async {
    final colegios = await CongestionEscolarRepository.instance.listarTodos();
    if (mounted) setState(() => _colegios = colegios);
  }

  @override
  void dispose() {
    _timerCongestion?.cancel();
    super.dispose();
  }

  Future<void> _cargarIncidenciasCercanas() async {
    final posicion = await LocationService.instance.ubicacionActual();
    if (posicion == null || !mounted) return;
    final incidencias = await IncidenciasRepository.instance.cercanas(
      posicion.latitude,
      posicion.longitude,
      radioMetros: 3000,
    );
    if (mounted) setState(() => _incidencias = incidencias);
  }

  void _alTocarMapa(LatLng punto) {
    if (_modo != _ModoMapa.buscarRuta) return;
    setState(() {
      if (_pinOrigen == null) {
        _pinOrigen = punto;
      } else if (_pinDestino == null) {
        _pinDestino = punto;
      } else {
        _pinOrigen = punto;
        _pinDestino = null;
      }
    });
  }

  Future<void> _alMantenerPresionado(LatLng punto) async {
    if (AuthService.instance.usuarioActual == null) return;
    final guardado = await mostrarReportarIncidencia(context, lat: punto.latitude, lon: punto.longitude);
    if (guardado == true) _cargarIncidenciasCercanas();
  }

  void _reiniciarPines() {
    setState(() {
      _pinOrigen = null;
      _pinDestino = null;
    });
  }

  Future<void> _verResultadoDePines() async {
    final origen = _pinOrigen;
    final destino = _pinDestino;
    if (origen == null || destino == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadoRutaScreen(
          origen: Parada(id: 'pin_origen', nombre: 'Origen marcado en el mapa', lat: origen.latitude, lon: origen.longitude),
          destino: Parada(id: 'pin_destino', nombre: 'Destino marcado en el mapa', lat: destino.latitude, lon: destino.longitude),
        ),
      ),
    );
  }

  Future<void> _abrirSelectorDeLineas() async {
    final todas = await GtfsRepository.instance.todasLasLineas();
    if (!mounted) return;
    final seleccionadas = Set<String>.from(_lineasDibujadas.keys);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var filtro = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final visibles = filtro.isEmpty
                ? todas
                : todas.where((l) {
                    final texto = '${l.nombreCorto} ${l.nombreLargo}'.toLowerCase();
                    return texto.contains(filtro.toLowerCase());
                  }).toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Elige una o más líneas para ver su recorrido',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar línea por nombre',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setSheetState(() => filtro = v),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: visibles.length,
                          itemBuilder: (context, i) {
                            final linea = visibles[i];
                            final activa = seleccionadas.contains(linea.id);
                            return CheckboxListTile(
                              value: activa,
                              secondary: CircleAvatar(backgroundColor: linea.color, radius: 12),
                              title: Text(linea.nombreCorto),
                              subtitle: linea.nombreLargo.isEmpty ? null : Text(linea.nombreLargo),
                              onChanged: (v) {
                                setSheetState(() {
                                  if (v == true) {
                                    seleccionadas.add(linea.id);
                                  } else {
                                    seleccionadas.remove(linea.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _dibujarLineasSeleccionadas(todas, seleccionadas);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Mostrar en el mapa'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _dibujarLineasSeleccionadas(List<Linea> todas, Set<String> ids) async {
    final nuevas = <String, (Linea, List<LatLng>)>{};
    for (final id in ids) {
      final linea = todas.firstWhere((l) => l.id == id);
      final shapeId = await GtfsRepository.instance.shapeDeLinea(id);
      final puntos = shapeId == null ? <LatLng>[] : await GtfsRepository.instance.puntosDeForma(shapeId);
      if (puntos.isNotEmpty) nuevas[id] = (linea, puntos);
    }
    if (mounted) setState(() => _lineasDibujadas.replace(nuevas));
  }

  void _cambiarModo(_ModoMapa nuevo) {
    setState(() {
      _modo = _modo == nuevo ? _ModoMapa.normal : nuevo;
      if (_modo != _ModoMapa.buscarRuta) {
        _pinOrigen = null;
        _pinDestino = null;
      }
    });
  }

  Future<void> _verIncidencia(Incidencia incidencia) async {
    final usuario = AuthService.instance.usuarioActual;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(incidencia.tipo.icono, color: incidencia.colorEstado),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    incidencia.tipo.etiqueta,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(incidencia.etiquetaConfianza, style: TextStyle(fontSize: 12, color: AppColors.grisTexto)),
            if (incidencia.comentario?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(incidencia.comentario!),
            ],
            const SizedBox(height: 8),
            Text(
              'Reportado por ${incidencia.reportadoPor} · ${incidencia.confirmaciones} confirmaciones',
              style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
            ),
            const SizedBox(height: 16),
            if (usuario != null && incidencia.estado == EstadoIncidencia.noVerificado) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await IncidenciasRepository.instance.confirmar(incidencia.id, usuario.id);
                        if (context.mounted) Navigator.pop(context);
                        _cargarIncidenciasCercanas();
                      },
                      icon: const Icon(Icons.thumb_up_outlined, size: 18),
                      label: const Text('Sigue así'),
                    ),
                  ),
                  if (usuario.esVerificador) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await IncidenciasRepository.instance.cambiarEstado(
                            incidencia.id,
                            EstadoIncidencia.verificado,
                          );
                          if (context.mounted) Navigator.pop(context);
                          _cargarIncidenciasCercanas();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Verificar'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _verColegio(ColegioCongestion colegio) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    colegio.nombre,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (colegio.calle != null) ...[
              const SizedBox(height: 6),
              Text(colegio.calle!, style: TextStyle(color: AppColors.grisTexto)),
            ],
            const SizedBox(height: 12),
            Text(
              'Estimación referencial por horario escolar (ingreso/salida de '
              'estudiantes), no es una medición de tráfico en tiempo real.',
              style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verTarifas() async {
    final tarifas = await TarifasRepository.instance.listarTodas();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarifas de referencia',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Solo informativo, no se gestionan pagos en la app.',
              style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
            ),
            const SizedBox(height: 12),
            ...tarifas.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(t.tipo)),
                      Text(
                        'Bs ${t.precio.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final congestionActiva = hayCongestionActiva(DateTime.now());
    final marcadores = <Marker>[
      for (final incidencia in _incidencias)
        Marker(
          point: LatLng(incidencia.lat, incidencia.lon),
          width: 34,
          height: 34,
          child: GestureDetector(
            onTap: () => _verIncidencia(incidencia),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: incidencia.colorEstado,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(incidencia.tipo.icono, color: Colors.white, size: 18),
            ),
          ),
        ),
      if (_pinOrigen != null)
        Marker(
          point: _pinOrigen!,
          width: 36,
          height: 36,
          child: const Icon(Icons.trip_origin, color: Colors.blue, size: 32),
        ),
      if (_pinDestino != null)
        Marker(
          point: _pinDestino!,
          width: 36,
          height: 36,
          child: const Icon(Icons.location_on, color: Colors.red, size: 36),
        ),
      if (congestionActiva)
        for (final colegio in _colegios)
          Marker(
            point: LatLng(colegio.lat, colegio.lon),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _verColegio(colegio),
              child: const SizedBox.expand(),
            ),
          ),
    ];

    final lineas = <Polyline>[
      for (final entrada in _lineasDibujadas.values)
        Polyline(points: entrada.$2, color: entrada.$1.color, strokeWidth: 4),
    ];

    final circulosCongestion = <CircleMarker>[
      if (congestionActiva)
        for (final colegio in _colegios)
          CircleMarker(
            point: LatLng(colegio.lat, colegio.lon),
            radius: 150,
            useRadiusInMeter: true,
            color: Colors.deepOrange.withOpacity(0.3),
            borderColor: Colors.deepOrange,
            borderStrokeWidth: 2,
          ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          MapaEnVivo(
            key: _mapaKey,
            marcadoresExtra: marcadores,
            lineasExtra: lineas,
            circulosExtra: circulosCongestion,
            alTocar: _alTocarMapa,
            alMantenerPresionado: _alMantenerPresionado,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                color: AppColors.blanco,
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _verTarifas,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.monetization_on, color: AppColors.primario, size: 24),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(Icons.help, color: AppColors.primario, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_modo == _ModoMapa.buscarRuta)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pinOrigen == null
                            ? 'Toca el mapa para marcar el origen'
                            : _pinDestino == null
                                ? 'Ahora toca el mapa para marcar el destino'
                                : 'Listo. Busca la ruta o vuelve a tocar para reiniciar.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (_pinOrigen != null || _pinDestino != null)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _reiniciarPines,
                      ),
                  ],
                ),
              ),
            ),
          if (_pinOrigen != null && _pinDestino != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 90,
              child: ElevatedButton.icon(
                onPressed: _verResultadoDePines,
                icon: const Icon(Icons.route),
                label: const Text('Buscar ruta entre estos puntos'),
              ),
            ),
          Positioned(
            left: 12,
            bottom: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'lineas',
                  backgroundColor: _modo == _ModoMapa.seleccionarLineas ? AppColors.primario : AppColors.blanco,
                  onPressed: () {
                    _cambiarModo(_ModoMapa.seleccionarLineas);
                    _abrirSelectorDeLineas();
                  },
                  child: Icon(
                    Icons.alt_route,
                    color: _modo == _ModoMapa.seleccionarLineas ? Colors.white : AppColors.primario,
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'buscar',
                  backgroundColor: _modo == _ModoMapa.buscarRuta ? AppColors.primario : AppColors.blanco,
                  onPressed: () => _cambiarModo(_ModoMapa.buscarRuta),
                  child: Icon(
                    Icons.pin_drop_outlined,
                    color: _modo == _ModoMapa.buscarRuta ? Colors.white : AppColors.primario,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'centrar',
              backgroundColor: AppColors.primario,
              onPressed: () => _mapaKey.currentState?.centrarEnMiUbicacion(),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Map<String, (Linea, List<LatLng>)> {
  void replace(Map<String, (Linea, List<LatLng>)> nuevo) {
    clear();
    addAll(nuevo);
  }
}
