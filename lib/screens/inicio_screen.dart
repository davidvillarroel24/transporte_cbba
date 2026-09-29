import 'package:flutter/material.dart';

import '../data/gtfs_repository.dart';
import '../data/lugares_conocidos.dart';
import '../models/parada.dart';
import '../theme/app_colors.dart';
import '../widgets/accion_card.dart';
import '../widgets/busqueda_destino.dart';
import '../widgets/lugar_card.dart';
import '../widgets/mapa_en_vivo.dart';
import 'buscar_ruta_screen.dart';
import 'favoritos_screen.dart';
import 'lineas_cercanas_screen.dart';
import 'mapa_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Future<List<Parada?>> _lugaresResueltos;

  @override
  void initState() {
    super.initState();
    _lugaresResueltos = _resolverLugares();
  }

  Future<List<Parada?>> _resolverLugares() async {
    final repo = GtfsRepository.instance;
    final resultado = <Parada?>[];
    for (final lugar in lugaresConocidos) {
      var cercanas = await repo.paradasCercanas(
        lugar.lat,
        lugar.lon,
        radioMetros: 400,
        limite: 1,
      );
      if (cercanas.isEmpty) {
        cercanas = await repo.paradasCercanas(
          lugar.lat,
          lugar.lon,
          radioMetros: 1500,
          limite: 1,
        );
      }
      resultado.add(cercanas.isEmpty ? null : cercanas.first);
    }
    return resultado;
  }

  void _irABuscarRuta({Parada? destinoInicial}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuscarRutaScreen(destinoInicial: destinoInicial),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo_maestrito.png',
                    height: 50,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "MAESTRITO",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.verde,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "¿A dónde desea dirigirse hoy?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 25),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 180,
                  child: MapaEnVivo(interactivo: false, zoomInicial: 15.0),
                ),
              ),
              const SizedBox(height: 25),
              BusquedaDestino(
                alBuscar: () => _irABuscarRuta(),
              ),
              const SizedBox(height: 30),
              const Text(
                "Accesos rápidos",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AccionCard(
                    icono: Icons.directions_bus,
                    titulo: "Líneas cercanas",
                    alPresionar: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LineasCercanasScreen(),
                        ),
                      );
                    },
                  ),
                  AccionCard(
                    icono: Icons.map,
                    titulo: "Ver mapa",
                    alPresionar: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapaScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Favoritos",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FavoritosScreen()),
                      );
                    },
                    child: const Text("Ver todos"),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              FutureBuilder<List<Parada?>>(
                future: _lugaresResueltos,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final paradas = snapshot.data!;
                  return Column(
                    children: List.generate(lugaresConocidos.length, (i) {
                      final lugar = lugaresConocidos[i];
                      final parada = paradas[i];
                      return LugarCard(
                        nombre: lugar.nombre,
                        direccion: lugar.direccion,
                        alSeleccionar: parada == null
                            ? () {}
                            : () => _irABuscarRuta(destinoInicial: parada),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
