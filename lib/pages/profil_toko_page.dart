
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Database Helper untuk menghitung jumlah pelanggan
import '../helpers/database_helper.dart';

// Import halaman kelola karyawan dan pelanggan
import 'kelola_karyawan_page.dart';
import 'kelola_pelanggan_page.dart';

// Halaman Pengaturan Profil Toko & Footer Struk Kasir
class ProfilTokoPage extends StatefulWidget {
  const ProfilTokoPage({super.key});

  @override
  State<ProfilTokoPage> createState() => _ProfilTokoPageState();
}

class _ProfilTokoPageState extends State<ProfilTokoPage> {
  // Controller formulir pengaturan identitas toko
  final _namaTokoController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noWaController = TextEditingController();
  final _footerController = TextEditingController();

  // Status visual tombol simpan
  bool _sedangMenyimpan = false;

  // Nama kasir aktif
  String _activeCashierName = 'Belum Ditentukan';

  // Future untuk menghitung jumlah pelanggan dari database
  late Future<int> _jumlahPelangganFuture;

  // Warna tema aplikasi
  static const Color warnaPink = Color(0xFFE91E63);
  static const Color warnaPinkMuda = Color(0xFFF8BBD0);
  static const Color warnaBackground = Color(0xFFFFF5F8);

  @override
  void initState() {
    super.initState();

    _muatProfilToko();

    // Mengambil jumlah pelanggan dari SQLite
    _jumlahPelangganFuture =
        DatabaseHelper.instance.countPelanggan();
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _alamatController.dispose();
    _noWaController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  // MEMUAT ULANG JUMLAH PELANGGAN
  void _muatJumlahPelanggan() {
    setState(() {
      _jumlahPelangganFuture =
          DatabaseHelper.instance.countPelanggan();
    });
  }

  // MEMBACA PENGATURAN TOKO DARI SHAREDPREFERENCES
  Future<void> _muatProfilToko() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _namaTokoController.text =
          prefs.getString('nama_toko') ?? 'SmartKasir Poliban';

      _alamatController.text =
          prefs.getString('alamat_toko') ??
          'Jl. Brigjend H. Hasan Basry, Banjarmasin';

      _noWaController.text =
          prefs.getString('no_wa') ?? '081234567890';

      _footerController.text =
          prefs.getString('footer_struk') ??
          'Terima Kasih Atas Kunjungan Anda! Barang yang sudah dibeli tidak dapat ditukar.';

      _activeCashierName =
          prefs.getString('active_cashier_name') ??
          'Belum Ditentukan';
    });
  }

  // MENYIMPAN PENGATURAN TOKO
  Future<void> _simpanProfilToko() async {
    setState(() => _sedangMenyimpan = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'nama_toko',
        _namaTokoController.text.trim(),
      );

      await prefs.setString(
        'alamat_toko',
        _alamatController.text.trim(),
      );

      await prefs.setString(
        'no_wa',
        _noWaController.text.trim(),
      );

      await prefs.setString(
        'footer_struk',
        _footerController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Identitas toko berhasil diperbarui!',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pengaturan: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sedangMenyimpan = false);
      }
    }
  }

  // KOMPONEN DEKORASI INPUT FORM
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: warnaPink),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: warnaPinkMuda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: warnaPink,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // KOMPONEN DEKORASI KARTU
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: warnaPinkMuda),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warnaBackground,

      // APP BAR
      appBar: AppBar(
        title: const Text(
          'Profil & Pengaturan Toko',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: warnaPink,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // KARTU RINGKASAN KASIR BERTUGAS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: warnaPink,
                    child: Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KASIR AKTIF SHIFT INI',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _activeCashierName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const KelolaKaryawanPage(),
                        ),
                      );

                      _muatProfilToko();
                    },
                    icon: const Icon(
                      Icons.people_outline,
                      size: 16,
                    ),
                    label: const Text('Kelola'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: warnaPink,
                      side: const BorderSide(
                        color: warnaPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // MENU DATA PELANGGAN & COUNTER JUMLAH MEMBER
            Container(
              decoration: _cardDecoration(),
              child: ListTile(
                leading: const CircleAvatar(
                  radius: 20,
                  backgroundColor: warnaPink,
                  child: Icon(
                    Icons.people_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                title: const Text(
                  'Data Pelanggan & Lokasi GPS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                // COUNTER JUMLAH PELANGGAN DARI DATABASE SQLITE
                subtitle: FutureBuilder<int>(
                  future: _jumlahPelangganFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Text(
                        'Memuat jumlah pelanggan...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Text(
                        'Gagal memuat jumlah pelanggan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      );
                    }

                    final jumlahPelanggan = snapshot.data ?? 0;

                    return Text(
                      '$jumlahPelanggan Member Pelanggan Terdaftar',
                      style: const TextStyle(
                        fontSize: 12,
                        color: warnaPink,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                  color: warnaPink,
                ),

                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const KelolaPelangganPage(),
                    ),
                  );

                  // Memperbarui counter setelah kembali
                  if (mounted) {
                    _muatJumlahPelanggan();
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            // JUDUL FORM IDENTITAS USAHA
            const Text(
              'IDENTITAS USAHA & STRUK KASIR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: warnaPink,
              ),
            ),

            const SizedBox(height: 12),

            // 1. NAMA TOKO
            TextFormField(
              controller: _namaTokoController,
              decoration: _inputDecoration(
                label: 'Nama Toko / Usaha',
                icon: Icons.store,
              ),
            ),

            const SizedBox(height: 14),

            // 2. ALAMAT TOKO
            TextFormField(
              controller: _alamatController,
              maxLines: 2,
              decoration: _inputDecoration(
                label: 'Alamat Toko',
                icon: Icons.location_on_outlined,
              ),
            ),

            const SizedBox(height: 14),

            // 3. KONTAK WHATSAPP
            TextFormField(
              controller: _noWaController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                label: 'Nomor WhatsApp / Kontak Toko',
                icon: Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 14),

            // 4. CATATAN KAKI STRUK
            TextFormField(
              controller: _footerController,
              maxLines: 2,
              decoration: _inputDecoration(
                label: 'Catatan Kaki Struk (Footer Nota)',
                icon: Icons.receipt_outlined,
                hint: 'Contoh: Terima kasih atas kunjungan Anda!',
              ),
            ),

            const SizedBox(height: 24),

            // TOMBOL SIMPAN PENGATURAN
            ElevatedButton.icon(
              onPressed: _sedangMenyimpan
                  ? null
                  : _simpanProfilToko,

              style: ElevatedButton.styleFrom(
                backgroundColor: warnaPink,
                disabledBackgroundColor: warnaPinkMuda,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              icon: _sedangMenyimpan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),

              label: Text(
                _sedangMenyimpan
                    ? 'Menyimpan Pengaturan...'
                    : 'Simpan Profil Toko',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
