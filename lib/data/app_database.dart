import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Punto único de acceso a la base de datos SQLite local de la app.
/// Las líneas, paradas, viajes y horarios importados del GTFS de
/// Cochabamba viven aquí para poder consultarse sin conexión.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existente = _db;
    if (existente != null) return existente;
    final abierta = await _abrir();
    _db = abierta;
    return abierta;
  }

  Future<Database> _abrir() async {
    final directorio = await getDatabasesPath();
    final ruta = p.join(directorio, 'transporte_cochabamba.db');
    return openDatabase(
      ruta,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE meta (
            clave TEXT PRIMARY KEY,
            valor TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE paradas (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_paradas_lat ON paradas(lat)');
        await db.execute('CREATE INDEX idx_paradas_lon ON paradas(lon)');
        await db.execute('CREATE INDEX idx_paradas_nombre ON paradas(nombre)');

        await db.execute('''
          CREATE TABLE rutas (
            id TEXT PRIMARY KEY,
            nombre_corto TEXT,
            nombre_largo TEXT,
            color TEXT,
            agencia_id TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE viajes (
            id TEXT PRIMARY KEY,
            ruta_id TEXT NOT NULL,
            shape_id TEXT,
            destino_texto TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_viajes_ruta ON viajes(ruta_id)');

        await db.execute('''
          CREATE TABLE paradas_por_viaje (
            viaje_id TEXT NOT NULL,
            secuencia INTEGER NOT NULL,
            parada_id TEXT NOT NULL,
            salida_seg INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_ppv_viaje_seq ON paradas_por_viaje(viaje_id, secuencia)',
        );
        await db.execute(
          'CREATE INDEX idx_ppv_parada ON paradas_por_viaje(parada_id)',
        );

        await db.execute('''
          CREATE TABLE puntos_forma (
            shape_id TEXT NOT NULL,
            secuencia INTEGER NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_puntos_forma_shape ON puntos_forma(shape_id, secuencia)',
        );

        await db.execute('''
          CREATE TABLE tarifas (
            ruta_id TEXT PRIMARY KEY,
            precio REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE frecuencias (
            viaje_id TEXT PRIMARY KEY,
            intervalo_seg INTEGER NOT NULL
          )
        ''');

        await _crearTablasCuentas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _crearTablasCuentas(db);
        }
      },
    );
  }

  Future<void> _crearTablasCuentas(Database db) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        rol TEXT NOT NULL,
        creado_en TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favoritos (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        nombre TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        creado_en TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_favoritos_usuario ON favoritos(usuario_id)');

    await db.execute('''
      CREATE TABLE incidencias (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        comentario TEXT,
        estado TEXT NOT NULL,
        usuario_id TEXT NOT NULL,
        creado_en TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_incidencias_lat ON incidencias(lat)');
    await db.execute('CREATE INDEX idx_incidencias_lon ON incidencias(lon)');

    await db.execute('''
      CREATE TABLE incidencia_confirmaciones (
        incidencia_id TEXT NOT NULL,
        usuario_id TEXT NOT NULL,
        PRIMARY KEY (incidencia_id, usuario_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lineas_override (
        ruta_id TEXT PRIMARY KEY,
        nombre_corto TEXT,
        color TEXT,
        activa INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }
}
