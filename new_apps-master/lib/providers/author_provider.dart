import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/author.dart';
import '../services/author_service.dart';

final authorServiceProvider = Provider((ref) => AuthorService());

// Semua penulis (dipakai dropdown di form artikel).
final authorsProvider = FutureProvider<List<Author>>((ref) {
  // TODO: panggil getAuthors() dari authorServiceProvider
  final service = ref.watch(authorServiceProvider);
  return service.getAuthors();
  // throw UnimplementedError('authorsProvider belum dibuat');
});
