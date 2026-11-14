import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smartkasir_app/helpers/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database should seed initial products with image URLs', () async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('produk');

    expect(
      result,
      isNotEmpty,
      reason:
          'Tabel produk harus berisi data awal agar gambar produk tersedia.',
    );

    for (final row in result) {
      final imagePath = (row['gambar_path'] as String?)?.trim() ?? '';
      expect(
        imagePath,
        isNotEmpty,
        reason: 'Setiap produk awal harus punya URL gambar yang valid.',
      );
    }

    final imageByCode = {
      for (final row in result)
        row['kode_produk'] as String: row['gambar_path'] as String,
    };

    expect(
      imageByCode['PRD-005'],
      'https://images.unsplash.com/photo-1740993384870-0793845268e6?w=800',
    );
    expect(
      imageByCode['PRD-006'],
      'https://images.unsplash.com/photo-1762941904142-9d91ca413e66?w=800',
    );
  });
}
