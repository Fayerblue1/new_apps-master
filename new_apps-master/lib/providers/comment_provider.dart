import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../services/comment_service.dart';

final commentServiceProvider = Provider((ref) => CommentService());

// Komentar milik satu artikel berdasarkan articleId (diurutkan dari yang terbaru)
final commentsProvider =
    FutureProvider.family<List<Comment>, dynamic>((ref, articleId) {
  final service = ref.watch(commentServiceProvider);
  return service.getComments(articleId);
});
