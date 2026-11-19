import 'package:flutter/material.dart';

import '../data/gtfs_repository.dart';
import '../data/lugares_conocidos.dart';
import '../models/parada.dart';
import '../services/location_service.dart';
import '../widgets/buscador_lugar.dart';
import '../widgets/destino_card.dart';
import 'elegir_punto_mapa_screen.dart';
import 'resultado_ruta_screen.dart';

/// Pantalla de búsqueda: origen y destino editables, cada uno con
/// autocompletado (paradas, favoritos, lugares turísticos, direcciones
/// reales) o eligiendo un punto tocando el mapa — estilo Trufi/Yandex.
class BuscarRutaScreen extends StatefulWidget {
  final Parada? destinoInicial;

  const BuscarRutaScreen({super.key, this.destinoInicial});

  @override
  State<BuscarRutaScreen> createState() => _BuscarRutaScreenState();
}

class _BuscarRutaScreenState extends State<BuscarRutaScreen> {
  final TextEditingController _controladorOrigen = TextEditingController();
  final TextEditingController _controladorDestino = TextEditingController();

  Parada? _origen;
  Parada? _destino;
  bool _buscandoUbicacion = true;
  final List<(LugarConocido, Parada?)> _destinosFrecuentes = [];

  @override
  void initState() {
    super.initState();
    _destino = widget.destinoInicial;
    if (widget.destinoInicial != null) {
      _controladorDestino.text = widget.destinoInicial!.nombre;
    }
    _cargarUbicacion();
    _cargarDestinosFrecuentes();
  }

  Future<void> _cargarUbicacion() async {
    final pos = await LocationService.instance.ubicacionActual();
    if (!mounted) return;
    setState(() {
      _buscandoUbicacion = false;
      if (pos != null) {
        _origen = Parada(
          id: 'ubicacion_actual',
          nombre: 'Mi ubicación actual',
          lat: pos.latitude,
          lon: pos.longitude,
        );
        _controladorOrigen.text = _origen!.nombre;
      }
    });
  }

  Future<void> _cargarDestinosFrecuentes() async {
    final repo = GtfsRepository.instance;
    for (final lugar in lugaresConocidos) {
      var cercanas = await repo.paradasCercanas(lugar.lat, lugar.lon, radioMetros: 400, limite: 1);
      if (cercanas.isEmpty) {
        cercanas = await repo.paradasCercanas(lugar.lat, lugar.lon, radioMetros: 1500, limite: 1);
      }
      _destinosFrecuentes.add((lugar, cercanas.isEmpty ? null : cercanas.first));
    }
    if (mounted) setState(() {});
  }

  void _seleccionarDestino(Parada parada) {
    setState(() {
      _destino = parada;
      _controladorDestino.text = parada.nombre;
    });
  }

  void _seleccionarOrigen(Parada parada) {
    setState(() {
      _origen = parada;
      _controladorOrigen.text = parada.nombre;
    });
  }

  Future<void> _elegirEnMapa({required bool esOrigen}) async {
    final resultado = await Navigator.push<Parada>(
      context,
      MaterialPageRoute(
        builder: (context) => ElegirPuntoMapaScreen(
          titulo: esOrigen ? 'Marca tu punto de partida' : 'Marca tu destino',
        ),
      ),
    );
    if (resultado == null) return;
    if (esOrigen) {
      _seleccionarOrigen(resultado);
    } else {
      _seleccionarDestino(resultado);
    }
  }

  void _buscarRuta() {
    final origen = _origen;
    final destino = _destino;
    if (origen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí un punto de partida primero')),
      );
      return;
    }
    if (destino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí un destino primero')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadoRutaScreen(origen: origen, destino: destino),
      ),
    );
  }

  @override
  void dispose() {
    _controladorOrigen.dispose();
    _controladorDestino.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar ruta"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "¿Dónde estás?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_buscandoUbicacion)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.map_outlined),
                    tooltip: 'Elegir en el mapa',
                    onPressed: () => _elegirEnMapa(esOrigen: true),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            BuscadorLugar(
              hintText: 'Tu ubicación o una dirección',
              controller: _controladorOrigen,
              onSeleccionar: _seleccionarOrigen,
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "¿A dónde quieres ir?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: 'Elegir en el mapa',
                  onPressed: () => _elegirEnMapa(esOrigen: false),
                ),
              ],
            ),
            const SizedBox(height: 10),
            BuscadorLugar(
              hintText: 'Escribe una calle o punto de referencia',
              controller: _controladorDestino,
              onSeleccionar: _seleccionarDestino,
            ),
            const SizedBox(height: 20),
            const Text(
              "Favoritos",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ..._destinosFrecuentes.map((entrada) {
              final (lugar, parada) = entrada;
              return DestinoCard(
                nombre: lugar.nombre,
                alSeleccionar: parada == null ? () {} : () => _seleccionarDestino(parada),
              );
            }),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _buscarRuta,
                icon: const Icon(Icons.route),
                label: const Text("Buscar ruta"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
