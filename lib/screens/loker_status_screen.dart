import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/utils.dart';

class LokerStatusScreen extends StatefulWidget {
  const LokerStatusScreen({super.key});

  @override
  State<LokerStatusScreen> createState() => _LokerStatusScreenState();
}

class _LokerStatusScreenState extends State<LokerStatusScreen> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref('sewa_aktif');

  void _konfirmasiBukaLoker({
    required String lokasi,
    required String loker,
    required int expiredAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    if (now < expiredAt + 5 * 60 * 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum 5 menit setelah masa sewa habis')),
      );
      return;
    }

    final TextEditingController alasanController = TextEditingController();

    final alasan = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Buka Loker'),
        content: TextField(
          controller: alasanController,
          decoration: const InputDecoration(labelText: 'Alasan membuka loker'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, alasanController.text.trim());
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (alasan == null || alasan.isEmpty) return;

    await FirebaseDatabase.instance.ref('perintah_buka/$lokasi/$loker').set({
      'perintah': true,
      'user_id': adminUid,
      'aktivitas': 'admin_buka',
      'timestamp': now,
    });

    await FirebaseDatabase.instance.ref('log_admin_buka_loker').push().set({
      'admin_id': adminUid,
      'lokasi_id': lokasi,
      'loker_id': loker,
      'alasan': alasan,
      'timestamp': now,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perintah buka loker dikirim')),
    );
  }

  void _hapusLoker(String lokasi, String loker) async {
    await ref.child('$lokasi/$loker').remove();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loker $loker di $lokasi telah dihapus.')),
    );
  }

  void _kosongkanLoker(String lokasi, String loker) async {
    final lokerRef = ref.child('$lokasi/$loker');

    // Hapus seluruh data loker dulu
    await lokerRef.remove();

    // Tulis ulang hanya dengan status kosong
    await lokerRef.set({'status': 'kosong'});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Loker $loker telah dikosongkan.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Semua Loker')),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('Belum ada data loker.'));
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          return ListView(
            padding: const EdgeInsets.all(12),
            children: data.entries.map((lokasiEntry) {
              final lokasiId = lokasiEntry.key;
              final lokasiLabel = lokasiNicknameMap[lokasiId] ?? lokasiId;
              final lokers = Map<String, dynamic>.from(lokasiEntry.value);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lokasiLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...lokers.entries.map((lokerEntry) {
                    final lokerId = lokerEntry.key;
                    final info = Map<String, dynamic>.from(lokerEntry.value);
                    final status = info['status'] ?? 'unknown';
                    final expiredAt =
                        int.tryParse(info['expired_at'].toString()) ?? 0;
                    final now = DateTime.now().millisecondsSinceEpoch;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  namaLoker(lokerId),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const Spacer(),
                                Text(
                                  status == 'kosong' ? 'Kosong' : 'Terisi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status == 'kosong'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed:
                                      (status == 'terisi' && now > expiredAt)
                                      ? () => _konfirmasiBukaLoker(
                                          lokasi: lokasiId,
                                          loker: lokerId,
                                          expiredAt: expiredAt,
                                        )
                                      : null,
                                  icon: const Icon(Icons.lock_open),
                                  label: const Text('Buka'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _hapusLoker(lokasiId, lokerId),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Hapus'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _kosongkanLoker(lokasiId, lokerId),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Kosongkan'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const Divider(height: 40, thickness: 1),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
