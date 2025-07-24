import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:loker_admin/utils/utils.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final ref = FirebaseDatabase.instance.ref('sewa_history');
  String filter = 'hari'; // opsi: hari, minggu, bulan
  List<Map<String, dynamic>> filteredData = [];

  Future<void> _exportToCSV(List<Map<String, dynamic>> data) async {
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Izin penyimpanan ditolak')));
      return;
    }

    final rows = [
      [
        'Tanggal',
        'Nama',
        'Email',
        'Lokasi',
        'Loker',
        'User ID',
        'Harga Total',
        'Durasi (Jam)',
      ],
    ];

    for (var item in data) {
      final millis = item['waktu_mulai'] is int
          ? item['waktu_mulai']
          : int.tryParse(item['waktu_mulai'].toString()) ?? 0;
      final tanggal = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(DateTime.fromMillisecondsSinceEpoch(millis));

      rows.add([
        tanggal,
        (item['user_nama'] ?? '-').toString(),
        (item['user_email'] ?? '-').toString(),
        (item['lokasi_id'] ?? '-').toString(),
        (item['loker_id'] ?? '-').toString(),
        (item['user_id'] ?? '-').toString(),
        (item['harga_total'] ?? 0).toString(),
        (item['durasi_jam'] ?? 0).toString(),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getExternalStorageDirectory();
    final filePath =
        '${dir!.path}/transaksi_${filter}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV berhasil disimpan ke:\n$filePath')),
    );
  }

  List<Map<String, dynamic>> applyFilter(Map<String, dynamic> rawData) {
    final now = DateTime.now().toUtc(); // Tambah .toUtc()
    final List<Map<String, dynamic>> list = [];

    for (final entry in rawData.entries) {
      final item = Map<String, dynamic>.from(entry.value);
      final millis = item['waktu_mulai'] is int
          ? item['waktu_mulai']
          : int.tryParse(item['waktu_mulai'].toString()) ?? 0;
      final waktu = DateTime.fromMillisecondsSinceEpoch(
        millis,
      ).toUtc(); // Tambah .toUtc()
      bool include = false;

      switch (filter) {
        case 'hari':
          include =
              waktu.day == now.day &&
              waktu.month == now.month &&
              waktu.year == now.year;
          break;
        case 'minggu':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          include =
              waktu.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              waktu.isBefore(endOfWeek.add(const Duration(days: 1)));
          break;
        case 'bulan':
          include = waktu.month == now.month && waktu.year == now.year;
          break;
      }

      if (include) list.add(item);
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
        actions: [
          PopupMenuButton<String>(
            initialValue: filter,
            onSelected: (val) => setState(() => filter = val),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'hari', child: Text('Hari Ini')),
              PopupMenuItem(value: 'minggu', child: Text('Minggu Ini')),
              PopupMenuItem(value: 'bulan', child: Text('Bulan Ini')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              if (filteredData.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tidak ada data untuk diekspor.'),
                  ),
                );
              } else {
                _exportToCSV(filteredData);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('Belum ada transaksi.'));
          }

          final rawData = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final data = applyFilter(rawData)
            ..sort((a, b) {
              final timeA = a['waktu_mulai'] ?? 0;
              final timeB = b['waktu_mulai'] ?? 0;
              return (timeB as int).compareTo(
                timeA as int,
              ); // dari terbaru ke terlama
            });
          filteredData = data;

          if (data.isEmpty) {
            return const Center(
              child: Text('Tidak ada transaksi sesuai filter.'),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = data[index];
              final millis = item['waktu_mulai'] is int
                  ? item['waktu_mulai']
                  : int.tryParse(item['waktu_mulai'].toString()) ?? 0;
              final tanggal = DateFormat(
                'dd MMM yyyy, HH:mm',
              ).format(DateTime.fromMillisecondsSinceEpoch(millis));

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    '${namaLoker(item['loker_id'])} - ${lokasiNicknameMap[item['lokasi_id']] ?? item['lokasi_id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'User: ${item['user_nama'] ?? '-'}\n'
                    'Email: ${item['user_email'] ?? '-'}\n'
                    'Tanggal: $tanggal\nDurasi: ${item['durasi_jam']} jam',
                  ),
                  trailing: Text(
                    'Rp ${item['harga_total']}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
