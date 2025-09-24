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
  final String? typeName;
  final int? categoryId;
  final String? categoryName;
  final Map<String, dynamic>? openingHours;

  final String? phone;
  final String? email;

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
    this.typeName,
    this.categoryId,
    this.categoryName,
    this.openingHours,
    this.phone,
    this.email,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    final businessType = json['business_types'];
    final category = businessType?['business_categories'];
    
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
      typeName: businessType?['name'],
      categoryId: json['category_id'],
      categoryName: category?['name'],

      openingHours: json['opening_hours'] != null
          ? Map<String, dynamic>.from(json['opening_hours'])
          : null,

      phone: json['profiles']?['phone'],
      email: json['profiles']?['email'],
    );
  }
}