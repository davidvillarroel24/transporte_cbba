import 'package:flutter/material.dart';

enum TipoIncidencia {
  calleBloqueada,
  mantenimiento,
  arbolCaido,
  cablesEnLaCalle,
  fugaDeGas,
  congestionamiento,
}

enum EstadoIncidencia { noVerificado, verificado, descartado }

extension TipoIncidenciaInfo on TipoIncidencia {
  String get etiqueta {
    switch (this) {
      case TipoIncidencia.calleBloqueada:
        return 'Calle bloqueada';
      case TipoIncidencia.mantenimiento:
        return 'Calle en mantenimiento';
      case TipoIncidencia.arbolCaido:
        return 'Árbol caído';
      case TipoIncidencia.cablesEnLaCalle:
        return 'Cables en la calle';
      case TipoIncidencia.fugaDeGas:
        return 'Fuga de gas';
      case TipoIncidencia.congestionamiento:
        return 'Congestionamiento';
    }
  }

  IconData get icono {
    switch (this) {
      case TipoIncidencia.calleBloqueada:
        return Icons.block;
      case TipoIncidencia.mantenimiento:
        return Icons.construction;
      case TipoIncidencia.arbolCaido:
        return Icons.park;
      case TipoIncidencia.cablesEnLaCalle:
        return Icons.power;
      case TipoIncidencia.fugaDeGas:
        return Icons.warning_amber;
      case TipoIncidencia.congestionamiento:
        return Icons.traffic;
    }
  }
}

TipoIncidencia tipoIncidenciaDesdeTexto(String texto) {
  return TipoIncidencia.values.firstWhere(
    (t) => t.name == texto,
    orElse: () => TipoIncidencia.congestionamiento,
  );
}

EstadoIncidencia estadoIncidenciaDesdeTexto(String texto) {
  return EstadoIncidencia.values.firstWhere(
    (e) => e.name == texto,
    orElse: () => EstadoIncidencia.noVerificado,
  );
}

class Incidencia {
  final String id;
  final TipoIncidencia tipo;
  final double lat;
  final double lon;
  final String? comentario;
  final EstadoIncidencia estado;
  final String usuarioId;
  final String reportadoPor;
  final int confirmaciones;
  final DateTime creadoEn;

  const Incidencia({
    required this.id,
    required this.tipo,
    required this.lat,
    required this.lon,
    required this.comentario,
    required this.estado,
    required this.usuarioId,
    required this.reportadoPor,
    required this.confirmaciones,
    required this.creadoEn,
  });

  Color get colorEstado {
    switch (estado) {
      case EstadoIncidencia.verificado:
        return const Color(0xFFC62828);
      case EstadoIncidencia.noVerificado:
        return const Color(0xFFE65100);
      case EstadoIncidencia.descartado:
        return const Color(0xFF9E9E9E);
    }
  }

  String get etiquetaConfianza {
    switch (estado) {
      case EstadoIncidencia.verificado:
        return 'Verificado por un revisor';
      case EstadoIncidencia.noVerificado:
        return 'Información no verificada, reportada por usuarios';
      case EstadoIncidencia.descartado:
        return 'Reporte descartado';
    }
  }
}
