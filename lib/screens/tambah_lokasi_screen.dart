import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahLokasiScreen extends StatefulWidget {
  const TambahLokasiScreen({super.key});

  @override
  State<TambahLokasiScreen> createState() => _TambahLokasiScreenState();
}

class _TambahLokasiScreenState extends State<TambahLokasiScreen> {
  final TextEditingController lokasiController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController lokerController = TextEditingController();
  bool isLoading = false;

  void _tambahLoker() async {
    final lokasi = lokasiController.text.trim();
    final nickname = nicknameController.text.trim();
    final loker = lokerController.text.trim();

    if (lokasi.isEmpty || loker.isEmpty || nickname.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final db = FirebaseDatabase.instance.ref();

      await db.child('sewa_aktif/$lokasi/$loker').set({'status': 'kosong'});

      await db.child('lokasi_nickname/$lokasi').set(nickname);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loker & lokasi berhasil ditambahkan.')),
      );

      lokasiController.clear();
      lokerController.clear();
      nicknameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menambahkan loker.')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Lokasi & Loker Baru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: lokasiController,
            decoration: const InputDecoration(
              labelText: 'ID Lokasi (ex: lokasi04)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nicknameController,
            decoration: const InputDecoration(
              labelText: 'Nama Lokasi (Nickname)',
              hintText: 'Contoh: Mall Olympic Garden',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lokerController,
            decoration: const InputDecoration(
              labelText: 'ID Loker (ex: lokerA)',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : _tambahLoker,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Tambah Loker'),
          ),
        ],
      ),
    );
  }
}
