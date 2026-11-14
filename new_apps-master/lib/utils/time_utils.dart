class TimeUtils {
  /// Format tanggal menjadi waktu relatif (contoh: "2 jam lalu", "Baru saja")
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Baru saja';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    }
    final years = (difference.inDays / 365).floor();
    return '$years tahun lalu';
  }

  /// Format tanggal lengkap untuk detail berita
  static String formatDetailDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final day = dateTime.day;
    final monthName = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $monthName $year, $hour:$minute WIB';
  }
}

