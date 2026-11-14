import 'article.dart';

// Pembungkus response GET /articles
class ArticleResponse {
  final bool success;
  final String message;
  final List<Article> articles;

  ArticleResponse({
    required this.success,
    required this.message,
    required this.articles,
  });

  factory ArticleResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] ?? json['articles'] ?? [];
    final List list = rawList is List ? rawList : [];

    return ArticleResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'OK',
      articles: list
          .whereType<Map<String, dynamic>>()
          .map((item) => Article.fromJson(item))
          .toList(),
    );
  }
}
