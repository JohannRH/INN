class Business {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final double distance;
  final String imageUrl;
  final double rating;
  final bool isOpen;
  final List<String> tags;

  Business({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.distance,
    required this.imageUrl,
    required this.rating,
    required this.isOpen,
    required this.tags,
  });
}