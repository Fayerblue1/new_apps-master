import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../models/article_response.dart';

class ApiException implements Exception {
  final String massage;
  final int? statusCode;

  ApiException(this.massage, [this.statusCode]);

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException (Status $statusCode): $massage';
    }
    return 'ApiException: $massage';
  }
}

class ArticleService {
  static const baseUrl =
      'https://ptzdkukkieyqbjigxlhi.supabase.co/functions/v1/api';

  // Key admin untuk POST, PUT, DELETE.
  static const apiKey = 'AyamGoreng123';

  static const headers = {'Content-Type': 'application/json', 'x-api-key': apiKey};

  // GET /articles?limit=50
  Future<List<Article>> getArticles() async {
    final uri = Uri.parse('$baseUrl/articles?limit=50');

    try {
      final response = await http.get(uri, headers: headers);
      final data = _decode(response);
      final articleResponse = ArticleResponse.fromJson(data);
      return articleResponse.articles;
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on http.ClientException {
      throw ApiException('Gagal menghubungkan ke server. Periksa jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // GET /articles?search={query}
  // Pada database Supabase, pencarian dieksekusi secara real-time menggunakan query:
  // .ilike('title', '%$query%')
  Future<List<Article>> searchArticles(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final uri = Uri.parse(
      '$baseUrl/articles?search=${Uri.encodeComponent(cleanQuery)}&limit=50',
    );

    try {
      final response = await http.get(uri, headers: headers);
      final data = _decode(response);
      final articleResponse = ArticleResponse.fromJson(data);
      return articleResponse.articles;
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on http.ClientException {
      throw ApiException('Gagal menghubungkan ke server. Periksa jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan saat mencari berita: $e');
    }
  }

  // GET /articles/{id}
  Future<Article> getArticle(dynamic id) async {
    final uri = Uri.parse('$baseUrl/articles/$id');

    try {
      final response = await http.get(uri, headers: headers);
      final body = _decode(response);
      return Article.fromJson(body['data'] ?? body);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on http.ClientException {
      throw ApiException('Gagal menghubungkan ke server. Periksa jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // POST /articles (butuh headers)
  Future<Article> createArticle(Article article) async {
    final uri = Uri.parse('$baseUrl/articles');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(article.toJson()),
      );

      final data = _decode(response);
      return Article.fromJson(data['data'] ?? data);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // PUT /articles/{id} (butuh headers)
  Future<Article> updateArticle(Article article) async {
    final uri = Uri.parse('$baseUrl/articles/${article.id}');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(article.toJson()),
      );

      final data = _decode(response);
      return Article.fromJson(data['data'] ?? data);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // DELETE /articles/{id} (butuh headers)
  Future<void> deleteArticle(dynamic id) async {
    final uri = Uri.parse('$baseUrl/articles/$id');

    try {
      final response = await http.delete(uri, headers: headers);
      _decode(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // Ubah response menjadi Map. Kalau gagal, lempar pesan error dari API.
  Map<String, dynamic> _decode(http.Response response) {
    final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      throw ApiException(body['message'] ?? 'Terjadi kesalahan pada server', response.statusCode);
    }
    return body;
  }
}
