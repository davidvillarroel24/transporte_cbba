class TarifaPasajero {
  final String tipo;
  final double precio;

  const TarifaPasajero({required this.tipo, required this.precio});

  factory TarifaPasajero.fromMap(Map<String, Object?> mapa) {
    return TarifaPasajero(
      tipo: mapa['tipo'] as String,
      precio: mapa['precio'] as double,
    );
  }
}
