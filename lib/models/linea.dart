import 'package:flutter/material.dart';

class Linea {
  final String id;
  final String nombreCorto;
  final String nombreLargo;
  final Color color;

  const Linea({
    required this.id,
    required this.nombreCorto,
    required this.nombreLargo,
    required this.color,
  });

  factory Linea.fromMap(Map<String, Object?> mapa) {
    final id = mapa['id'] as String;
    final colorHex = mapa['color'] as String?;
    return Linea(
      id: id,
      nombreCorto: (mapa['nombre_corto'] as String?)?.trim().isNotEmpty == true
          ? mapa['nombre_corto'] as String
          : id,
      nombreLargo: (mapa['nombre_largo'] as String?) ?? '',
      color: _colorDesde(id, colorHex),
    );
  }

  static Color _colorDesde(String id, String? hex) {
    if (hex != null && hex.trim().isNotEmpty) {
      final limpio = hex.trim().replaceFirst('#', '');
      final valor = int.tryParse(limpio, radix: 16);
      if (valor != null && limpio.length == 6) {
        return Color(0xFF000000 | valor);
      }
    }
    // El GTFS no siempre trae route_color: se deriva un color estable
    // a partir del id de la línea para que cada línea sea reconocible.
    final paleta = <Color>[
      const Color(0xFF2E7D32),
      const Color(0xFF1565C0),
      const Color(0xFFB71C1C),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
      const Color(0xFF00695C),
      const Color(0xFF283593),
      const Color(0xFF4E342E),
    ];
    return paleta[id.hashCode.abs() % paleta.length];
  }
}
