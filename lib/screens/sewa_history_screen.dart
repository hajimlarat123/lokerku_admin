import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../utils/utils.dart';

class SewaHistoryScreen extends StatelessWidget {
  const SewaHistoryScreen({super.key});

  String formatWaktu(dynamic millisRaw) {
    final millis = millisRaw is int
        ? millisRaw
        : int.tryParse(millisRaw.toString()) ?? 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('dd MMM yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('sewa_history');

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Penyewaan')),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('Belum ada riwayat penyewaan.'));
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final items = data.entries.toList()
            ..sort(
              (a, b) => (int.tryParse(b.value['waktu_mulai'].toString()) ?? 0)
                  .compareTo(
                    int.tryParse(a.value['waktu_mulai'].toString()) ?? 0,
                  ),
            );

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = Map<String, dynamic>.from(items[index].value);
              final lokasi = item['lokasi_id'] ?? '-';
              final lokasiLabel = lokasiNicknameMap[lokasi] ?? lokasi;
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text('${namaLoker(item['loker_id'])} - $lokasiLabel'),
                subtitle: Text(
                  'User: ${item['user_nama'] ?? '-'}\n'
                  'Email: ${item['user_email'] ?? '-'}\n'
                  'Mulai: ${formatWaktu(item['waktu_mulai'])}\n'
                  'Durasi: ${item['durasi_jam']} jam',
                ),
                trailing: Text('Rp ${item['harga_total']}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
