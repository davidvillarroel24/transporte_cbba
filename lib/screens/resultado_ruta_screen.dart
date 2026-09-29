import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/favoritos_repository.dart';
import '../data/gtfs_repository.dart';
import '../models/parada.dart';
import '../models/resultado_ruta.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mapa_en_vivo.dart';

class ResultadoRutaScreen extends StatefulWidget {
  final Parada origen;
  final Parada destino;

  const ResultadoRutaScreen({
    super.key,
    required this.origen,
    required this.destino,
  });

  @override
  State<ResultadoRutaScreen> createState() => _ResultadoRutaScreenState();
}

class _ResultadoRutaScreenState extends State<ResultadoRutaScreen> {
  late Future<List<ResultadoRuta>> _resultados;

  @override
  void initState() {
    super.initState();
    _resultados = GtfsRepository.instance.buscarRutas(
      origen: widget.origen,
      destino: widget.destino,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultados de ruta"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ResultadoRuta>>(
        future: _resultados,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final resultados = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Destino:\n📍 ${widget.destino.nombre}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _BotonGuardarFavorito(destino: widget.destino),
                  ],
                ),
              ),
              Expanded(
                child: resultados.isEmpty
                    ? _SinResultados(destino: widget.destino)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 200,
                              child: _MapaResultado(
                                origen: widget.origen,
                                destino: widget.destino,
                                resultados: resultados,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Opciones disponibles",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          ...resultados.map((r) => RutaCard(resultado: r)),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  final Parada destino;

  const _SinResultados({required this.destino});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_filled_outlined, size: 60, color: AppColors.grisTexto),
            const SizedBox(height: 16),
            Text(
              "No se encontró una línea directa entre tu ubicación y "
              "${destino.nombre} en los datos disponibles.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisTexto),
            ),
            const SizedBox(height: 8),
            Text(
              "Puede que el trayecto requiera combinar dos líneas.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisTexto, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapaResultado extends StatefulWidget {
  final Parada origen;
  final Parada destino;
  final List<ResultadoRuta> resultados;

  const _MapaResultado({
    required this.origen,
    required this.destino,
    required this.resultados,
  });

  @override
  State<_MapaResultado> createState() => _MapaResultadoState();
}

class _MapaResultadoState extends State<_MapaResultado> {
  late Future<List<Polyline>> _lineas;

  @override
  void initState() {
    super.initState();
    _lineas = _cargarLineas();
  }

  Future<List<Polyline>> _cargarLineas() async {
    final lineas = <Polyline>[];
    for (final resultado in widget.resultados.take(3)) {
      final shapeId = resultado.shapeId;
      if (shapeId == null || shapeId.isEmpty) continue;
      final puntos = await GtfsRepository.instance.puntosDeForma(shapeId);
      if (puntos.isEmpty) continue;
      lineas.add(Polyline(points: puntos, color: resultado.linea.color, strokeWidth: 4));
    }
    return lineas;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Polyline>>(
      future: _lineas,
      builder: (context, snapshot) {
        final marcadores = [
          Marker(
            point: LatLng(widget.destino.lat, widget.destino.lon),
            width: 34,
            height: 34,
            child: const Icon(Icons.location_on, color: Colors.red, size: 34),
          ),
        ];
        return MapaEnVivo(
          centroInicial: LatLng(widget.origen.lat, widget.origen.lon),
          marcadoresExtra: marcadores,
          lineasExtra: snapshot.data ?? const [],
        );
      },
    );
  }
}

class _BotonGuardarFavorito extends StatefulWidget {
  final Parada destino;

  const _BotonGuardarFavorito({required this.destino});

  @override
  State<_BotonGuardarFavorito> createState() => _BotonGuardarFavoritoState();
}

class _BotonGuardarFavoritoState extends State<_BotonGuardarFavorito> {
  bool _guardado = false;
  bool _guardando = false;

  Future<void> _guardar() async {
    final usuario = AuthService.instance.usuarioActual;
    if (usuario == null || _guardado || _guardando) return;
    setState(() => _guardando = true);
    await FavoritosRepository.instance.agregar(
      usuarioId: usuario.id,
      nombre: widget.destino.nombre,
      lat: widget.destino.lat,
      lon: widget.destino.lon,
    );
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _guardado = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agregado a tus favoritos')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _guardando ? null : _guardar,
      icon: Icon(
        _guardado ? Icons.favorite : Icons.favorite_border,
        color: _guardado ? Colors.red : AppColors.grisTexto,
      ),
      tooltip: 'Guardar como favorito',
    );
  }
}

class RutaCard extends StatelessWidget {
  final ResultadoRuta resultado;

  const RutaCard({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final linea = resultado.linea;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: linea.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_bus, color: linea.color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linea.nombreCorto,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (linea.nombreLargo.isNotEmpty)
                  Text(
                    linea.nombreLargo,
                    style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
                  ),
                const SizedBox(height: 5),
                Text("Tiempo estimado: ${resultado.tiempoMinutos} min aprox."),
                Text("Tarifa: ${resultado.tarifaTexto}"),
                Text(
                  "Sube en: ${resultado.paradaOrigen.nombre}",
                  style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
                ),
                Text(
                  "Baja en: ${resultado.paradaDestino.nombre}",
                  style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
