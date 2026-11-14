import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';

class BookmarkNotifier extends Notifier<List<Article>> {
  static const _storageKey = 'bookmarked_article_ids';
  static const _dataKey = 'bookmarked_articles_cache';

  @override
  List<Article> build() {
    _loadBookmarks();
    return [];
  }

  /// Memuat daftar artikel tersimpan dari SharedPreferences lokal
  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawData = prefs.getString(_dataKey);
      if (rawData != null && rawData.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(rawData);
        final list = decoded.values
            .whereType<Map<String, dynamic>>()
            .map((item) => Article.fromJson(item))
            .toList();
        state = list;
      }
    } catch (_) {
      // Abaikan jika cache rusak/kosong
    }
  }

  /// Cek apakah suatu artikel sudah tersimpan
  bool isBookmarked(dynamic id) {
    final idStr = id.toString();
    return state.any((a) => a.id.toString() == idStr);
  }

  /// Toggle simpan/hapus bookmark. Mengembalikan true jika ditambahkan, false jika dihapus.
  Future<bool> toggleBookmark(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final idStr = article.id.toString();
    final currentList = List<Article>.from(state);

    final isAlreadySaved = currentList.any((a) => a.id.toString() == idStr);
    bool added;

    if (isAlreadySaved) {
      currentList.removeWhere((a) => a.id.toString() == idStr);
      added = false;
    } else {
      currentList.insert(0, article);
      added = true;
    }

    state = currentList;

    // Simpan ke SharedPreferences
    final idList = currentList.map((a) => a.id.toString()).toList();
    final Map<String, dynamic> cacheMap = {
      for (final a in currentList) a.id.toString(): a.toJson(),
    };

    await prefs.setStringList(_storageKey, idList);
    await prefs.setString(_dataKey, jsonEncode(cacheMap));

    return added;
  }

  /// Hapus bookmark berdasarkan ID
  Future<void> removeBookmark(dynamic id) async {
    final idStr = id.toString();
    final currentList = List<Article>.from(state);
    currentList.removeWhere((a) => a.id.toString() == idStr);
    state = currentList;

    final prefs = await SharedPreferences.getInstance();
    final idList = currentList.map((a) => a.id.toString()).toList();
    final Map<String, dynamic> cacheMap = {
      for (final a in currentList) a.id.toString(): a.toJson(),
    };

    await prefs.setStringList(_storageKey, idList);
    await prefs.setString(_dataKey, jsonEncode(cacheMap));
  }
}

final bookmarkProvider =
    NotifierProvider<BookmarkNotifier, List<Article>>(BookmarkNotifier.new);

