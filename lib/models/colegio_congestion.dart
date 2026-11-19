class ColegioCongestion {
  final String id;
  final String nombre;
  final String? calle;
  final double lat;
  final double lon;

  const ColegioCongestion({
    required this.id,
    required this.nombre,
    this.calle,
    required this.lat,
    required this.lon,
  });

  factory ColegioCongestion.fromMap(Map<String, Object?> mapa) {
    return ColegioCongestion(
      id: mapa['id'] as String,
      nombre: mapa['nombre'] as String,
      calle: mapa['calle'] as String?,
      lat: mapa['lat'] as double,
      lon: mapa['lon'] as double,
    );
  }
}
