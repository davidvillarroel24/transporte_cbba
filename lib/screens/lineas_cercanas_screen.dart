import 'package:flutter/material.dart';

import '../data/gtfs_repository.dart';
import '../models/linea.dart';
import '../models/parada.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

class LineasCercanasScreen extends StatefulWidget {
  const LineasCercanasScreen({super.key});

  @override
  State<LineasCercanasScreen> createState() => _LineasCercanasScreenState();
}

class _LineasCercanasScreenState extends State<LineasCercanasScreen> {
  bool _cargando = true;
  String? _error;
  List<(Parada, List<Linea>)> _resultado = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final posicion = await LocationService.instance.ubicacionActual();
    if (!mounted) return;
    if (posicion == null) {
      setState(() {
        _cargando = false;
        _error = 'Activa el GPS y los permisos de ubicación para ver las '
            'líneas cercanas a donde estás.';
      });
      return;
    }

    final repo = GtfsRepository.instance;
    final paradas = await repo.paradasCercanas(
      posicion.latitude,
      posicion.longitude,
      radioMetros: 600,
      limite: 6,
    );

    if (paradas.isEmpty) {
      setState(() {
        _cargando = false;
        _error = 'No se encontraron paradas registradas cerca de tu '
            'ubicación actual.';
      });
      return;
    }

    final agrupado = <(Parada, List<Linea>)>[];
    for (final parada in paradas) {
      final lineas = await repo.lineasEnParada(parada.id);
      if (lineas.isNotEmpty) agrupado.add((parada, lineas));
    }

    if (!mounted) return;
    setState(() {
      _cargando = false;
      _resultado = agrupado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Líneas cercanas'),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grisTexto),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _resultado.length,
                  itemBuilder: (context, indice) {
                    final (parada, lineas) = _resultado[indice];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  parada.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: lineas.map((linea) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: linea.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: linea.color),
                                ),
                                child: Text(
                                  linea.nombreCorto,
                                  style: TextStyle(
                                    color: linea.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
