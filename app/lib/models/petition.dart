enum PetitionStatus { pending, responded, completed }

class Petition {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;
  final PetitionStatus status;
  final int responseCount;
  final double? budget;

  Petition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.status,
    required this.responseCount,
    this.budget,
  });
}