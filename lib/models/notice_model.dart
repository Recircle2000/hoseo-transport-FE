class Notice {
  final int id;
  final String title;
  final String content;
  final String noticeType;
  final DateTime createdAt;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.noticeType,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      noticeType: json['notice_type'] ?? 'App',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}