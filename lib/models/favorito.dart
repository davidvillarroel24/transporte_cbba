class Favorito {
  final String id;
  final String nombre;
  final double lat;
  final double lon;

  const Favorito({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lon,
  });

  factory Favorito.fromMap(Map<String, Object?> mapa) {
    return Favorito(
      id: mapa['id'] as String,
      nombre: mapa['nombre'] as String,
      lat: mapa['lat'] as double,
      lon: mapa['lon'] as double,
    );
  }
}
