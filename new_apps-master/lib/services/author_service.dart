import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/author.dart';
import 'article_service.dart';

class AuthorService {
  // GET /authors
  Future<List<Author>> getAuthors() async {
    // TODO: GET ke '${ArticleService.baseUrl}/authors'
    // Hint: daftar penulis ada di body['data'] (List) -> ubah tiap item dengan Author.fromJson
    final uri = Uri.parse('${ArticleService.baseUrl}/authors');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final List data = body['data'] as List;
        return data.map((item) => Author.fromJson(item)).toList();
      } else {
        throw ApiException('Gagal memuat data Author', response.statusCode);
      }
    } on SocketException {
      throw ApiException('Tidak ada koneksi Internet');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('terjadi kesalah : $e ');
    }
    // throw UnimplementedError('getAuthors belum dibuat');
  }
}
