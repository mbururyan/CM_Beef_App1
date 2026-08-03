/// Small date helpers so screens don't each invent their own format.
class Formatters {
  Formatters._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "25 Jul 2026". Returns a dash when the date is still resolving.
  static String date(DateTime? d) {
    if (d == null) return '—';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// "today" / "yesterday" / "25 Jul 2026" — friendlier for recent items.
  static String relativeDate(DateTime? d) {
    if (d == null) return 'just now';
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    return date(d);
  }
}