class Loker {
  final String lokasiId;
  final String lokerId;
  final String status; // "kosong", "terisi", "rusak", dsb
  final String? userId; // jika sedang disewa
  final DateTime? expiredAt;

  Loker({
    required this.lokasiId,
    required this.lokerId,
    required this.status,
    this.userId,
    this.expiredAt,
  });

  factory Loker.fromMap(Map<String, dynamic> map) {
    return Loker(
      lokasiId: map['lokasiId'],
      lokerId: map['lokerId'],
      status: map['status'],
      userId: map['userId'],
      expiredAt: map['expiredAt'] != null
          ? DateTime.parse(map['expiredAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lokasiId': lokasiId,
      'lokerId': lokerId,
      'status': status,
      'userId': userId,
      'expiredAt': expiredAt?.toIso8601String(),
    };
  }
}
