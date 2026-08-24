import 'package:intl/intl.dart';

class DateGrouper {
  /// Groups items by month and year
  /// Returns a map where key is "Month Year" string and value is list of items
  static Map<String, List<T>> groupByMonthYear<T>(
    List<T> items,
    int Function(T) dateExtractor,
  ) {
    final grouped = <String, List<T>>{};

    for (var item in items) {
      final date = DateTime.fromMillisecondsSinceEpoch(dateExtractor(item));
      final key = DateFormat('MMMM yyyy').format(date);

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }

    return grouped;
  }

  /// Groups items by year
  /// Returns a map where key is year string and value is list of items
  static Map<String, List<T>> groupByYear<T>(
    List<T> items,
    int Function(T) dateExtractor,
  ) {
    final grouped = <String, List<T>>{};

    for (var item in items) {
      final date = DateTime.fromMillisecondsSinceEpoch(dateExtractor(item));
      final key = date.year.toString();

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }

    return grouped;
  }

  /// Gets sorted keys in descending order (most recent first)
  static List<String> getSortedKeys(Map<String, List<dynamic>> grouped) {
    return grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Formats a date from milliseconds since epoch for display
  static String formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formats a date-time for display with time
  static String formatDateTime(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
