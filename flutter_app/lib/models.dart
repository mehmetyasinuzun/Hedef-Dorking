class Dork {
  final int id;
  final String kategori;
  final String sorgu;
  final String aciklama;
  final List<String> etiketler;

  const Dork({
    required this.id,
    required this.kategori,
    required this.sorgu,
    required this.aciklama,
    required this.etiketler,
  });

  factory Dork.fromJson(Map<String, dynamic> json) => Dork(
        id: json['id'] as int,
        kategori: json['kategori'] as String,
        sorgu: json['sorgu'] as String,
        aciklama: json['aciklama'] as String,
        etiketler: (json['etiketler'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}
