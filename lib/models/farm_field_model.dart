class FarmField {
  final int id;
  final String name;
  final String city;
  final String county;
  final double area;
  final String plantName;

  FarmField({
    required this.id,
    required this.name,
    required this.city,
    required this.county,
    required this.area,
    required this.plantName,
  });

  // Backend'den gelen JSON verisini (Yazı) -> Dart Nesnesine çeviren fabrika
  factory FarmField.fromJson(Map<String, dynamic> json) {
    return FarmField(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'İsimsiz Tarla',
      city: json['city'] ?? '-',
      county: json['county'] ?? '-',
      area: (json['area'] ?? 0.0).toDouble(),
      plantName: json['plantName'] ?? 'Belirtilmemiş',
    );
  }
}
