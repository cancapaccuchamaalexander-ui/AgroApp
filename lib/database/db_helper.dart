import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/parcela.dart';
import '../models/cultivo.dart';
import '../models/registro_riego.dart';
import '../models/registro_fertilizante.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'agro_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE parcelas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    ubicacion TEXT,
    area_hectareas REAL,
    foto_path TEXT,
    latitud REAL,
    longitud REAL
  )
''');

    await db.execute('''
      CREATE TABLE cultivos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parcela_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        variedad TEXT,
        fecha_siembra TEXT,
        etapa TEXT,
        FOREIGN KEY (parcela_id) REFERENCES parcelas (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE registros_riego (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cultivo_id INTEGER NOT NULL,
        fecha TEXT,
        cantidad_agua REAL,
        notificacion_id INTEGER,
        FOREIGN KEY (cultivo_id) REFERENCES cultivos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE registros_fertilizante (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cultivo_id INTEGER NOT NULL,
        fecha TEXT,
        producto TEXT,
        dosis REAL,
        FOREIGN KEY (cultivo_id) REFERENCES cultivos (id) ON DELETE CASCADE
      )
    ''');
  }
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE parcelas ADD COLUMN foto_path TEXT');
      await db.execute('ALTER TABLE parcelas ADD COLUMN latitud REAL');
      await db.execute('ALTER TABLE parcelas ADD COLUMN longitud REAL');
    }
  }

  // ---------------- PARCELAS ----------------

  Future<int> insertParcela(Parcela parcela) async {
    final db = await database;
    return await db.insert('parcelas', parcela.toMap());
  }

  Future<List<Parcela>> getParcelas() async {
    final db = await database;
    final maps = await db.query('parcelas', orderBy: 'nombre');
    return maps.map((map) => Parcela.fromMap(map)).toList();
  }

  Future<int> updateParcela(Parcela parcela) async {
    final db = await database;
    return await db.update(
      'parcelas',
      parcela.toMap(),
      where: 'id = ?',
      whereArgs: [parcela.id],
    );
  }

  Future<int> deleteParcela(int id) async {
    final db = await database;
    return await db.delete('parcelas', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- CULTIVOS ----------------

  Future<int> insertCultivo(Cultivo cultivo) async {
    final db = await database;
    return await db.insert('cultivos', cultivo.toMap());
  }

  Future<List<Cultivo>> getCultivos() async {
    final db = await database;
    final maps = await db.query('cultivos', orderBy: 'fecha_siembra DESC');
    return maps.map((map) => Cultivo.fromMap(map)).toList();
  }

  Future<List<Cultivo>> getCultivosPorParcela(int parcelaId) async {
    final db = await database;
    final maps = await db.query(
      'cultivos',
      where: 'parcela_id = ?',
      whereArgs: [parcelaId],
    );
    return maps.map((map) => Cultivo.fromMap(map)).toList();
  }

  Future<int> updateCultivo(Cultivo cultivo) async {
    final db = await database;
    return await db.update(
      'cultivos',
      cultivo.toMap(),
      where: 'id = ?',
      whereArgs: [cultivo.id],
    );
  }

  Future<int> deleteCultivo(int id) async {
    final db = await database;
    return await db.delete('cultivos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- RIEGO ----------------

  Future<int> insertRiego(RegistroRiego riego) async {
    final db = await database;
    return await db.insert('registros_riego', riego.toMap());
  }

  Future<List<RegistroRiego>> getRiegosPorCultivo(int cultivoId) async {
    final db = await database;
    final maps = await db.query(
      'registros_riego',
      where: 'cultivo_id = ?',
      whereArgs: [cultivoId],
      orderBy: 'fecha DESC',
    );
    return maps.map((map) => RegistroRiego.fromMap(map)).toList();
  }

  Future<int> deleteRiego(int id) async {
    final db = await database;
    return await db.delete('registros_riego', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- FERTILIZANTES ----------------

  Future<int> insertFertilizante(RegistroFertilizante fert) async {
    final db = await database;
    return await db.insert('registros_fertilizante', fert.toMap());
  }

  Future<List<RegistroFertilizante>> getFertilizantesPorCultivo(
    int cultivoId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'registros_fertilizante',
      where: 'cultivo_id = ?',
      whereArgs: [cultivoId],
      orderBy: 'fecha DESC',
    );
    return maps.map((map) => RegistroFertilizante.fromMap(map)).toList();
  }

  Future<int> deleteFertilizante(int id) async {
    final db = await database;
    return await db.delete(
      'registros_fertilizante',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- RIEGO POR MES (gráfico) ----------------

  Future<Map<String, double>> getAguaPorMes({int meses = 6}) async {
    final db = await database;

    final resultado = await db.rawQuery('''
      SELECT substr(fecha, 1, 7) AS mes, SUM(cantidad_agua) AS total
      FROM registros_riego
      GROUP BY mes
      ORDER BY mes DESC
      LIMIT $meses
    ''');

    final datos = <String, double>{};
    for (final fila in resultado.reversed) {
      datos[fila['mes'] as String] = (fila['total'] as num).toDouble();
    }
    return datos;
  }
}


