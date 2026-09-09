import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/currency.dart';
import '../models/fatora.dart';
import '../models/fatora_product.dart';
import '../models/payment.dart';
import '../models/user.dart';
import '../models/user_balance.dart';

class UserReportService {
  UserReportService._();

  static Future<void> sharePdfReport({
    required User user,
    required UserBalance? balance,
    required List<(Fatora, List<FatoraProduct>)> invoices,
    required List<Payment> payments,
  }) async {
    final file = await generatePdfFile(
      user: user,
      balance: balance,
      invoices: invoices,
      payments: payments,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'تقرير المستخدم ${user.name}',
        text: 'تقرير تفصيلي للفواتير والدفعات الخاصة بالمستخدم ${user.name}',
      ),
    );
  }

  static Future<void> shareExcelReport({
    required User user,
    required UserBalance? balance,
    required List<(Fatora, List<FatoraProduct>)> invoices,
    required List<Payment> payments,
  }) async {
    final file = await generateExcelFile(
      user: user,
      balance: balance,
      invoices: invoices,
      payments: payments,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'تقرير Excel للمستخدم ${user.name}',
        text: 'ملف Excel يتضمن الفواتير والدفعات الخاصة بالمستخدم ${user.name}',
      ),
    );
  }

  static Future<File> generatePdfFile({
    required User user,
    required UserBalance? balance,
    required List<(Fatora, List<FatoraProduct>)> invoices,
    required List<Payment> payments,
  }) async {
    final bytes = await _generatePdfBytes(
      user: user,
      balance: balance,
      invoices: invoices,
      payments: payments,
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        dir.path,
        'user_report_${_sanitizeFileName(user.name)}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<File> generateExcelFile({
    required User user,
    required UserBalance? balance,
    required List<(Fatora, List<FatoraProduct>)> invoices,
    required List<Payment> payments,
  }) async {
    final csv = _generateExcelCsv(
      user: user,
      balance: balance,
      invoices: invoices,
      payments: payments,
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        dir.path,
        'user_report_${_sanitizeFileName(user.name)}_${DateTime.now().millisecondsSinceEpoch}.csv',
      ),
    );
    await file.writeAsString(csv, encoding: utf8);
    return file;
  }

  static Future<Uint8List> _generatePdfBytes({
    required User user,
    required UserBalance? balance,
    required List<(Fatora, List<FatoraProduct>)> invoices,
    required List<Payment> payments,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );

    final entries = <_UserReportEntry>[
      ...invoices.map(
        (record) => _UserReportEntry.fromInvoice(
          fatora: record.$1,
          products: record.$2,
        ),
      ),
      ...payments.map(
        (payment) => _UserReportEntry.fromPayment(payment: payment),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final invoiceTotalSy = invoices.fold<double>(
      0,
      (sum, item) => sum + item.$1.totalSy,
    );
    final invoiceTotalDollar = invoices.fold<double>(
      0,
      (sum, item) => sum + item.$1.totalDollar,
    );
    final paymentTotalSy = payments
        .where((payment) => payment.currency == Currency.sy)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final paymentTotalDollar = payments
        .where((payment) => payment.currency == Currency.dollar)
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'تقرير المستخدم',
                  style: pw.TextStyle(font: boldFont, fontSize: 24),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _pdfInfoBlock(
                        title: 'الاسم',
                        value: user.name,
                        regularFont: regularFont,
                        boldFont: boldFont,
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: _pdfInfoBlock(
                        title: 'الموقع',
                        value: user.location,
                        regularFont: regularFont,
                        boldFont: boldFont,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _pdfInfoBlock(
                        title: 'رصيد الليرة',
                        value:
                            '${(balance?.sy ?? 0).toStringAsFixed(2)} ${Currency.sy.symbol}',
                        regularFont: regularFont,
                        boldFont: boldFont,
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: _pdfInfoBlock(
                        title: 'رصيد الدولار',
                        value:
                            '${(balance?.dollar ?? 0).toStringAsFixed(2)} ${Currency.dollar.symbol}',
                        regularFont: regularFont,
                        boldFont: boldFont,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              pw.Expanded(
                child: _summaryCard(
                  title: 'إجمالي الفواتير (ل.س)',
                  value: invoiceTotalSy.toStringAsFixed(2),
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _summaryCard(
                  title: 'إجمالي الفواتير (USD)',
                  value: invoiceTotalDollar.toStringAsFixed(2),
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _summaryCard(
                  title: 'إجمالي الدفعات (ل.س)',
                  value: paymentTotalSy.toStringAsFixed(2),
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _summaryCard(
                  title: 'إجمالي الدفعات (USD)',
                  value: paymentTotalDollar.toStringAsFixed(2),
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'سجل الفواتير والدفعات (الأحدث أولاً)',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1.1),
              4: pw.FlexColumnWidth(2.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('النوع', boldFont, isHeader: true),
                  _pdfCell('التاريخ', boldFont, isHeader: true),
                  _pdfCell('العملة', boldFont, isHeader: true),
                  _pdfCell('المبلغ', boldFont, isHeader: true),
                  _pdfCell('التفاصيل', boldFont, isHeader: true),
                ],
              ),
              ...entries.map(
                (entry) => pw.TableRow(
                  children: [
                    _pdfCell(entry.type, regularFont),
                    _pdfCell(_formatDateTime(entry.date), regularFont),
                    _pdfCell(entry.currencySymbol, regularFont),
                    _pdfCell(
                      '${entry.amount.toStringAsFixed(2)} ${entry.currencySymbol}',
                      boldFont,
                    ),
                    _pdfCell(entry.details, regularFont),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _generateExcelCsv({
    required User user,
    required UserBalance? balance,
    required List<(Fatora, List<FatoraProduct>)> invoices,
    required List<Payment> payments,
  }) {
    final entries = <_UserReportEntry>[
      ...invoices.map(
        (record) => _UserReportEntry.fromInvoice(
          fatora: record.$1,
          products: record.$2,
        ),
      ),
      ...payments.map(
        (payment) => _UserReportEntry.fromPayment(payment: payment),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final buffer = StringBuffer();
    buffer.writeln(_csvRow(['اسم المستخدم', user.name]));
    buffer.writeln(_csvRow(['الموقع', user.location]));
    buffer.writeln(
      _csvRow([
        'رصيد الليرة',
        '${(balance?.sy ?? 0).toStringAsFixed(2)} ${Currency.sy.symbol}',
      ]),
    );
    buffer.writeln(
      _csvRow([
        'رصيد الدولار',
        '${(balance?.dollar ?? 0).toStringAsFixed(2)} ${Currency.dollar.symbol}',
      ]),
    );
    buffer.writeln();
    buffer.writeln(
      _csvRow(['النوع', 'التاريخ', 'العملة', 'المبلغ', 'التفاصيل']),
    );

    for (final entry in entries) {
      buffer.writeln(
        _csvRow([
          entry.type,
          _formatDateTime(entry.date),
          entry.currencySymbol,
          '${entry.amount.toStringAsFixed(2)} ${entry.currencySymbol}',
          entry.details,
        ]),
      );
    }

    return buffer.toString();
  }

  static String _csvRow(List<String> values) {
    final escaped = values
        .map((value) {
          final text = value.replaceAll('"', '""');
          return '"$text"';
        })
        .join(';');

    return escaped;
  }

  static String _sanitizeFileName(String value) {
    final normalized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_');
    return normalized.trim().isEmpty ? 'user' : normalized.trim();
  }

  static String _formatDateTime(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  static pw.Widget _pdfInfoBlock({
    required String title,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 12)),
      ],
    );
  }

  static pw.Widget _summaryCard({
    required String title,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 16)),
        ],
      ),
    );
  }

  static pw.Widget _pdfCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}

class _UserReportEntry {
  final int date;
  final String type;
  final String currencySymbol;
  final double amount;
  final String details;

  const _UserReportEntry({
    required this.date,
    required this.type,
    required this.currencySymbol,
    required this.amount,
    required this.details,
  });

  factory _UserReportEntry.fromInvoice({
    required Fatora fatora,
    required List<FatoraProduct> products,
  }) {
    final invoiceAmount = (fatora.totalSy > 0 && fatora.totalDollar == 0)
        ? fatora.totalSy
        : (fatora.totalDollar > 0 && fatora.totalSy == 0)
        ? fatora.totalDollar
        : (fatora.totalSy + fatora.totalDollar);

    final listString = products.isEmpty
        ? (fatora.note ?? 'لا توجد منتجات')
        : products
              .map(
                (product) =>
                    '${product.productName} (${product.quantity} × ${product.price})',
              )
              .join(' | ');

    final currency = fatora.totalDollar > 0 && fatora.totalSy == 0
        ? Currency.dollar
        : Currency.sy;

    return _UserReportEntry(
      date: fatora.date,
      type: 'فاتورة',
      currencySymbol: currency.symbol,
      amount: invoiceAmount,
      details: listString,
    );
  }

  factory _UserReportEntry.fromPayment({required Payment payment}) {
    return _UserReportEntry(
      date: payment.date,
      type: 'دفعة',
      currencySymbol: payment.currency.symbol,
      amount: payment.amount,
      details: 'دفعة مالية',
    );
  }
}
