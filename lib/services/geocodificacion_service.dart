import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/parada.dart';

/// Busca direcciones reales (calles, avenidas, barrios) usando Nominatim,
/// el geocodificador gratuito de OpenStreetMap. Complementa la búsqueda por
/// nombre de parada del GTFS, que no conoce direcciones que no sean una
/// parada registrada.
class GeocodificacionService {
  GeocodificacionService._();
  static final GeocodificacionService instance = GeocodificacionService._();

  static const _url = 'https://nominatim.openstreetmap.org/search';
  static const _urlInversa = 'https://nominatim.openstreetmap.org/reverse';
  // Caja aproximada de Cochabamba (ciudad y alrededores), para priorizar
  // resultados locales sin descartar el resto de Bolivia.
  static const _viewbox = '-66.28,-17.30,-66.05,-17.47';

  Future<List<Parada>> buscar(String texto) async {
    final consulta = texto.trim();
    if (consulta.length < 3) return const [];

    final uri = Uri.parse(_url).replace(queryParameters: {
      'q': consulta,
      'format': 'json',
      'countrycodes': 'bo',
      'viewbox': _viewbox,
      'bounded': '0',
      'limit': '5',
    });

    try {
      final respuesta = await http
          .get(uri, headers: {'User-Agent': 'MaestritoCochabambaApp/1.0'})
          .timeout(const Duration(seconds: 6));
      if (respuesta.statusCode != 200) return const [];

      final lista = jsonDecode(respuesta.body) as List<dynamic>;
      return lista.map((item) {
        final mapa = item as Map<String, dynamic>;
        return Parada(
          id: 'geo_${mapa['place_id']}',
          nombre: (mapa['display_name'] as String).split(',').take(3).join(','),
          lat: double.parse(mapa['lat'] as String),
          lon: double.parse(mapa['lon'] as String),
        );
      }).toList();
    } catch (_) {
      // Sin conexión o error de red: no rompe la búsqueda, simplemente no
      // aporta resultados de geocodificación (quedan los locales).
      return const [];
    }
  }

  /// Nombre legible para un punto marcado a mano en el mapa (geocodificación
  /// inversa). Si falla, el llamador debe usar un nombre genérico.
  Future<String?> nombrePara(double lat, double lon) async {
    final uri = Uri.parse(_urlInversa).replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'json',
    });
    try {
      final respuesta = await http
          .get(uri, headers: {'User-Agent': 'MaestritoCochabambaApp/1.0'})
          .timeout(const Duration(seconds: 6));
      if (respuesta.statusCode != 200) return null;
      final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
      final nombre = mapa['display_name'] as String?;
      return nombre?.split(',').take(3).join(',');
    } catch (_) {
      return null;
    }
  }
}
