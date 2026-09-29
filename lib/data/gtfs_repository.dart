import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/linea.dart';
import '../models/parada.dart';
import '../models/resultado_ruta.dart';
import 'app_database.dart';
import 'lineas_admin_repository.dart';

/// Consultas de solo lectura sobre los datos GTFS ya importados a SQLite.
class GtfsRepository {
  GtfsRepository._();
  static final GtfsRepository instance = GtfsRepository._();

  static const _radioTierraM = 6371000.0;

  /// Arma una Linea aplicando las correcciones que haya hecho el admin
  /// (nombre/color) sobre la fila original importada del GTFS.
  Future<Linea> _lineaConOverride(Map<String, Object?> filaRuta) async {
    final rutaId = filaRuta['id'] as String;
    final override = await LineasAdminRepository.instance.overrideDe(rutaId);
    if (override == null) return Linea.fromMap(filaRuta);
    final combinada = Map<String, Object?>.from(filaRuta);
    if ((override['nombre_corto'] as String?)?.trim().isNotEmpty == true) {
      combinada['nombre_corto'] = override['nombre_corto'];
    }
    if ((override['color'] as String?)?.trim().isNotEmpty == true) {
      combinada['color'] = override['color'];
    }
    return Linea.fromMap(combinada);
  }

  double _distanciaMetros(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _gradosARadianes(lat2 - lat1);
    final dLon = _gradosARadianes(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_gradosARadianes(lat1)) *
            math.cos(_gradosARadianes(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _radioTierraM * c;
  }

  double _gradosARadianes(double grados) => grados * math.pi / 180;

  Future<List<Parada>> buscarParadasPorNombre(
    String texto, {
    int limite = 8,
  }) async {
    final consulta = texto.trim();
    if (consulta.length < 2) return const [];
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'paradas',
      where: 'nombre LIKE ?',
      whereArgs: ['%$consulta%'],
      limit: limite,
      orderBy: 'nombre',
    );
    return filas.map(Parada.fromMap).toList();
  }

  /// Paradas reales dentro de [radioMetros] de un punto, ordenadas por
  /// distancia. Usa una caja delimitadora en SQL (rápida, con índice) y
  /// afina con distancia real (haversine) en Dart.
  Future<List<Parada>> paradasCercanas(
    double lat,
    double lon, {
    double radioMetros = 500,
    int limite = 30,
  }) async {
    final deltaLat = radioMetros / 111320.0;
    final deltaLon = radioMetros / (111320.0 * math.cos(_gradosARadianes(lat)).abs().clamp(0.05, 1.0));
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'paradas',
      where: 'lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?',
      whereArgs: [lat - deltaLat, lat + deltaLat, lon - deltaLon, lon + deltaLon],
    );
    final conDistancia = filas.map((f) {
      final parada = Parada.fromMap(f);
      final distancia = _distanciaMetros(lat, lon, parada.lat, parada.lon);
      return (parada: parada, distancia: distancia);
    }).where((e) => e.distancia <= radioMetros).toList()
      ..sort((a, b) => a.distancia.compareTo(b.distancia));
    return conDistancia.take(limite).map((e) => e.parada).toList();
  }

  Future<List<Linea>> lineasEnParada(String paradaId) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.rawQuery('''
      SELECT DISTINCT r.id, r.nombre_corto, r.nombre_largo, r.color
      FROM paradas_por_viaje ppv
      JOIN viajes v ON v.id = ppv.viaje_id
      JOIN rutas r ON r.id = v.ruta_id
      WHERE ppv.parada_id = ?
    ''', [paradaId]);
    final desactivadas = await LineasAdminRepository.instance.idsDesactivadas();
    final activas = filas.where((f) => !desactivadas.contains(f['id'] as String));
    return Future.wait(activas.map(_lineaConOverride));
  }

  /// Todas las líneas activas del GTFS (para el selector del mapa).
  Future<List<Linea>> todasLasLineas() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('rutas', orderBy: 'nombre_corto');
    final desactivadas = await LineasAdminRepository.instance.idsDesactivadas();
    final activas = filas.where((f) => !desactivadas.contains(f['id'] as String));
    return Future.wait(activas.map(_lineaConOverride));
  }

  Future<String?> shapeDeLinea(String rutaId) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'viajes',
      where: "ruta_id = ? AND shape_id IS NOT NULL AND shape_id != ''",
      whereArgs: [rutaId],
      limit: 1,
    );
    if (filas.isEmpty) return null;
    return filas.first['shape_id'] as String?;
  }

  Future<List<LatLng>> puntosDeForma(String shapeId) async {
    if (shapeId.trim().isEmpty) return const [];
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'puntos_forma',
      where: 'shape_id = ?',
      whereArgs: [shapeId],
      orderBy: 'secuencia',
    );
    return filas
        .map((f) => LatLng(f['lat'] as double, f['lon'] as double))
        .toList();
  }

  /// Busca líneas reales que conecten un origen con un destino: exige que
  /// exista un mismo viaje (trip) del GTFS que pase primero cerca del
  /// origen y después, más adelante en su recorrido, cerca del destino.
  Future<List<ResultadoRuta>> buscarRutas({
    required Parada origen,
    required Parada destino,
    double radioMetros = 450,
    int limite = 8,
  }) async {
    final paradasOrigen = await paradasCercanas(
      origen.lat,
      origen.lon,
      radioMetros: radioMetros,
    );
    final paradasDestino = await paradasCercanas(
      destino.lat,
      destino.lon,
      radioMetros: radioMetros,
    );
    if (paradasOrigen.isEmpty || paradasDestino.isEmpty) return const [];

    final idsOrigen = paradasOrigen.map((p) => p.id).toSet();
    final idsDestino = paradasDestino.map((p) => p.id).toSet();
    final porOrigen = {for (final p in paradasOrigen) p.id: p};
    final porDestino = {for (final p in paradasDestino) p.id: p};

    final marcadoresOrigen = List.filled(idsOrigen.length, '?').join(',');
    final marcadoresDestino = List.filled(idsDestino.length, '?').join(',');

    final db = await AppDatabase.instance.database;
    final filas = await db.rawQuery('''
      SELECT
        v.ruta_id AS ruta_id,
        v.id AS viaje_id,
        v.shape_id AS shape_id,
        ppv1.parada_id AS parada_origen_id,
        ppv2.parada_id AS parada_destino_id,
        ppv1.salida_seg AS t1,
        ppv2.salida_seg AS t2
      FROM paradas_por_viaje ppv1
      JOIN paradas_por_viaje ppv2
        ON ppv2.viaje_id = ppv1.viaje_id
        AND ppv2.secuencia > ppv1.secuencia
      JOIN viajes v ON v.id = ppv1.viaje_id
      WHERE ppv1.parada_id IN ($marcadoresOrigen)
        AND ppv2.parada_id IN ($marcadoresDestino)
    ''', [...idsOrigen, ...idsDestino]);

    if (filas.isEmpty) return const [];

    // Agrupamos por línea y nos quedamos con el viaje más rápido de cada una.
    final mejorPorRuta = <String, Map<String, Object?>>{};
    final vecesPorRuta = <String, int>{};
    for (final f in filas) {
      final rutaId = f['ruta_id'] as String;
      vecesPorRuta[rutaId] = (vecesPorRuta[rutaId] ?? 0) + 1;
      final t1 = f['t1'] as int;
      final t2 = f['t2'] as int;
      if (t2 <= t1) continue;
      final actual = mejorPorRuta[rutaId];
      if (actual == null || (t2 - t1) < ((actual['t2'] as int) - (actual['t1'] as int))) {
        mejorPorRuta[rutaId] = f;
      }
    }
    if (mejorPorRuta.isEmpty) return const [];

    final rutaIds = mejorPorRuta.keys.toList();
    final marcadoresRutas = List.filled(rutaIds.length, '?').join(',');
    final rutasInfo = await db.query(
      'rutas',
      where: 'id IN ($marcadoresRutas)',
      whereArgs: rutaIds,
    );
    final desactivadas = await LineasAdminRepository.instance.idsDesactivadas();
    final rutasActivas = rutasInfo.where((r) => !desactivadas.contains(r['id'] as String));
    final lineasResueltas = await Future.wait(rutasActivas.map(_lineaConOverride));
    final lineaPorId = {
      for (final l in lineasResueltas) l.id: l,
    };
    final tarifas = await db.query(
      'tarifas',
      where: 'ruta_id IN ($marcadoresRutas)',
      whereArgs: rutaIds,
    );
    final tarifaPorRuta = {
      for (final t in tarifas) t['ruta_id'] as String: t['precio'] as double,
    };

    final resultados = <ResultadoRuta>[];
    for (final entrada in mejorPorRuta.entries) {
      final rutaId = entrada.key;
      final fila = entrada.value;
      final linea = lineaPorId[rutaId];
      if (linea == null) continue;
      final paradaOrigen = porOrigen[fila['parada_origen_id'] as String];
      final paradaDestino = porDestino[fila['parada_destino_id'] as String];
      if (paradaOrigen == null || paradaDestino == null) continue;
      final segundos = (fila['t2'] as int) - (fila['t1'] as int);
      resultados.add(ResultadoRuta(
        linea: linea,
        paradaOrigen: paradaOrigen,
        paradaDestino: paradaDestino,
        tiempoMinutos: (segundos / 60).round().clamp(1, 999),
        tarifa: tarifaPorRuta[rutaId],
        viajesEncontrados: vecesPorRuta[rutaId] ?? 1,
        shapeId: fila['shape_id'] as String?,
      ));
    }

    resultados.sort((a, b) => a.tiempoMinutos.compareTo(b.tiempoMinutos));
    return resultados.take(limite).toList();
  }
}
