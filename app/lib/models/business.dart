class Business {
  final String id;
  final String userId;
  final String name;
  final String? nit;
  final String? address;
  final String? description;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;
  final int? typeId;
  final int? categoryId;

  Business({
    required this.id,
    required this.userId,
    required this.name,
    this.nit,
    this.address,
    this.description,
    this.logoUrl,
    this.latitude,
    this.longitude,
    this.typeId,
    this.categoryId,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      nit: json['nit'],
      address: json['address'],
      description: json['description'],
      logoUrl: json['logo_url'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      typeId: json['type_id'],
      categoryId: json['category_id'],
    );
  }
}