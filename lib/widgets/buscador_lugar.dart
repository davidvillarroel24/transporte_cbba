import 'dart:async';

import 'package:flutter/material.dart';

import '../data/favoritos_repository.dart';
import '../data/gtfs_repository.dart';
import '../data/lugares_conocidos.dart';
import '../models/parada.dart';
import '../services/auth_service.dart';
import '../services/geocodificacion_service.dart';
import '../theme/app_colors.dart';

/// Campo de búsqueda con sugerencias en vivo, estilo Google Maps: combina,
/// por orden de prioridad, paradas del GTFS, favoritos guardados, lugares
/// turísticos conocidos y geocodificación de direcciones reales (Nominatim).
/// Lo ya conocido localmente aparece primero porque no depende de red.
class BuscadorLugar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<Parada> onSeleccionar;

  const BuscadorLugar({
    super.key,
    this.hintText = '¿A dónde quieres ir?',
    this.controller,
    required this.onSeleccionar,
  });

  @override
  State<BuscadorLugar> createState() => _BuscadorLugarState();
}

class _BuscadorLugarState extends State<BuscadorLugar> {
  late final TextEditingController _controlador;
  late final bool _controladorPropio;
  Timer? _debounce;
  List<Parada> _sugerencias = const [];
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _controladorPropio = widget.controller == null;
    _controlador = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_controladorPropio) _controlador.dispose();
    super.dispose();
  }

  void _alCambiarTexto(String texto) {
    _debounce?.cancel();
    if (texto.trim().isEmpty) {
      setState(() => _sugerencias = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _buscar(texto));
  }

  Future<void> _buscar(String texto) async {
    setState(() => _buscando = true);

    final textoNormalizado = texto.toLowerCase();
    final repo = GtfsRepository.instance;
    final usuario = AuthService.instance.usuarioActual;

    final favoritosCoincidentes = usuario == null
        ? const <Parada>[]
        : (await FavoritosRepository.instance.deUsuario(usuario.id))
            .where((f) => f.nombre.toLowerCase().contains(textoNormalizado))
            .map((f) => Parada(id: 'fav_${f.id}', nombre: f.nombre, lat: f.lat, lon: f.lon))
            .toList();

    final lugaresCoincidentes = lugaresConocidos
        .where((l) => l.nombre.toLowerCase().contains(textoNormalizado))
        .map((l) => Parada(id: 'lugar_${l.nombre}', nombre: l.nombre, lat: l.lat, lon: l.lon))
        .toList();

    final paradas = await repo.buscarParadasPorNombre(texto);
    final geocodificadas = await GeocodificacionService.instance.buscar(texto);

    if (!mounted) return;
    setState(() {
      _sugerencias = [...paradas, ...favoritosCoincidentes, ...lugaresCoincidentes, ...geocodificadas];
      _buscando = false;
    });
  }

  void _seleccionar(Parada parada) {
    setState(() => _sugerencias = const []);
    _controlador.text = parada.nombre;
    FocusScope.of(context).unfocus();
    widget.onSeleccionar(parada);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: TextField(
            controller: _controlador,
            onChanged: _alCambiarTexto,
            decoration: InputDecoration(
              icon: const Icon(Icons.search),
              hintText: widget.hintText,
              border: InputBorder.none,
              suffixIcon: _buscando
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (_sugerencias.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 260),
            child: Material(
              type: MaterialType.transparency,
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
                    onTap: () => _seleccionar(parada),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
