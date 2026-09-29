class Parada {
  final String id;
  final String nombre;
  final double lat;
  final double lon;

  const Parada({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lon,
  });

  factory Parada.fromMap(Map<String, Object?> mapa) {
    return Parada(
      id: mapa['id'] as String,
      nombre: mapa['nombre'] as String,
      lat: mapa['lat'] as double,
      lon: mapa['lon'] as double,
    );
  }
}
