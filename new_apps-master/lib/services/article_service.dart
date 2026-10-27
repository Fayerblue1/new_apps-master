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
  static const baseUrl = 'https://knlhpjkhujzjyzrmxfjj.supabase.co/functions/v1/api';

  // Key admin untuk POST, PUT, DELETE. Isi dengan ADMIN_API_KEY dari punyamu dewe.
  // Hanya untuk latihan — aslinya jangan taruh kayak gini si apiKey ini.
  static const apiKey = 'AyamGoreng123';

  static const headers = {'Content-Type': 'application/json', 'x-api-key': apiKey};

  // GET /articles?limit=50
  Future<List<Article>> getArticles() async {
    // TODO: panggil http.get(Uri.parse(...)), lalu ubah dengan _decode(response)
    // Hint: hasilnya dibungkus -> pakai ArticleResponse.fromJson(...).articles
    final uri = Uri.parse('$baseUrl/articles?limit=50');

    try {
      final response = await http.get(uri, headers: headers);
      final data = _decode(response);
      final articleResponse = ArticleResponse.fromJson(data);
      return articleResponse.articles;
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan : $e');
    }
    // throw UnimplementedError('getArticles belum dibuat');
  }

  // GET /articles/{id}
  Future<Article> getArticle(int id) async {
    // TODO: GET ke '$baseUrl/articles/$id'
    // Hint: satu artikel ada di body['data'] -> Article.fromJson(...)
    final uri = Uri.parse('$baseUrl/articles/$id');

    try {
      final response = await http.get(uri, headers: headers);
      final body = _decode(response);
      return Article.fromJson(body['data']);
    } on SocketException {
      throw ApiException('Tidak ada koneksi Internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('terjadi kesalah : $e ');
    }
    // throw UnimplementedError('getArticle belum dibuat');
  }

  // POST /articles (butuh headers)
  Future<Article> createArticle(Article article) async {
    // TODO: http.post dengan headers dan body
    // Hint: body harus String JSON -> jsonEncode(article.toJson())
    final uri = Uri.parse('$baseUrl/articles');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(article.toJson()),
      );

      final data = _decode(response);
      return Article.fromJson(data['data']);
    } on SocketException {
      throw ApiException('Tidak ada koneksi Internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('terjadi kesalah : $e ');
    }
    // throw UnimplementedError('createArticle belum dibuat');
  }

  // PUT /articles/{id} (butuh headers)
  Future<Article> updateArticle(Article article) async {
    // TODO: mirip createArticle, tapi pakai http.put dan id artikel di URL
    final uri = Uri.parse('$baseUrl/articles/${article.id}');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(article.toJson()),
      );

      final data = _decode(response);
      return Article.fromJson(data['data']);
    } on SocketException {
      throw ApiException('Tidak ada koneksi Internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('terjadi kesalah : $e ');
    }
    // throw UnimplementedError('updateArticle belum dibuat');
  }

  // DELETE /articles/{id} (butuh headers)
  Future<void> deleteArticle(int id) async {
    // TODO: http.delete dengan headers, lalu cek hasilnya dengan _decode(response)
    final uri = Uri.parse('$baseUrl/articles/$id');

    try {
      final response = await http.delete(uri, headers: headers);
      _decode(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi Internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('terjadi kesalah : $e ');
    }
    // throw UnimplementedError('deleteArticle belum dibuat');
  }

  // Ubah response menjadi Map. Kalau gagal, lempar pesan error dari API.
  Map<String, dynamic> _decode(http.Response response) {
    // TODO: ubah response jadi Map dengan jsonDecode(...)
    // Hint: pakai utf8.decode(response.bodyBytes) agar huruf non-ASCII aman
    // Hint: kalau response.statusCode >= 400, throw Exception(body['message'])
    final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      throw ApiException(body['message'] ?? 'Terjadi kesalahan', response.statusCode);
    }
    return body;
    // throw UnimplementedError('_decode belum dibuat');
  }
}
