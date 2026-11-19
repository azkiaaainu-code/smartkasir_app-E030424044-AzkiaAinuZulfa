
// Mengimpor pustaka antarmuka Flutter Material 3
import 'package:flutter/material.dart';

// Mengimpor pustaka geolocator untuk mengakses sensor GPS hardware
import 'package:geolocator/geolocator.dart';

// Mengimpor format waktu internasional
import 'package:intl/intl.dart';

// Mengimpor model data Pelanggan dan pembantu database SQLite
import '../models/pelanggan.dart';
import '../helpers/database_helper.dart';

// Halaman formulir dwifungsi: Tambah Pelanggan Baru & Edit Data Pelanggan
class FormPelangganPage extends StatefulWidget {
  final Pelanggan? pelanggan;

  const FormPelangganPage({super.key, this.pelanggan});

  @override
  State<FormPelangganPage> createState() => _FormPelangganPageState();
}

class _FormPelangganPageState extends State<FormPelangganPage> {
  // Palet warna pink SmartKasir
  static const Color pinkUtama = Color(0xFFE91E63);
  static const Color pinkGelap = Color(0xFFC2185B);
  static const Color pinkMuda = Color(0xFFFCE4EC);
  static const Color latarPink = Color(0xFFFFF5F8);
  static const Color pinkBorder = Color(0xFFF8BBD0);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  late TextEditingController _nomorWaController;
  late TextEditingController _alamatController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();

    final isEdit = widget.pelanggan != null;

    final autoKode =
        'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    _kodeController = TextEditingController(
      text: isEdit ? widget.pelanggan!.kodePelanggan : autoKode,
    );

    _namaController = TextEditingController(
      text: isEdit ? widget.pelanggan!.namaPelanggan : '',
    );

    _nomorWaController = TextEditingController(
      text: isEdit ? widget.pelanggan!.nomorWa : '',
    );

    _alamatController = TextEditingController(
      text: isEdit ? widget.pelanggan!.alamat : '',
    );

    _latitudeController = TextEditingController(
      text: isEdit && widget.pelanggan!.latitude != null
          ? widget.pelanggan!.latitude.toString()
          : '',
    );

    _longitudeController = TextEditingController(
      text: isEdit && widget.pelanggan!.longitude != null
          ? widget.pelanggan!.longitude.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _nomorWaController.dispose();
    _alamatController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    super.dispose();
  }

  // Fungsi mengambil koordinat GPS
  Future<void> _ambilKoordinatGps() async {
    setState(() {
      _isLoadingGps = true;
    });

    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Layanan GPS perangkat belum aktif. Silakan aktifkan GPS Anda.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin akses lokasi ditolak oleh pengguna.',
              ),
              backgroundColor: Colors.red,
            ),
          );

          setState(() => _isLoadingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() => _isLoadingGps = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitudeController.text =
            position.latitude.toStringAsFixed(6);

        _longitudeController.text =
            position.longitude.toStringAsFixed(6);

        _isLoadingGps = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Titik GPS berhasil dikunci: '
            '(${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)})',
          ),
          backgroundColor: pinkGelap,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingGps = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil koordinat GPS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi menyimpan data pelanggan ke SQLite
  Future<void> _simpanPelanggan() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.pelanggan != null;

    final now = DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now());

    final double? lat =
        double.tryParse(_latitudeController.text.trim());

    final double? lng =
        double.tryParse(_longitudeController.text.trim());

    final pelangganBaru = Pelanggan(
      id: isEdit ? widget.pelanggan!.id : null,
      kodePelanggan: _kodeController.text.trim(),
      namaPelanggan: _namaController.text.trim(),
      nomorWa: _nomorWaController.text.trim(),
      alamat: _alamatController.text.trim(),
      latitude: lat,
      longitude: lng,
      createdAt: isEdit ? widget.pelanggan!.createdAt : now,
    );

    try {
      if (isEdit) {
        await DatabaseHelper.instance.updatePelanggan(
          pelangganBaru,
        );
      } else {
        await DatabaseHelper.instance.insertPelanggan(
          pelangganBaru,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Data pelanggan berhasil diperbarui!'
                  : 'Pelanggan baru berhasil ditambahkan!',
            ),
            backgroundColor: pinkGelap,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan saat menyimpan: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dekorasi standar seluruh input
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: pinkGelap),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: pinkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: pinkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: pinkUtama,
          width: 1.8,
        ),
      ),
      floatingLabelStyle: const TextStyle(
        color: pinkGelap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pelanggan != null;

    return Scaffold(
      backgroundColor: latarPink,
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Edit Data Pelanggan'
              : 'Tambah Pelanggan Baru',
        ),
        backgroundColor: pinkUtama,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner panduan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pinkMuda,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: pinkBorder),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: pinkGelap,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rekam nomor WhatsApp untuk pengiriman nota digital dan simpan titik koordinat GPS untuk rute pengantaran pesanan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D2945),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kode pelanggan
              TextFormField(
                controller: _kodeController,
                decoration: _inputDecoration(
                  label: 'Kode Member / ID Pelanggan *',
                  hint: 'Contoh: CUST-001',
                  icon: Icons.badge_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kode pelanggan tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Nama pelanggan
              TextFormField(
                controller: _namaController,
                decoration: _inputDecoration(
                  label: 'Nama Lengkap Pelanggan / Mitra Usaha *',
                  hint: 'Contoh: Warung Berkah Ibu Rini',
                  icon: Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama pelanggan wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Nomor WhatsApp
              TextFormField(
                controller: _nomorWaController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  label: 'Nomor Kontak WhatsApp *',
                  hint: 'Contoh: 081234567890 atau 628...',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor WhatsApp wajib diisi';
                  }

                  if (value.trim().length < 9) {
                    return 'Nomor telepon tidak valid (terlalu pendek)';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Alamat pelanggan
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                decoration: _inputDecoration(
                  label: 'Alamat Domisili / Pengantaran Barang *',
                  hint:
                      'Contoh: Jl. Kayu Tangi 1 Jalur 2 No. 15, Banjarmasin',
                  icon: Icons.home_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat pelanggan wajib diisi untuk logistik';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Bagian GPS
              Card(
                elevation: 1,
                color: const Color(0xFFFFF0F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: pinkBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: pinkUtama,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Titik Lokasi Pengantaran (GPS Satelit)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF831843),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Ambil posisi saat ini jika Anda berada di lokasi fisik rumah/toko pelanggan:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B6474),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tombol GPS
                      ElevatedButton.icon(
                        onPressed: _isLoadingGps
                            ? null
                            : _ambilKoordinatGps,
                        icon: _isLoadingGps
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          _isLoadingGps
                              ? 'Mengunci Koordinat Satelit GPS...'
                              : 'Ambil Koordinat GPS Saat Ini',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pinkUtama,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Latitude dan Longitude
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: _inputDecoration(
                                label: 'Latitude',
                                icon: Icons.my_location,
                                hint: '-3.298280',
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: _inputDecoration(
                                label: 'Longitude',
                                icon: Icons.explore_outlined,
                                hint: '114.588820',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tombol simpan
              ElevatedButton(
                onPressed: _simpanPelanggan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pinkUtama,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEdit
                      ? 'Perbarui Data Pelanggan'
                      : 'Simpan Pelanggan Baru',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
