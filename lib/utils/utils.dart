Map<String, String> lokasiNicknameMap = {
  'lokasi01': 'Terminal Arjosari',
  'lokasi02': 'Stasiun Malang Kota Baru',
  'lokasi03': 'Malang Town Square',
};

String namaLoker(String lokerId) {
  if (lokerId.startsWith('loker') && lokerId.length > 5) {
    return 'Loker ${lokerId.substring(5).toUpperCase()}';
  }
  return lokerId;
}
