// Mengimpor pustaka dasar Flutter, SQLite, and path
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Mengimpor model data Produk dan Karyawan
import '../models/produk.dart';
import '../models/karyawan.dart';

// Kelas Pengelola Basis Data Lokal SQLite (Pola Desain Singleton)
class DatabaseHelper {
  // Instansiasi tunggal statis
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter pembuka koneksi database aktif
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartkasir.db');
    await _seedIfNeeded(_database!);
    await _normalisasiGambarProduk(_database!);
    return _database!;
  }

  Future<void> _seedIfNeeded(Database db) async {
    final produkRow = await db.rawQuery('SELECT COUNT(*) as count FROM produk');
    final produkCount = (produkRow.first['count'] as int?) ?? 0;

    if (produkCount == 0) {
      for (final produk in produkAwalSQLite) {
        await db.insert('produk', produk.toMap());
      }
    }

    final karyawanRow = await db.rawQuery(
      'SELECT COUNT(*) as count FROM karyawan',
    );
    final karyawanCount = (karyawanRow.first['count'] as int?) ?? 0;

    if (karyawanCount == 0) {
      await db.rawInsert('''
        INSERT INTO karyawan (nama_karyawan, pin, peran)
        VALUES ('Ahmad Kasir', '1234', 'Kasir')
      ''');
      await db.rawInsert('''
        INSERT INTO karyawan (nama_karyawan, pin, peran)
        VALUES ('Siti Supervisor', '8888', 'Manajer')
      ''');
    }
  }

  Future<void> _normalisasiGambarProduk(Database db) async {
    final produkList = await db.query('produk');

    for (final row in produkList) {
      final nama = (row['nama_produk'] as String? ?? '').trim();
      final lower = nama.toLowerCase();
      String? gambarUrl;

      if (lower.contains('kopi')) {
        gambarUrl = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500';
      } else if (lower.contains('roti') || lower.contains('bakar')) {
        gambarUrl =
            'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500';
      } else if (lower.contains('matcha') || lower.contains('latte')) {
        gambarUrl =
            'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?w=500';
      } else if (lower.contains('nasi') && lower.contains('goreng')) {
        gambarUrl = 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500';
      } else if (lower.contains('keripik') || lower.contains('singkong')) {
        gambarUrl = 'https://images.unsplash.com/photo-1740993384870-0793845268e6?w=800';
      } else if (lower.contains('pisang') || lower.contains('goreng')) {
        gambarUrl = 'https://images.unsplash.com/photo-1762941904142-9d91ca413e66?w=800';
      }

      if (gambarUrl != null) {
        await db.update(
          'produk',
          {'gambar_path': gambarUrl},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  // Inisialisasi berkas basis data SQLite
  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createDB,
          onUpgrade: _onUpgradeDB,
        ),
      );
    } else {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
      );
    }
  }

  // DDL: Pembuatan Tabel Basis Data (Versi Baru)
  Future _createDB(Database db, int version) async {
    // HAPUS PAKSA TABEL LAMA AGAR CACHE BERSIH TOTAL DAN DATA TERBARU MASUK
    await db.execute('DROP TABLE IF EXISTS produk');
    await db.execute('DROP TABLE IF EXISTS karyawan');

    // 1. Pembuatan Tabel Produk
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 2. Pembuatan Tabel Karyawan
    await db.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    // 3. Memasukkan data produk awal otomatis (Seeding Data Awal Toko)
    for (final produk in produkAwalSQLite) {
      await db.insert('produk', produk.toMap());
    }

    // 4. Memasukkan data staf awal otomatis
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Ahmad Kasir', '1234', 'Kasir')
    ''');
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Siti Supervisor', '8888', 'Manajer')
    ''');
  }

  // DDL: Migrasi Skema jika versi basis data ditingkatkan
  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS karyawan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_karyawan TEXT NOT NULL,
          pin TEXT NOT NULL,
          peran TEXT NOT NULL
        )
      ''');

      final existingProduk = await db.query('produk');
      if (existingProduk.isEmpty) {
        for (final produk in produkAwalSQLite) {
          await db.insert('produk', produk.toMap());
        }
      }

      final existingKaryawan = await db.query('karyawan');
      if (existingKaryawan.isEmpty) {
        await db.rawInsert('''
          INSERT INTO karyawan (nama_karyawan, pin, peran)
          VALUES ('Ahmad Kasir', '1234', 'Kasir')
        ''');
        await db.rawInsert('''
          INSERT INTO karyawan (nama_karyawan, pin, peran)
          VALUES ('Siti Supervisor', '8888', 'Manajer')
        ''');
      }
    }
  }

  // ==========================================
  // METODE CRUD: TABEL KARYAWAN
  // ==========================================

  // 1. CREATE: Menyimpan Karyawan Baru
  Future<int> insertKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.insert('karyawan', karyawan.toMap());
  }

  // 2. READ: Mengambil Seluruh Karyawan
  Future<List<Karyawan>> getAllKaryawan() async {
    final db = await instance.database;
    final result = await db.query('karyawan', orderBy: 'id ASC');
    return result.map((json) => Karyawan.fromMap(json)).toList();
  }

  // 3. UPDATE: Memperbarui Data Karyawan
  Future<int> updateKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.update(
      'karyawan',
      karyawan.toMap(),
      where: 'id = ?',
      whereArgs: [karyawan.id],
    );
  }

  // 4. DELETE: Menghapus Karyawan Berdasarkan ID
  Future<int> deleteKaryawan(int id) async {
    final db = await instance.database;
    return await db.delete('karyawan', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // METODE CRUD: TABEL PRODUK (DARI MINGGU 11)
  // ==========================================

  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;
    return await db.insert('produk', produk.toMap());
  }

  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;
    final result = await db.query('produk', orderBy: 'id DESC');
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  Future<List<Produk>> getProdukByKategori(String kategori) async {
    final db = await instance.database;
    if (kategori == 'Semua') return await getAllProduk();
    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'id DESC',
    );
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  Future<List<Produk>> searchProduk(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'produk',
      where: 'nama_produk LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'id DESC',
    );
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;
    return await db.update(
      'produk',
      produk.toMap(includeCreatedAt: false),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  Future<int> deleteProduk(int id) async {
    final db = await instance.database;
    return await db.delete('produk', where: 'id = ?', whereArgs: [id]);
  }
}
