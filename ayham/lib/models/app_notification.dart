class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduledDate': scheduledDate.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      scheduledDate: DateTime.parse(json['scheduledDate']),
    );
  }
}
