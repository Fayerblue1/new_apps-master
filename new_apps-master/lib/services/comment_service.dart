import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/comment.dart';
import 'article_service.dart';

class CommentService {
  // GET /articles/{articleId}/comments?limit=50
  Future<List<Comment>> getComments(dynamic articleId) async {
    final uri = Uri.parse('${ArticleService.baseUrl}/articles/$articleId/comments?limit=50');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final List data = body['data'] as List? ?? [];
        final comments = data
            .whereType<Map<String, dynamic>>()
            .map((item) => Comment.fromJson(item))
            .toList();

        // Urutkan komentar dari yang paling baru
        comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return comments;
      } else {
        throw ApiException('Gagal memuat komentar', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw ApiException('Gagal menghubungi server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // POST /articles/{articleId}/comments — kirim komentar baru
  Future<Comment> addComment(dynamic articleId, String userName, String commentText) async {
    final uri = Uri.parse('${ArticleService.baseUrl}/articles/$articleId/comments');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'article_id': articleId,
          'user_name': userName,
          'name': userName,
          'comment_text': commentText,
          'content': commentText,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Comment.fromJson(body['data'] ?? body);
      } else {
        throw ApiException(body['message'] ?? 'Gagal mengirim komentar', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw ApiException('Gagal menghubungi server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }
}
