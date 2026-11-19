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
      version: 3,
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
        await _crearTablasCongestionYTarifas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _crearTablasCuentas(db);
        }
        if (oldVersion < 3) {
          await _crearTablasCongestionYTarifas(db);
        }
      },
    );
  }

  Future<void> _crearTablasCongestionYTarifas(Database db) async {
    await db.execute('''
      CREATE TABLE congestion_escolar (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        calle TEXT,
        lat REAL NOT NULL,
        lon REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tarifas_pasajero (
        tipo TEXT PRIMARY KEY,
        precio REAL NOT NULL
      )
    ''');

    // Colegios con coordenada confirmada (ver Perfil de Grado / PDF de
    // congestión escolar). Falta "Sara Ugarte de Salamanca" porque no se
    // pudo geocodificar su calle (16 de Julio y Bolívar no está indexada
    // en OpenStreetMap para Cochabamba); el admin lo agrega a mano desde
    // el panel de administración marcándolo en el mapa.
    const colegios = [
      {
        'id': 'seed_don_bosco',
        'nombre': 'Don Bosco',
        'calle': 'Av. Oquendo y Av. Papa Paulo',
        'lat': -17.383196,
        'lon': -66.150931,
      },
      {
        'id': 'seed_domingo_sabio',
        'nombre': 'Domingo Sabio',
        'calle': 'Av. Aniceto Arce',
        'lat': -17.381278,
        'lon': -66.144187,
      },
      {
        'id': 'seed_instituto_americano',
        'nombre': 'Instituto Americano',
        'calle': 'Entre Av. Circunvalación y Av. Julio Rodríguez, entre Av. Santa Cruz y Potosí',
        'lat': -17.368204,
        'lon': -66.154360,
      },
      {
        'id': 'seed_elena_arce',
        'nombre': 'Elena Arce',
        'calle': 'Adela Zamudio y B.M. Pulacayo',
        'lat': -17.370381,
        'lon': -66.164453,
      },
      {
        'id': 'seed_german_bush',
        'nombre': 'German Bush',
        'calle': 'Av. Julio Rodriguez y Pasos Kanki',
        'lat': -17.367937,
        'lon': -66.161107,
      },
      {
        'id': 'seed_6_de_agosto',
        'nombre': 'Escuela 6 de Agosto',
        'calle': null,
        'lat': -17.415800,
        'lon': -66.151200,
      },
      {
        'id': 'seed_ceferino_namuncura',
        'nombre': 'Escuela Ceferino Namuncurá',
        'calle': null,
        'lat': -17.395700,
        'lon': -66.163500,
      },
      {
        'id': 'seed_gualberto_villarroel',
        'nombre': 'Escuela Gualberto Villarroel',
        'calle': null,
        'lat': -17.419100,
        'lon': -66.162600,
      },
      {
        'id': 'seed_iv_centenario',
        'nombre': 'Escuela IV Centenario',
        'calle': null,
        'lat': -17.374300,
        'lon': -66.189500,
      },
      {
        'id': 'seed_jose_gabriel_gumucio',
        'nombre': 'Escuela José Gabriel de Gumucio',
        'calle': null,
        'lat': -17.408400,
        'lon': -66.182500,
      },
      {
        'id': 'seed_liceo_adela_zamudio',
        'nombre': 'Liceo Adela Zamudio',
        'calle': null,
        'lat': -17.435000,
        'lon': -66.151400,
      },
      {
        'id': 'seed_liceo_guindalina_loayza',
        'nombre': 'Liceo Guindalina Loayza',
        'calle': null,
        'lat': -17.426200,
        'lon': -66.151000,
      },
      {
        'id': 'seed_instituto_eduardo_laredo',
        'nombre': 'Instituto Eduardo Laredo',
        'calle': null,
        'lat': -17.462700,
        'lon': -66.117600,
      },
      {
        'id': 'seed_liceo_mercedes_candia',
        'nombre': 'Liceo Mercedes Candia de Ovando',
        'calle': null,
        'lat': -17.452400,
        'lon': -66.129400,
      },
      {
        'id': 'seed_liceo_elena_arze',
        'nombre': 'Liceo Elena Arze de Arze',
        'calle': null,
        'lat': -17.477000,
        'lon': -66.110100,
      },
    ];
    for (final colegio in colegios) {
      await db.insert('congestion_escolar', colegio, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    const tarifas = [
      {'tipo': 'Niño', 'precio': 2.0},
      {'tipo': 'Adulto', 'precio': 3.0},
      {'tipo': 'Estudiante', 'precio': 1.5},
      {'tipo': 'Universitario', 'precio': 2.0},
      {'tipo': 'Adulto mayor', 'precio': 1.5},
    ];
    for (final tarifa in tarifas) {
      await db.insert('tarifas_pasajero', tarifa, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
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
