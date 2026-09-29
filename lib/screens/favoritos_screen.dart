import 'package:flutter/material.dart';

import '../data/favoritos_repository.dart';
import '../data/lugares_conocidos.dart';
import '../models/favorito.dart';
import '../models/parada.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/lugar_card.dart';
import 'buscar_ruta_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  late Future<List<Favorito>> _favoritos;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    final usuario = AuthService.instance.usuarioActual;
    _favoritos = usuario == null
        ? Future.value(const [])
        : FavoritosRepository.instance.deUsuario(usuario.id);
  }

  Future<void> _irABuscarRuta(String nombre, double lat, double lon) async {
    final destino = Parada(id: 'favorito', nombre: nombre, lat: lat, lon: lon);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BuscarRutaScreen(destinoInicial: destino)),
    );
  }

  Future<void> _quitar(Favorito favorito) async {
    await FavoritosRepository.instance.quitar(favorito.id);
    setState(_cargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Lugares turísticos sugeridos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...lugaresConocidos.map((lugar) {
            return LugarCard(
              nombre: lugar.nombre,
              direccion: lugar.direccion,
              alSeleccionar: () => _irABuscarRuta(lugar.nombre, lugar.lat, lugar.lon),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Mis favoritos guardados',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Favorito>>(
            future: _favoritos,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final favoritos = snapshot.data!;
              if (favoritos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Aún no guardaste ningún favorito. Puedes hacerlo desde '
                    'el resultado de una búsqueda de ruta.',
                    style: TextStyle(color: AppColors.grisTexto, fontSize: 13),
                  ),
                );
              }
              return Column(
                children: favoritos.map((favorito) {
                  return Dismissible(
                    key: ValueKey(favorito.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _quitar(favorito),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    child: LugarCard(
                      nombre: favorito.nombre,
                      direccion: 'Favorito guardado',
                      alSeleccionar: () => _irABuscarRuta(favorito.nombre, favorito.lat, favorito.lon),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
