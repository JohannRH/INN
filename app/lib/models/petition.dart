enum PetitionStatus { pending, responded, completed }

class Petition {
  final String id;
  final String userId;
  final int? categoryId;
  final String title;
  final String? description;
  final DateTime createdAt;
  final PetitionStatus status;
  final String? imageUrl;

  Petition({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.description,
    required this.createdAt,
    required this.status,
    this.imageUrl,
  });

  factory Petition.fromJson(Map<String, dynamic> json) {
    return Petition(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'] as int?,
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      status: _mapStatus(json['status']),
      imageUrl: json['image_url'],
    );
  }

  static PetitionStatus _mapStatus(String status) {
    switch (status) {
      case 'pendiente':
        return PetitionStatus.pending;
      case 'respondida':
        return PetitionStatus.responded;
      case 'finalizada':
        return PetitionStatus.completed;
      default:
        return PetitionStatus.pending;
    }
  }
}