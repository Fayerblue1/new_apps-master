import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/comment.dart';
import 'article_service.dart';

class CommentService {
  // GET /articles/{articleId}/comments?limit=50
  Future<List<Comment>> getComments(int articleId) async {
    // TODO: GET komentar, lalu ubah body['data'] menjadi List<Comment>
    final uri = Uri.parse('${ArticleService.baseUrl}/articles/$articleId/comments?limit=50');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final List data = body['data'] as List;
        return data.map((item) => Comment.fromJson(item)).toList();
      } else {
        throw ApiException('Gagal memuat komentar', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Tidak ada koneksi Internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('terjadi kesalah : $e ');
    }
    // throw UnimplementedError('getComments belum dibuat');
  }

  // POST /articles/{articleId}/comments — tidak perlu api key
  Future<Comment> addComment(int articleId, String name, String content) async {
    // TODO: http.post dengan header Content-Type dan body {'name': ..., 'content': ...}
    // Hint: jangan lupa jsonEncode body-nya
    final uri = Uri.parse('${ArticleService.baseUrl}/articles/$articleId/comments');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'content': content,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return Comment.fromJson(body['data']);
      } else {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        throw ApiException(body['message'] ?? 'Gagal mengirim komentar', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Tidak ada koneksi Internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('terjadi kesalah : $e ');
    }
    // throw UnimplementedError('addComment belum dibuat');
  }
}
