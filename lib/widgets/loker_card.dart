import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class LokerCard extends StatelessWidget {
  final String lokasi;
  final String lokerId;
  final String status;

  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  const LokerCard({
    super.key,
    required this.lokasi,
    required this.lokerId,
    required this.status,
    this.onOpen,
    this.onDelete,
  });

  void _bukaLoker(BuildContext context) async {
    try {
      await FirebaseService.bukaLoker(lokasi, lokerId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perintah buka loker $lokerId dikirim')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal buka loker: $e')));
    }
  }

  void _hapusSewa(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Sewa?'),
        content: Text('Yakin ingin menghapus sewa untuk loker $lokerId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseService.hapusSewa(lokasi, lokerId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sewa dihapus untuk loker $lokerId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal hapus sewa: $e')));
    }
  }

  void _kosongkanLoker(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan Loker?'),
        content: Text(
          'Yakin ingin menghapus penyewa dan mengosongkan loker $lokerId?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseService.kosongkanLoker(lokasi, lokerId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loker $lokerId berhasil dikosongkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengosongkan loker: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('Loker $lokerId'),
        subtitle: Text('Status: $status'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _bukaLoker(context),
              child: const Text('Buka'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _hapusSewa(context),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _kosongkanLoker(context),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Kosongkan'),
            ),
          ],
        ),
      ),
    );
  }
}
