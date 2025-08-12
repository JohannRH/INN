class Message {
  final String id;
  final String businessId;
  final String businessName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });
}