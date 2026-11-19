import 'package:sqflite/sqflite.dart';

import '../models/tarifa_pasajero.dart';
import 'app_database.dart';

/// Tarifas de referencia por tipo de pasajero, mostradas desde el mapa.
/// Editables desde el panel de administrador; no implica pagos dentro de
/// la app.
class TarifasRepository {
  TarifasRepository._();
  static final TarifasRepository instance = TarifasRepository._();

  Future<List<TarifaPasajero>> listarTodas() async {
    final db = await AppDatabase.instance.database;
    final filas = await db.query('tarifas_pasajero', orderBy: 'tipo');
    return filas.map(TarifaPasajero.fromMap).toList();
  }

  Future<void> actualizarPrecio(String tipo, double precio) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'tarifas_pasajero',
      {'tipo': tipo, 'precio': precio},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
