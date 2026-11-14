import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../services/article_service.dart';

// Provider service API
final articleServiceProvider = Provider((ref) => ArticleService());

// Mengambil seluruh artikel
final articlesProvider = FutureProvider<List<Article>>((ref) {
  final service = ref.watch(articleServiceProvider);
  return service.getArticles();
});

// Mengambil satu artikel berdasarkan id
final articleProvider = FutureProvider.family<Article, dynamic>((ref, id) {
  final service = ref.watch(articleServiceProvider);
  return service.getArticle(id);
});

// Provider pencarian artikel secara real-time
final searchArticlesProvider =
    FutureProvider.family<List<Article>, String>((ref, query) async {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return [];
  final service = ref.watch(articleServiceProvider);
  return service.searchArticles(cleanQuery);
});

// Notifier untuk kategori aktif
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Semua';

  void setCategory(String category) {
    state = category;
  }
}

// State kategori yang sedang aktif ('Semua', 'Teknologi', 'Bisnis', 'Olahraga', 'Hiburan', dll.)
final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

// Notifier untuk ukuran font artikel
class ArticleFontSizeNotifier extends Notifier<double> {
  @override
  double build() => 16.0;

  void setFontSize(double size) {
    state = size;
  }

  void increase() {
    state = (state + 2).clamp(12.0, 26.0);
  }

  void decrease() {
    state = (state - 2).clamp(12.0, 26.0);
  }
}

// State ukuran font untuk pembacaan artikel di Halaman Detail (default: 16.0)
final articleFontSizeProvider =
    NotifierProvider<ArticleFontSizeNotifier, double>(ArticleFontSizeNotifier.new);
