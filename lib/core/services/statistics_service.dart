import 'package:naji/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class StatisticCurrencyAmount {
  const StatisticCurrencyAmount({this.sy = 0, this.dollar = 0});

  final double sy;
  final double dollar;

  StatisticCurrencyAmount operator +(StatisticCurrencyAmount other) {
    return StatisticCurrencyAmount(
      sy: sy + other.sy,
      dollar: dollar + other.dollar,
    );
  }
}

class StatisticSummary {
  const StatisticSummary({
    required this.userCount,
    required this.invoiceCount,
    required this.paymentCount,
    required this.productCount,
    required this.invoiceTotal,
    required this.paymentTotal,
    required this.balance,
    required this.averageInvoiceSy,
    required this.averageInvoiceDollar,
  });

  final int userCount;
  final int invoiceCount;
  final int paymentCount;
  final int productCount;

  final StatisticCurrencyAmount invoiceTotal;
  final StatisticCurrencyAmount paymentTotal;

  /// Invoice total - payment total.
  final StatisticCurrencyAmount balance;

  final double averageInvoiceSy;
  final double averageInvoiceDollar;
}

class StatisticDailySummary {
  const StatisticDailySummary({
    required this.invoiceCount,
    required this.paymentCount,
    required this.invoiceTotal,
    required this.paymentTotal,
  });

  final int invoiceCount;
  final int paymentCount;

  final StatisticCurrencyAmount invoiceTotal;
  final StatisticCurrencyAmount paymentTotal;
}

class StatisticMonthlySummary {
  const StatisticMonthlySummary({
    required this.year,
    required this.month,
    required this.invoiceCount,
    required this.paymentCount,
    required this.invoiceTotal,
    required this.paymentTotal,
  });

  final int year;
  final int month;

  final int invoiceCount;
  final int paymentCount;

  final StatisticCurrencyAmount invoiceTotal;
  final StatisticCurrencyAmount paymentTotal;

  String get key {
    return '$year-${month.toString().padLeft(2, '0')}';
  }
}

class StatisticUserBalance {
  const StatisticUserBalance({
    required this.userUnified,
    required this.name,
    required this.location,
    required this.balanceSy,
    required this.balanceDollar,
  });

  final String userUnified;
  final String name;
  final String location;

  final double balanceSy;
  final double balanceDollar;
}

class StatisticRecentInvoice {
  const StatisticRecentInvoice({
    required this.unified,
    required this.userUnified,
    required this.userName,
    required this.date,
    required this.totalSy,
    required this.totalDollar,
    required this.writer,
    required this.note,
  });

  final String unified;
  final String userUnified;
  final String userName;

  final int date;

  final double totalSy;
  final double totalDollar;

  final String writer;
  final String? note;
}

class StatisticRecentPayment {
  const StatisticRecentPayment({
    required this.unified,
    required this.userUnified,
    required this.userName,
    required this.date,
    required this.amount,
    required this.currency,
  });

  final String unified;
  final String userUnified;
  final String userName;

  final int date;

  final double amount;
  final String currency;
}

class StatisticData {
  const StatisticData({
    required this.summary,
    required this.today,
    required this.monthly,
    required this.userBalances,
    required this.recentInvoices,
    required this.recentPayments,
  });

  final StatisticSummary summary;
  final StatisticDailySummary today;

  final List<StatisticMonthlySummary> monthly;

  final List<StatisticUserBalance> userBalances;

  final List<StatisticRecentInvoice> recentInvoices;
  final List<StatisticRecentPayment> recentPayments;
}

class StatisticService {
  StatisticService({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  // ============================================================
  // LOAD EVERYTHING
  // ============================================================

  Future<StatisticData> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;

    final range = _normalizeRange(startDate: startDate, endDate: endDate);

    final summary = await _getSummary(
      db,
      startDate: range.start,
      endDate: range.end,
    );

    final today = await _getToday(db);

    final monthly = await _getMonthly(
      db,
      startDate: range.start,
      endDate: range.end,
    );

    final userBalances = await _getUserBalances(db);

    final recentInvoices = await _getRecentInvoices(db, limit: 10);

    final recentPayments = await _getRecentPayments(db, limit: 10);

    return StatisticData(
      summary: summary,
      today: today,
      monthly: monthly,
      userBalances: userBalances,
      recentInvoices: recentInvoices,
      recentPayments: recentPayments,
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Future<StatisticSummary> _getSummary(
    Database db, {
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final start = startDate == null ? null : _startOfDay(startDate);

    final end = endDate == null ? null : _endOfDay(endDate);

    final whereDate = <String>[];
    final args = <Object?>[];

    if (start != null) {
      whereDate.add('date >= ?');
      args.add(start.millisecondsSinceEpoch);
    }

    if (end != null) {
      whereDate.add('date <= ?');
      args.add(end.millisecondsSinceEpoch);
    }

    final dateWhere = whereDate.isEmpty ? '' : 'AND ${whereDate.join(' AND ')}';

    final usersResult = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM users
      WHERE deletedAt IS NULL
    ''');

    final invoicesResult = await db.rawQuery('''
      SELECT
        COUNT(*) AS count,
        COALESCE(SUM(totalSy), 0) AS totalSy,
        COALESCE(SUM(totalDollar), 0) AS totalDollar
      FROM fatoras
      WHERE deletedAt IS NULL
      $dateWhere
    ''', args);

    final paymentsResult = await db.rawQuery('''
      SELECT
        COUNT(*) AS count,
        COALESCE(
          SUM(
            CASE
              WHEN currency = 'sy'
                OR currency = 'SYP'
              THEN amount
              ELSE 0
            END
          ),
          0
        ) AS totalSy,
        COALESCE(
          SUM(
            CASE
              WHEN currency = 'dollar'
                OR currency = 'USD'
                OR currency = '\$'
              THEN amount
              ELSE 0
            END
          ),
          0
        ) AS totalDollar
      FROM payments
      WHERE deletedAt IS NULL
      $dateWhere
    ''', args);

    final productsResult = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM fatora_items
      WHERE deletedAt IS NULL
      ${_invoiceItemDateFilter(db, start, end)}
    ''');

    final userCount = _toInt(usersResult.first['count']);

    final invoiceCount = _toInt(invoicesResult.first['count']);

    final invoiceSy = _toDouble(invoicesResult.first['totalSy']);

    final invoiceDollar = _toDouble(invoicesResult.first['totalDollar']);

    final paymentCount = _toInt(paymentsResult.first['count']);

    final paymentSy = _toDouble(paymentsResult.first['totalSy']);

    final paymentDollar = _toDouble(paymentsResult.first['totalDollar']);

    final productCount = _toInt(productsResult.first['count']);

    return StatisticSummary(
      userCount: userCount,
      invoiceCount: invoiceCount,
      paymentCount: paymentCount,
      productCount: productCount,
      invoiceTotal: StatisticCurrencyAmount(
        sy: invoiceSy,
        dollar: invoiceDollar,
      ),
      paymentTotal: StatisticCurrencyAmount(
        sy: paymentSy,
        dollar: paymentDollar,
      ),
      balance: StatisticCurrencyAmount(
        sy: invoiceSy - paymentSy,
        dollar: invoiceDollar - paymentDollar,
      ),
      averageInvoiceSy: invoiceCount == 0 ? 0 : invoiceSy / invoiceCount,
      averageInvoiceDollar: invoiceCount == 0
          ? 0
          : invoiceDollar / invoiceCount,
    );
  }

  // ============================================================
  // TODAY
  // ============================================================

  Future<StatisticDailySummary> _getToday(Database db) async {
    final now = DateTime.now();

    final start = _startOfDay(now);
    final end = _endOfDay(now);

    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    final invoices = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS count,
        COALESCE(SUM(totalSy), 0) AS totalSy,
        COALESCE(SUM(totalDollar), 0) AS totalDollar
      FROM fatoras
      WHERE deletedAt IS NULL
      AND date >= ?
      AND date <= ?
    ''',
      [startMs, endMs],
    );

    final payments = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS count,

        COALESCE(
          SUM(
            CASE
              WHEN currency = 'sy'
                OR currency = 'SYP'
              THEN amount
              ELSE 0
            END
          ),
          0
        ) AS totalSy,

        COALESCE(
          SUM(
            CASE
              WHEN currency = 'dollar'
                OR currency = 'USD'
                OR currency = '\$'
              THEN amount
              ELSE 0
            END
          ),
          0
        ) AS totalDollar

      FROM payments
      WHERE deletedAt IS NULL
      AND date >= ?
      AND date <= ?
    ''',
      [startMs, endMs],
    );

    return StatisticDailySummary(
      invoiceCount: _toInt(invoices.first['count']),
      paymentCount: _toInt(payments.first['count']),
      invoiceTotal: StatisticCurrencyAmount(
        sy: _toDouble(invoices.first['totalSy']),
        dollar: _toDouble(invoices.first['totalDollar']),
      ),
      paymentTotal: StatisticCurrencyAmount(
        sy: _toDouble(payments.first['totalSy']),
        dollar: _toDouble(payments.first['totalDollar']),
      ),
    );
  }

  // ============================================================
  // MONTHLY
  // ============================================================

  Future<List<StatisticMonthlySummary>> _getMonthly(
    Database db, {
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final where = <String>['deletedAt IS NULL'];

    final args = <Object?>[];

    if (startDate != null) {
      where.add('date >= ?');
      args.add(_startOfDay(startDate).millisecondsSinceEpoch);
    }

    if (endDate != null) {
      where.add('date <= ?');
      args.add(_endOfDay(endDate).millisecondsSinceEpoch);
    }

    final whereSql = where.join(' AND ');

    final invoiceRows = await db.rawQuery('''
      SELECT
        strftime('%Y', date / 1000, 'unixepoch') AS year,
        strftime('%m', date / 1000, 'unixepoch') AS month,
        COUNT(*) AS count,
        COALESCE(SUM(totalSy), 0) AS totalSy,
        COALESCE(SUM(totalDollar), 0) AS totalDollar
      FROM fatoras
      WHERE $whereSql
      GROUP BY year, month
      ORDER BY year ASC, month ASC
    ''', args);

    final paymentRows = await db.rawQuery('''
      SELECT
        strftime('%Y', date / 1000, 'unixepoch') AS year,
        strftime('%m', date / 1000, 'unixepoch') AS month,

        COUNT(*) AS count,

        COALESCE(
          SUM(
            CASE
              WHEN currency = 'sy'
                OR currency = 'SYP'
              THEN amount
              ELSE 0
            END
          ),
          0
        ) AS totalSy,

        COALESCE(
          SUM(
            CASE
              WHEN currency = 'dollar'
                OR currency = 'USD'
                OR currency = '\$'
              THEN amount
              ELSE 0
            END
          ),
          0
        ) AS totalDollar

      FROM payments
      WHERE $whereSql
      GROUP BY year, month
      ORDER BY year ASC, month ASC
    ''', args);

    final result = <String, _MonthlyBuilder>{};

    for (final row in invoiceRows) {
      final year = int.parse(row['year'].toString());

      final month = int.parse(row['month'].toString());

      final key = '$year-${month.toString().padLeft(2, '0')}';

      final builder = result.putIfAbsent(
        key,
        () => _MonthlyBuilder(year: year, month: month),
      );

      builder.invoiceCount = _toInt(row['count']);

      builder.invoiceSy = _toDouble(row['totalSy']);

      builder.invoiceDollar = _toDouble(row['totalDollar']);
    }

    for (final row in paymentRows) {
      final year = int.parse(row['year'].toString());

      final month = int.parse(row['month'].toString());

      final key = '$year-${month.toString().padLeft(2, '0')}';

      final builder = result.putIfAbsent(
        key,
        () => _MonthlyBuilder(year: year, month: month),
      );

      builder.paymentCount = _toInt(row['count']);

      builder.paymentSy = _toDouble(row['totalSy']);

      builder.paymentDollar = _toDouble(row['totalDollar']);
    }

    final values = result.values.toList();

    values.sort((a, b) {
      if (a.year != b.year) {
        return a.year.compareTo(b.year);
      }

      return a.month.compareTo(b.month);
    });

    return values.map((item) {
      return StatisticMonthlySummary(
        year: item.year,
        month: item.month,
        invoiceCount: item.invoiceCount,
        paymentCount: item.paymentCount,
        invoiceTotal: StatisticCurrencyAmount(
          sy: item.invoiceSy,
          dollar: item.invoiceDollar,
        ),
        paymentTotal: StatisticCurrencyAmount(
          sy: item.paymentSy,
          dollar: item.paymentDollar,
        ),
      );
    }).toList();
  }

  // ============================================================
  // USER BALANCES
  // ============================================================

  Future<List<StatisticUserBalance>> _getUserBalances(Database db) async {
    final rows = await db.rawQuery('''
      SELECT
        u.unified,
        u.name,
        u.location,

        COALESCE(
          (
            SELECT SUM(f.totalSy)
            FROM fatoras f
            WHERE f.userUnified = u.unified
            AND f.deletedAt IS NULL
          ),
          0
        )
        -
        COALESCE(
          (
            SELECT SUM(p.amount)
            FROM payments p
            WHERE p.userUnified = u.unified
            AND p.deletedAt IS NULL
            AND (
              p.currency = 'sy'
              OR p.currency = 'SYP'
            )
          ),
          0
        ) AS balanceSy,

        COALESCE(
          (
            SELECT SUM(f.totalDollar)
            FROM fatoras f
            WHERE f.userUnified = u.unified
            AND f.deletedAt IS NULL
          ),
          0
        )
        -
        COALESCE(
          (
            SELECT SUM(p.amount)
            FROM payments p
            WHERE p.userUnified = u.unified
            AND p.deletedAt IS NULL
            AND (
              p.currency = 'dollar'
              OR p.currency = 'USD'
              OR p.currency = '\$'
            )
          ),
          0
        ) AS balanceDollar

      FROM users u
      WHERE u.deletedAt IS NULL
      ORDER BY u.name COLLATE NOCASE
    ''');

    return rows.map((row) {
      return StatisticUserBalance(
        userUnified: row['unified'].toString(),
        name: row['name'].toString(),
        location: row['location'].toString(),
        balanceSy: _toDouble(row['balanceSy']),
        balanceDollar: _toDouble(row['balanceDollar']),
      );
    }).toList();
  }

  // ============================================================
  // RECENT INVOICES
  // ============================================================

  Future<List<StatisticRecentInvoice>> _getRecentInvoices(
    Database db, {
    int limit = 10,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT
        f.unified,
        f.userUnified,
        f.date,
        f.totalSy,
        f.totalDollar,
        f.writer,
        f.note,
        COALESCE(u.name, 'غير معروف') AS userName

      FROM fatoras f

      LEFT JOIN users u
        ON u.unified = f.userUnified

      WHERE f.deletedAt IS NULL

      ORDER BY f.date DESC

      LIMIT ?
    ''',
      [limit],
    );

    return rows.map((row) {
      return StatisticRecentInvoice(
        unified: row['unified'].toString(),
        userUnified: row['userUnified'].toString(),
        userName: row['userName'].toString(),
        date: _toInt(row['date']),
        totalSy: _toDouble(row['totalSy']),
        totalDollar: _toDouble(row['totalDollar']),
        writer: row['writer'].toString(),
        note: row['note'] as String?,
      );
    }).toList();
  }

  // ============================================================
  // RECENT PAYMENTS
  // ============================================================

  Future<List<StatisticRecentPayment>> _getRecentPayments(
    Database db, {
    int limit = 10,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT
        p.unified,
        p.userUnified,
        p.date,
        p.amount,
        p.currency,
        COALESCE(u.name, 'غير معروف') AS userName

      FROM payments p

      LEFT JOIN users u
        ON u.unified = p.userUnified

      WHERE p.deletedAt IS NULL

      ORDER BY p.date DESC

      LIMIT ?
    ''',
      [limit],
    );

    return rows.map((row) {
      return StatisticRecentPayment(
        unified: row['unified'].toString(),
        userUnified: row['userUnified'].toString(),
        userName: row['userName'].toString(),
        date: _toInt(row['date']),
        amount: _toDouble(row['amount']),
        currency: row['currency'].toString(),
      );
    }).toList();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  _DateRange _normalizeRange({DateTime? startDate, DateTime? endDate}) {
    if (startDate == null && endDate == null) {
      return const _DateRange(start: null, end: null);
    }

    final start = startDate == null ? null : _startOfDay(startDate);

    final end = endDate == null ? null : _endOfDay(endDate);

    return _DateRange(start: start, end: end);
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _invoiceItemDateFilter(Database db, DateTime? start, DateTime? end) {
    // Product records don't contain their own business date.
    // Their creation date is used when a date range is applied.
    final conditions = <String>[];

    if (start != null) {
      conditions.add('createdAt >= ${start.millisecondsSinceEpoch}');
    }

    if (end != null) {
      conditions.add('createdAt <= ${end.millisecondsSinceEpoch}');
    }

    if (conditions.isEmpty) {
      return '';
    }

    return 'AND ${conditions.join(' AND ')}';
  }

  int _toInt(Object? value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(Object? value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}

class _MonthlyBuilder {
  _MonthlyBuilder({required this.year, required this.month});

  final int year;
  final int month;

  int invoiceCount = 0;
  int paymentCount = 0;

  double invoiceSy = 0;
  double invoiceDollar = 0;

  double paymentSy = 0;
  double paymentDollar = 0;
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime? start;
  final DateTime? end;
}
