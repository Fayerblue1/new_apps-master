class Comment {
  final dynamic id;
  final dynamic articleId;
  final String userName;
  final String commentText;
  final DateTime createdAt;

  Comment({
    required this.id,
    this.articleId,
    required this.userName,
    required this.commentText,
    required this.createdAt,
  });

  // Getter kompatibilitas nama lama
  String get name => userName;
  String get content => commentText;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      articleId: json['article_id'] ?? json['articleId'],
      userName: json['user_name'] ?? json['userName'] ?? json['name'] ?? 'Anonim',
      commentText: json['comment_text'] ?? json['commentText'] ?? json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (articleId != null) 'article_id': articleId,
      'user_name': userName,
      'name': userName,
      'comment_text': commentText,
      'content': commentText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
