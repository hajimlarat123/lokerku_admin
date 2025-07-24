import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final _rtdb = FirebaseDatabase.instance.ref();
  static final _firestore = FirebaseFirestore.instance;

  /// 🔄 Stream semua status loker dari Realtime Database (sewa_aktif)
  static Stream<Map<String, dynamic>> getAllLokerStatus() {
    return _rtdb.child('sewa_aktif').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        return Map<String, dynamic>.from(raw as Map);
      } else {
        return {};
      }
    });
  }

  /// ❌ Hapus sewa aktif (admin)
  static Future<void> hapusSewa(String lokasiId, String lokerId) async {
    try {
      final path = 'sewa_aktif/$lokasiId/$lokerId';
      await _rtdb.child(path).remove();
      print('✅ Sewa berhasil dihapus: $path');
    } catch (e) {
      print('❌ Gagal hapus sewa: $e');
      rethrow;
    }
  }

  /// ✅ Perintah buka loker (admin & user)
  static Future<void> bukaLoker(String lokasi, String lokerId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'perintah_buka/$lokasi/$lokerId';

      await _rtdb.child(path).set({'user_id': 'admin', 'timestamp': timestamp});

      print('✅ Perintah buka dikirim ke: $path');
    } catch (e) {
      print('❌ Gagal kirim perintah buka: $e');
      rethrow;
    }
  }
  /// Hapus data penyewa dan set status ke 'kosong' (tanpa menghapus loker)
static Future<void> kosongkanLoker(String lokasiId, String lokerId) async {
  final path = 'sewa_aktif/$lokasiId/$lokerId';
  try {
    await _rtdb.child(path).update({
      'user_id': null,
      'expired_at': null,
      'status': 'kosong',
    });
    print('✅ Loker $lokasiId/$lokerId dikosongkan');
  } catch (e) {
    print('❌ Gagal mengosongkan loker: $e');
    rethrow;
  }
}


  /// 📜 Stream histori sewa (dari Firestore)
  static Stream<List<Map<String, dynamic>>> getSewaHistory() {
    return _firestore
        .collection('sewa_history')
        .orderBy('waktu', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// ➕ Tambahkan lokasi baru
  static Future<void> addLokasi(String lokasiId) async {
    final path = 'sewa_aktif/$lokasiId';
    await _rtdb.child(path).set({});
  }

  /// ➕ Tambahkan loker baru dalam lokasi tertentu
  static Future<void> addLoker(String lokasiId, String lokerId) async {
    final path = 'sewa_aktif/$lokasiId/$lokerId';
    await _rtdb.child(path).set({'status': 'kosong'});
  }
}
