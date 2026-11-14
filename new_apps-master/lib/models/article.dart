import 'author.dart';

class Article {
  final dynamic id;
  final String title;
  final String? summary;
  final String content;
  final String? imageUrl;
  final String category;
  final String authorName;
  final bool isBreaking;
  final DateTime? createdAt;
  final int? categoryId;
  final Author author;

  Article({
    required this.id,
    required this.title,
    this.summary,
    required this.content,
    String? imageUrl,
    String? thumbnailUrl,
    String? category,
    String? authorName,
    this.isBreaking = false,
    this.createdAt,
    this.categoryId,
    Author? author,
  })  : imageUrl = imageUrl ?? thumbnailUrl,
        category = category ?? 'Umum',
        authorName = authorName ?? author?.name ?? 'Redaksi',
        author = author ??
            Author(
              id: 1,
              name: authorName ?? 'Redaksi',
              avatarUrl: null,
            );

  // Getter kompatibilitas kode lama
  String? get thumbnailUrl => imageUrl;
  String get categoryName => category;

  factory Article.fromJson(Map<String, dynamic> json) {
    // 1. Ambil category
    final cat = json['category'];
    String categoryStr = 'Umum';
    int? catId;
    if (cat is String) {
      categoryStr = cat;
    } else if (cat is Map) {
      categoryStr = cat['name'] ?? 'Umum';
      catId = cat['id'] is int ? cat['id'] : int.tryParse(cat['id']?.toString() ?? '');
    }

    // 2. Ambil author
    final auth = json['author'];
    String authorStr = json['author_name'] ?? 'Redaksi';
    Author? authorObj;
    if (auth is Map<String, dynamic>) {
      authorObj = Author.fromJson(auth);
      authorStr = auth['name'] ?? authorStr;
    } else if (auth is String) {
      authorStr = auth;
    }

    // 3. Ambil created_at / published_at
    DateTime? parsedDate;
    final dateRaw = json['created_at'] ?? json['published_at'];
    if (dateRaw != null) {
      parsedDate = DateTime.tryParse(dateRaw.toString());
    }

    // 4. Ambil image_url / thumbnail_url
    final img = json['image_url'] ?? json['thumbnail_url'] ?? json['imageUrl'];

    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'],
      content: json['content'] ?? json['summary'] ?? '',
      imageUrl: img,
      category: categoryStr,
      authorName: authorStr,
      isBreaking: json['is_breaking'] == true || json['isBreaking'] == true,
      createdAt: parsedDate,
      categoryId: json['category_id'] is int
          ? json['category_id']
          : (catId ?? 1),
      author: authorObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'image_url': imageUrl,
      'thumbnail_url': imageUrl,
      'category': category,
      'category_id': categoryId ?? 1,
      'author_name': authorName,
      'author_id': author.id,
      'is_breaking': isBreaking,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
