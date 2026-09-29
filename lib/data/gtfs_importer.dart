import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

typedef ProgresoImportacion = void Function(String etapa, double fraccion);

/// Lee el feed GTFS estático de assets/cochabamba_gtfs (rutas reales de
/// micros, minibuses y trufis de Cochabamba, publicado por Trufi
/// Association) y lo vuelca a la base SQLite local, una sola vez.
class GtfsImporter {
  static const _carpeta = 'assets/cochabamba_gtfs';
  static const _versionDatos = 'cochabamba_gtfs_v1';
  static const _tamanoLote = 1500;

  static Future<void> importarSiHaceFalta({
    ProgresoImportacion? onProgreso,
  }) async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query(
      'meta',
      where: 'clave = ?',
      whereArgs: ['version_datos'],
    );
    if (filas.isNotEmpty && filas.first['valor'] == _versionDatos) {
      onProgreso?.call('Datos listos', 1.0);
      return;
    }
    await _importar(db, onProgreso);
  }

  static Future<List<List<String>>> _leerCsv(String archivo) async {
    final crudo = await rootBundle.loadString('$_carpeta/$archivo');
    final normalizado = crudo.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    const conversor = CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    );
    final filas = conversor.convert(normalizado);
    if (filas.length <= 1) return const [];
    return filas
        .sublist(1)
        .where((fila) => fila.isNotEmpty && fila.any((c) => c.toString().trim().isNotEmpty))
        .map((fila) => fila.map((c) => c.toString().trim()).toList())
        .toList();
  }

  static int _segundosDesdeHora(String hora) {
    final partes = hora.split(':');
    if (partes.length != 3) return 0;
    final h = int.tryParse(partes[0]) ?? 0;
    final m = int.tryParse(partes[1]) ?? 0;
    final s = int.tryParse(partes[2]) ?? 0;
    return h * 3600 + m * 60 + s;
  }

  static double? _double(String valor) {
    if (valor.trim().isEmpty) return null;
    return double.tryParse(valor.trim());
  }

  static Future<void> _importar(
    Database db,
    ProgresoImportacion? onProgreso,
  ) async {
    await db.transaction((txn) async {
      await txn.delete('paradas');
      await txn.delete('rutas');
      await txn.delete('viajes');
      await txn.delete('paradas_por_viaje');
      await txn.delete('puntos_forma');
      await txn.delete('tarifas');
      await txn.delete('frecuencias');

      // ---- paradas (stops.txt: stop_id,stop_name,stop_lat,stop_lon,stop_desc)
      onProgreso?.call('Importando paradas', 0.05);
      final paradas = await _leerCsv('stops.txt');
      var lote = txn.batch();
      var enLote = 0;
      for (final f in paradas) {
        if (f.length < 4) continue;
        final lat = _double(f[2]);
        final lon = _double(f[3]);
        if (lat == null || lon == null) continue;
        lote.insert(
          'paradas',
          {'id': f[0], 'nombre': f[1], 'lat': lat, 'lon': lon},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        enLote++;
        if (enLote >= _tamanoLote) {
          await lote.commit(noResult: true);
          lote = txn.batch();
          enLote = 0;
        }
      }
      await lote.commit(noResult: true);

      // ---- rutas (routes.txt: route_id,agency_id,route_short_name,route_long_name,route_color,route_type)
      onProgreso?.call('Importando líneas', 0.15);
      final rutas = await _leerCsv('routes.txt');
      lote = txn.batch();
      for (final f in rutas) {
        if (f.length < 3) continue;
        lote.insert('rutas', {
          'id': f[0],
          'agencia_id': f.length > 1 ? f[1] : '',
          'nombre_corto': f.length > 2 ? f[2] : '',
          'nombre_largo': f.length > 3 ? f[3] : '',
          'color': f.length > 4 ? f[4] : '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await lote.commit(noResult: true);

      // ---- viajes (trips.txt: trip_id,route_id,service_id,shape_id,trip_headsign,direction_id)
      onProgreso?.call('Importando viajes', 0.2);
      final viajes = await _leerCsv('trips.txt');
      lote = txn.batch();
      for (final f in viajes) {
        if (f.length < 2) continue;
        lote.insert('viajes', {
          'id': f[0],
          'ruta_id': f[1],
          'shape_id': f.length > 3 ? f[3] : '',
          'destino_texto': f.length > 4 ? f[4] : '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await lote.commit(noResult: true);

      // ---- paradas por viaje (stop_times.txt: trip_id,stop_sequence,stop_id,arrival_time,departure_time,timepoint)
      onProgreso?.call('Importando horarios (puede tardar unos segundos)', 0.35);
      final stopTimes = await _leerCsv('stop_times.txt');
      lote = txn.batch();
      enLote = 0;
      for (final f in stopTimes) {
        if (f.length < 5) continue;
        final secuencia = int.tryParse(f[1]);
        if (secuencia == null) continue;
        lote.insert('paradas_por_viaje', {
          'viaje_id': f[0],
          'secuencia': secuencia,
          'parada_id': f[2],
          'salida_seg': _segundosDesdeHora(f[4]),
        });
        enLote++;
        if (enLote >= _tamanoLote) {
          await lote.commit(noResult: true);
          lote = txn.batch();
          enLote = 0;
        }
      }
      await lote.commit(noResult: true);

      // ---- puntos de forma (shapes.txt: shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence)
      onProgreso?.call('Importando trazado de rutas', 0.65);
      final shapes = await _leerCsv('shapes.txt');
      lote = txn.batch();
      enLote = 0;
      for (final f in shapes) {
        if (f.length < 4) continue;
        final lat = _double(f[1]);
        final lon = _double(f[2]);
        final secuencia = int.tryParse(f[3]);
        if (lat == null || lon == null || secuencia == null) continue;
        lote.insert('puntos_forma', {
          'shape_id': f[0],
          'secuencia': secuencia,
          'lat': lat,
          'lon': lon,
        });
        enLote++;
        if (enLote >= _tamanoLote) {
          await lote.commit(noResult: true);
          lote = txn.batch();
          enLote = 0;
        }
      }
      await lote.commit(noResult: true);

      // ---- tarifas (fare_attributes.txt + fare_rules.txt)
      onProgreso?.call('Importando tarifas', 0.9);
      final fareAttrs = await _leerCsv('fare_attributes.txt');
      final precioPorFareId = <String, double>{};
      for (final f in fareAttrs) {
        if (f.length < 3) continue;
        precioPorFareId[f[1]] = _double(f[2]) ?? 0;
      }
      final fareRules = await _leerCsv('fare_rules.txt');
      final precioPorRuta = <String, double>{};
      for (final f in fareRules) {
        if (f.length < 2) continue;
        final precio = precioPorFareId[f[0]] ?? 0;
        final rutaId = f[1];
        final actual = precioPorRuta[rutaId] ?? 0;
        if (precio > actual) precioPorRuta[rutaId] = precio;
      }
      lote = txn.batch();
      for (final entrada in precioPorRuta.entries) {
        lote.insert('tarifas', {
          'ruta_id': entrada.key,
          'precio': entrada.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await lote.commit(noResult: true);

      // ---- frecuencias (frequencies.txt: trip_id,start_time,end_time,headway_secs,exact_times)
      onProgreso?.call('Importando frecuencias', 0.95);
      final frecuencias = await _leerCsv('frequencies.txt');
      lote = txn.batch();
      for (final f in frecuencias) {
        if (f.length < 4) continue;
        final intervalo = int.tryParse(f[3]);
        if (intervalo == null) continue;
        lote.insert('frecuencias', {
          'viaje_id': f[0],
          'intervalo_seg': intervalo,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await lote.commit(noResult: true);

      await txn.insert('meta', {
        'clave': 'version_datos',
        'valor': _versionDatos,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    onProgreso?.call('Datos listos', 1.0);
  }
}
