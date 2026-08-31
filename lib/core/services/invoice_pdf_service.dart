import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/currency.dart';
import '../models/fatora.dart';
import '../models/fatora_product.dart';
import '../models/user.dart';

class InvoicePdfService {
  InvoicePdfService._();

  static Future<Uint8List> generate({
    required User user,
    required Fatora fatora,
    required List<FatoraProduct> products,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            _buildHeader(
              regularFont: regularFont,
              boldFont: boldFont,
              user: user,
              fatora: fatora,
            ),

            pw.SizedBox(height: 24),

            _buildProductsTable(
              products: products,
              regularFont: regularFont,
              boldFont: boldFont,
            ),

            pw.SizedBox(height: 18),

            _buildTotals(
              fatora: fatora,
              regularFont: regularFont,
              boldFont: boldFont,
            ),

            if (fatora.note != null && fatora.note!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildNote(fatora.note!, regularFont),
            ],

            pw.SizedBox(height: 30),

            _buildFooter(regularFont, boldFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required pw.Font regularFont,
    required pw.Font boldFont,
    required User user,
    required Fatora fatora,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text('فاتورة', style: pw.TextStyle(font: boldFont, fontSize: 26)),

          pw.SizedBox(height: 4),

          pw.Text(
            'فاتورة مبيعات',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 13,
              color: PdfColors.grey700,
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Row(
            children: [
              pw.Expanded(
                child: _infoBlock(
                  title: 'العميل',
                  value: user.name,
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              ),

              pw.SizedBox(width: 20),

              pw.Expanded(
                child: _infoBlock(
                  title: 'الموقع',
                  value: user.location,
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),
          if (fatora.writer.trim().isNotEmpty)
            pw.Row(
              children: [
                pw.Expanded(
                  child: _infoBlock(
                    title: 'الموزع',
                    value: fatora.writer,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _infoBlock(
                    title: 'التاريخ',
                    value: _formatDate(fatora.date),
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                ),
              ],
            )
          else
            pw.Row(
              children: [
                pw.Expanded(
                  child: _infoBlock(
                    title: 'التاريخ',
                    value: _formatDate(fatora.date),
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
                child: _infoBlock(
                  title: 'رقم الفاتورة',
                  value: fatora.unified,
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoBlock({
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
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildProductsTable({
    required List<FatoraProduct> products,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('المنتج', boldFont),
            _tableHeader('الكمية', boldFont),
            _tableHeader('السعر', boldFont),
            _tableHeader('المجموع', boldFont),
          ],
        ),

        ...products.map((product) {
          final total = product.price * product.quantity;

          return pw.TableRow(
            children: [
              _tableCell(product.productName, regularFont),
              _tableCell(
                _formatNumber(product.quantity),
                regularFont,
                center: true,
              ),
              _tableCell(
                '${_formatNumber(product.price)} ${product.currency.symbol}',
                regularFont,
                center: true,
              ),
              _tableCell(
                '${_formatNumber(total)} ${product.currency.symbol}',
                boldFont,
                center: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(9),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.Font font, {
    bool center = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(9),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.right,
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildTotals({
    required Fatora fatora,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    final rows = <pw.Widget>[];

    if (fatora.totalSy != 0) {
      rows.add(
        _totalRow(
          'الإجمالي بالليرة السورية',
          '${_formatNumber(fatora.totalSy)} ${Currency.sy.symbol}',
          regularFont,
          boldFont,
        ),
      );
    }

    if (fatora.totalDollar != 0) {
      if (rows.isNotEmpty) {
        rows.add(pw.SizedBox(height: 8));
      }

      rows.add(
        _totalRow(
          'الإجمالي بالدولار',
          '${_formatNumber(fatora.totalDollar)} ${Currency.dollar.symbol}',
          regularFont,
          boldFont,
        ),
      );
    }

    return pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
        width: 280,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(children: rows),
      ),
    );
  }

  static pw.Widget _totalRow(
    String title,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            title,
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
        ),
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildNote(String note, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ملاحظات', style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text(note, style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font regularFont, pw.Font boldFont) {
    return pw.Center(
      child: pw.Text(
        'شكراً لتعاملكم معنا',
        style: pw.TextStyle(font: boldFont, fontSize: 11),
      ),
    );
  }

  static Future<void> printInvoice({
    required User user,
    required Fatora fatora,
    required List<FatoraProduct> products,
  }) async {
    await Printing.layoutPdf(
      name: 'فاتورة-${fatora.unified}',
      onLayout: (_) async {
        return generate(user: user, fatora: fatora, products: products);
      },
    );
  }

  static Future<void> shareInvoice({
    required User user,
    required Fatora fatora,
    required List<FatoraProduct> products,
  }) async {
    final bytes = await generate(
      user: user,
      fatora: fatora,
      products: products,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'فاتورة-${user.name}-${fatora.unified}.pdf',
      subject: 'فاتورة ${user.name}',
    );
  }

  static String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    return '${date.year}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatNumber(num value) {
    return value.toStringAsFixed(2);
  }
}
