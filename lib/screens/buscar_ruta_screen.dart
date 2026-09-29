import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/gtfs_repository.dart';
import '../data/lugares_conocidos.dart';
import '../models/parada.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/destino_card.dart';
import 'resultado_ruta_screen.dart';

class BuscarRutaScreen extends StatefulWidget {
  final Parada? destinoInicial;

  const BuscarRutaScreen({super.key, this.destinoInicial});

  @override
  State<BuscarRutaScreen> createState() => _BuscarRutaScreenState();
}

class _BuscarRutaScreenState extends State<BuscarRutaScreen> {
  final TextEditingController _controlador = TextEditingController();
  Timer? _debounce;

  Parada? _destinoSeleccionado;
  Position? _miUbicacion;
  bool _buscandoUbicacion = true;
  List<Parada> _sugerencias = const [];
  final List<(LugarConocido, Parada?)> _destinosFrecuentes = [];

  @override
  void initState() {
    super.initState();
    _destinoSeleccionado = widget.destinoInicial;
    if (widget.destinoInicial != null) {
      _controlador.text = widget.destinoInicial!.nombre;
    }
    _cargarUbicacion();
    _cargarDestinosFrecuentes();
  }

  Future<void> _cargarUbicacion() async {
    final pos = await LocationService.instance.ubicacionActual();
    if (!mounted) return;
    setState(() {
      _miUbicacion = pos;
      _buscandoUbicacion = false;
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

  void _alCambiarTexto(String texto) {
    setState(() => _destinoSeleccionado = null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final resultados = await GtfsRepository.instance.buscarParadasPorNombre(texto);
      if (mounted) setState(() => _sugerencias = resultados);
    });
  }

  void _seleccionarParada(Parada parada) {
    setState(() {
      _destinoSeleccionado = parada;
      _sugerencias = const [];
      _controlador.text = parada.nombre;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar ruta"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "¿Dónde estás?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location,
                    color: _miUbicacion != null ? Colors.red : AppColors.grisTexto,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _buscandoUbicacion
                          ? "Buscando tu ubicación..."
                          : _miUbicacion != null
                              ? "Mi ubicación actual"
                              : "Sin acceso al GPS. Activa el permiso de ubicación.",
                    ),
                  ),
                  if (!_buscandoUbicacion)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _cargarUbicacion,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "¿A dónde quieres ir?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _controlador,
              onChanged: _alCambiarTexto,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Escribe una calle o punto de referencia",
                filled: true,
                fillColor: AppColors.blanco,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_sugerencias.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _sugerencias.length,
                  itemBuilder: (context, i) {
                    final parada = _sugerencias[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on, size: 18, color: Colors.red),
                      title: Text(parada.nombre, style: const TextStyle(fontSize: 14)),
                      onTap: () => _seleccionarParada(parada),
                    );
                  },
                ),
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
                alSeleccionar: parada == null ? () {} : () => _seleccionarParada(parada),
              );
            }),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final destino = _destinoSeleccionado;
                  if (destino == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Selecciona un destino primero")),
                    );
                    return;
                  }
                  final ubicacion = _miUbicacion;
                  if (ubicacion == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Necesitamos tu ubicación para buscar la ruta. Activa el GPS.",
                        ),
                      ),
                    );
                    return;
                  }
                  final origen = Parada(
                    id: 'ubicacion_actual',
                    nombre: 'Mi ubicación actual',
                    lat: ubicacion.latitude,
                    lon: ubicacion.longitude,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultadoRutaScreen(
                        origen: origen,
                        destino: destino,
                      ),
                    ),
                  );
                },
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
