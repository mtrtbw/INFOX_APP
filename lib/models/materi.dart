class Materi {
  final String id;
  final String judul;
  final String deskripsi;

  Materi({
    required this.id,
    required this.judul,
    required this.deskripsi,
  });

  factory Materi.fromJson(Map<String, dynamic> json) {
    return Materi(
      id: json['id_materi'],
      judul: json['judul'],
      deskripsi: json['deskripsi'],
    );
  }
}
