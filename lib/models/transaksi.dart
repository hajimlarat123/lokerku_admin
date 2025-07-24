class Transaksi {
  final String orderId;
  final String userId;
  final String lokasiId;
  final String lokerId;
  final int durasiJam;
  final int totalHarga;
  final DateTime waktuMulai;
  final DateTime waktuSelesai;

  Transaksi({
    required this.orderId,
    required this.userId,
    required this.lokasiId,
    required this.lokerId,
    required this.durasiJam,
    required this.totalHarga,
    required this.waktuMulai,
    required this.waktuSelesai,
  });

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      orderId: map['orderId'],
      userId: map['userId'],
      lokasiId: map['lokasiId'],
      lokerId: map['lokerId'],
      durasiJam: map['durasiJam'],
      totalHarga: map['totalHarga'],
      waktuMulai: DateTime.parse(map['waktuMulai']),
      waktuSelesai: DateTime.parse(map['waktuSelesai']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'lokasiId': lokasiId,
      'lokerId': lokerId,
      'durasiJam': durasiJam,
      'totalHarga': totalHarga,
      'waktuMulai': waktuMulai.toIso8601String(),
      'waktuSelesai': waktuSelesai.toIso8601String(),
    };
  }
}
