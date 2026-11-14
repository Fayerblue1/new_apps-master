import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../models/author.dart';
import '../providers/article_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/comment_provider.dart';
import '../utils/time_utils.dart';
import 'article_form_screen.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  const ArticleDetailScreen({
    super.key,
    required this.id,
    this.articleData,
  });

  final int id;
  final Article? articleData;

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  Future<void> _delete(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus artikel?'),
        content: const Text('Artikel yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yes != true) return;

    try {
      await ref.read(articleServiceProvider).deleteArticle(widget.id);
      ref.invalidate(articlesProvider); // Muat ulang daftar berita
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  /// Menampilkan panel pengatur ukuran font (Font Size Adjuster)
  void _showFontSizeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentSize = ref.watch(articleFontSizeProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ukuran Huruf Artikel',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${currentSize.round()} pt',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.text_decrease),
                          tooltip: 'Perkecil',
                          onPressed: currentSize > 12.0
                              ? () => ref.read(articleFontSizeProvider.notifier).decrease()
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: currentSize,
                            min: 12.0,
                            max: 26.0,
                            divisions: 7,
                            label: '${currentSize.round()}',
                            onChanged: (val) {
                              ref.read(articleFontSizeProvider.notifier).setFontSize(val);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_increase),
                          tooltip: 'Perbesar',
                          onPressed: currentSize < 26.0
                              ? () => ref.read(articleFontSizeProvider.notifier).increase()
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Teks Pratinjau
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Contoh tampilan huruf artikel berita.',
                        style: TextStyle(fontSize: currentSize, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jika artikel sudah dikirim langsung dari daftar, gunakan langsung untuk performa instan
    final articleAsync = ref.watch(articleProvider(widget.id));
    final article = widget.articleData ?? articleAsync.value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Berita'),
        actions: [
          // Tombol Bookmark
          if (article != null)
            Consumer(
              builder: (context, ref, _) {
                final bookmarks = ref.watch(bookmarkProvider);
                final isBookmarked = bookmarks.any((a) => a.id.toString() == article.id.toString());
                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Theme.of(context).primaryColor : null,
                  ),
                  tooltip: isBookmarked ? 'Hapus dari Tersimpan' : 'Simpan Berita',
                  onPressed: () async {
                    final added = await ref.read(bookmarkProvider.notifier).toggleBookmark(article);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(
                            added
                                ? 'Berita disimpan ke Tersimpan'
                                : 'Dihapus dari Tersimpan',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),

          // Tombol Font Size Adjuster
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Sesuaikan Ukuran Huruf',
            onPressed: () => _showFontSizeDialog(context),
          ),

          // Menu Edit & Hapus
          if (article != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Artikel',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ArticleFormScreen(article: article)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Artikel',
              onPressed: () => _delete(context),
            ),
          ],
        ],
      ),
      body: article != null
          ? _ArticleBody(article: article, articleId: article.id)
          : articleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('$error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(articleProvider(widget.id)),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) => _ArticleBody(article: data, articleId: data.id),
            ),
    );
  }
}

class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({
    required this.article,
    required this.articleId,
  });

  final Article article;
  final dynamic articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final fontSize = ref.watch(articleFontSizeProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. Gambar Hero
        if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
          Hero(
            tag: 'article-img-${article.id}',
            child: SizedBox(
              width: double.infinity,
              height: 250,
              child: Image.network(
                article.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Kategori & Waktu Relatif
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    TimeUtils.formatRelativeTime(article.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Judul Lengkap
              Text(
                article.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Info Penulis & Tanggal Rilis
              _AuthorCard(
                authorName: article.authorName,
                author: article.author,
                date: article.createdAt,
              ),
              const Divider(height: 32),

              // Summary / Ringkasan jika ada
              if (article.summary != null && article.summary!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: Colors.blue.shade400, width: 4),
                    ),
                  ),
                  child: Text(
                    article.summary!,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Isi Konten Berita dengan Ukuran Font Dinamis
              Text(
                article.content,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.75,
                  letterSpacing: 0.25,
                  color: const Color(0xFF2B2B2B),
                ),
              ),
              const Divider(height: 48),

              // Bagian Komentar
              _CommentSection(articleId: articleId),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({
    required this.authorName,
    required this.author,
    this.date,
  });

  final String authorName;
  final Author author;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage: author.avatarUrl != null ? NetworkImage(author.avatarUrl!) : null,
            child: author.avatarUrl == null
                ? Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null ? TimeUtils.formatDetailDate(date) : 'Baru saja dirilis',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentSection extends ConsumerStatefulWidget {
  const _CommentSection({required this.articleId});

  final dynamic articleId;

  @override
  ConsumerState<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<_CommentSection> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong (minimal 2 karakter)')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi komentar tidak boleh kosong (minimal 3 karakter)')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(commentServiceProvider).addComment(
            widget.articleId,
            name,
            content,
          );

      _contentController.clear();
      FocusScope.of(context).unfocus();

      // Otomatis perbarui daftar komentar di layar secara real-time
      ref.invalidate(commentsProvider(widget.articleId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Komentar Anda berhasil dipublikasikan!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('$e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.articleId));
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Bagian Komentar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 20, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Komentar Pembaca',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            commentsAsync.maybeWhen(
              data: (list) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${list.length} Komentar',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Daftar Komentar (Diurutkan dari yang terbaru)
        commentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gagal memuat komentar: $error',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(commentsProvider(widget.articleId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.forum_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada komentar untuk artikel ini.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jadilah yang pertama memberikan pendapat!',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Inisial Pengguna
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryColor.withOpacity(0.15),
                        child: Text(
                          comment.userName.isNotEmpty
                              ? comment.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nama, Waktu, & Isi Komentar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  comment.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  TimeUtils.formatRelativeTime(comment.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              comment.commentText,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF333333),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),

        // Form Tambah Komentar Baru
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tulis Komentar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Input Nama Singkat
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  labelText: 'Nama Anda',
                  hintText: 'Misal: Budi Santoso',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Input Isi Komentar
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.chat_bubble_outline, size: 20),
                  ),
                  labelText: 'Komentar',
                  hintText: 'Tulis tanggapan atau komentar Anda...',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Tombol Kirim Komentar
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSending ? 'Mengirim...' : 'Kirim Komentar',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
