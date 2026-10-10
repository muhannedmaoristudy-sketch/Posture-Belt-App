class PostureAlert {
  final int? id;
  final DateTime timestamp;

  PostureAlert({
    this.id,
    required this.timestamp,
  });

  // تحويل البيانات إلى شكل يقبله SQLite (Map)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // تحويل البيانات المسترجعة من SQLite إلى كائن PostureAlert
  factory PostureAlert.fromMap(Map<String, dynamic> map) {
    return PostureAlert(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
