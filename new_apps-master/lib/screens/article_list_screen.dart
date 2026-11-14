import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../providers/article_provider.dart';
import '../providers/bookmark_provider.dart';
import '../utils/time_utils.dart';
import '../widgets/shimmer_loading.dart';
import 'article_detail_screen.dart';
import 'article_form_screen.dart';
import 'article_search_screen.dart';
import 'login_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class ArticleListScreen extends ConsumerStatefulWidget {
  const ArticleListScreen({super.key});

  @override
  ConsumerState<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends ConsumerState<ArticleListScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentCarouselIndex = 0;

  static const List<String> categories = [
    'Semua',
    'Teknologi',
    'Bisnis',
    'Olahraga',
    'Hiburan',
    'Kesehatan',
    'Otomotif',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('Logout error: $e');
      }

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(articlesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'KABAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Terkini',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cari Berita',
            icon: const Icon(Icons.search_rounded, color: Colors.black87),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArticleSearchScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Tambah Berita',
            icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArticleFormScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Keluar Akun',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: articlesAsync.when(
        loading: () => const HomeShimmerLoading(),
        error: (error, _) => _buildErrorView(error),
        data: (articles) => _buildContent(articles, selectedCategory),
      ),
    );
  }

  /// Tampilan jika ada masalah koneksi / error
  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Berita',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(articlesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan Konten Utama
  Widget _buildContent(List<Article> allArticles, String selectedCategory) {
    // 1. Ambil berita Breaking News untuk Carousel
    final breakingArticles = allArticles.where((a) => a.isBreaking).toList();
    final carouselArticles = breakingArticles.isNotEmpty
        ? breakingArticles
        : allArticles.take(4).toList();

    // 2. Filter artikel berdasarkan kategori yang dipilih
    final filteredArticles = selectedCategory == 'Semua'
        ? allArticles
        : allArticles.where((article) {
            final cat = article.category.toLowerCase();
            final target = selectedCategory.toLowerCase();
            // Mendukung kecocokan Bisnis & Ekonomi
            if (target == 'bisnis') {
              return cat.contains('bisnis') || cat.contains('ekonomi');
            }
            return cat.contains(target);
          }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.refresh(articlesProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // 1. Bagian Carousel Breaking News
          if (carouselArticles.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildBreakingCarousel(carouselArticles),
            const SizedBox(height: 10),
            _buildCarouselIndicators(carouselArticles.length),
            const SizedBox(height: 16),
          ],

          // 2. Bagian Tab / Chip Filter Kategori Horizontal
          _buildCategoryFilter(selectedCategory),
          const SizedBox(height: 16),

          // 3. Header Daftar Berita
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCategory == 'Semua'
                      ? 'Berita Terbaru'
                      : 'Kategori: $selectedCategory',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${filteredArticles.length} artikel',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Daftar Berita Sesuai Kategori
          if (filteredArticles.isEmpty)
            _buildEmptyCategory(selectedCategory)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredArticles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final article = filteredArticles[index];
                return _buildArticleCard(context, article);
              },
            ),
        ],
      ),
    );
  }

  /// Carousel Horizontal untuk Breaking News
  Widget _buildBreakingCarousel(List<Article> articles) {
    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: _pageController,
        itemCount: articles.length,
        onPageChanged: (index) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final article = articles[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => _navigateToDetail(context, article),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gambar Berita
                    if (article.imageUrl != null &&
                        article.imageUrl!.isNotEmpty)
                      Image.network(
                        article.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.newspaper,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.newspaper,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),

                    // Gradient Overlay agar tulisan mudah dibaca
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.85),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),

                    // Label Breaking News
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade700,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bolt, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'BREAKING NEWS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tombol Bookmark di Carousel
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.black.withOpacity(0.4),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            final added = await ref
                                .read(bookmarkProvider.notifier)
                                .toggleBookmark(article);
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
                          child: Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: Consumer(
                              builder: (context, ref, _) {
                                final bookmarks = ref.watch(bookmarkProvider);
                                final isSaved = bookmarks.any(
                                  (a) =>
                                      a.id.toString() == article.id.toString(),
                                );
                                return Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 18,
                                  color: isSaved ? Colors.amber : Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Judul & Info di bagian bawah carousel
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                article.authorName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                ' · ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                TimeUtils.formatRelativeTime(article.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Indikator titik carousel
  Widget _buildCarouselIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentCarouselIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  /// Chip Filter Kategori Horizontal
  Widget _buildCategoryFilter(String selectedCategory) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          final primaryColor = Theme.of(context).primaryColor;

          return GestureDetector(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).setCategory(cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Card Item Berita
  Widget _buildArticleCard(BuildContext context, Article article) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0.5,
      child: InkWell(
        onTap: () => _navigateToDetail(context, article),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 100,
                  height: 90,
                  child:
                      article.imageUrl != null && article.imageUrl!.isNotEmpty
                      ? Image.network(
                          article.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.newspaper,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Info Berita (Judul, Kategori, Tanggal, Penulis)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Kategori & Tombol Bookmark
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.category,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final bookmarks = ref.watch(bookmarkProvider);
                            final isSaved = bookmarks.any(
                              (a) => a.id.toString() == article.id.toString(),
                            );
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final added = await ref
                                    .read(bookmarkProvider.notifier)
                                    .toggleBookmark(article);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
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
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 20,
                                  color: isSaved
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Judul Berita
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Penulis & Relative Time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            article.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          ' · ',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        Text(
                          TimeUtils.formatRelativeTime(article.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tampilan ketika kategori kosong
  Widget _buildEmptyCategory(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.feed_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Belum ada berita untuk kategori "$category"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(
          id: article.id is int
              ? article.id as int
              : int.tryParse(article.id.toString()) ?? 1,
          articleData: article,
        ),
      ),
    );
  }
}
