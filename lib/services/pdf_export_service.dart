import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class PdfExportService {
  static final PdfExportService instance = PdfExportService._();
  PdfExportService._();
  final _db = DatabaseHelper.instance;

  Future<void> exportRentRoll() async {
    final leases = await _db.getActiveLeasesWithDetails();
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Rent Roll Report',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
        ),
        footer: (context) => pw.Text(
          'Generated ${dateFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
        build: (context) => [
          pw.Paragraph(
              text:
                  'Active Leases: ${leases.length} | Generated: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Tenant', 'Property', 'Unit', 'Rent', 'Period', 'Status'],
            data: leases.map((l) {
              final start = dateFormat
                  .format(DateTime.parse(l['start_date'] as String));
              final end = dateFormat
                  .format(DateTime.parse(l['end_date'] as String));
              final isExpired =
                  DateTime.parse(l['end_date'] as String).isBefore(DateTime.now());
              return [
                l['tenant_name'] as String? ?? 'Unknown',
                l['property_name'] as String? ?? 'Unknown',
                'Unit ${l['unit_number'] as String? ?? '?'}',
                currencyFormat.format((l['rent_amount'] as num?)?.toDouble() ?? 0),
                '$start - $end',
                isExpired ? 'Expired' : 'Active',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300)),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Total Active Leases: ${leases.where((l) => DateTime.parse(l['end_date'] as String).isAfter(DateTime.now())).length}'),
                pw.Text('Total Monthly Rent: ${currencyFormat.format(
                  leases.fold<double>(0, (sum, l) =>
                      sum + ((l['rent_amount'] as num?)?.toDouble() ?? 0)),
                )}'),
              ],
            ),
          ),
        ],
      ),
    );

    await _saveAndShare(pdf, 'rent_roll_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  Future<void> exportPropertyReport(int propertyId) async {
    final property = await _db.getPropertyWithOwner(propertyId);
    if (property == null) return;
    final units = await _db.getUnitsByProperty(propertyId);
    final maintenance =
        await _db.getMaintenanceRequestsByProperty(propertyId);
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text(property['name'] as String? ?? 'Property Report'),
        ),
        build: (context) => [
          pw.Paragraph(
              text:
                  'Address: ${property['address']}, ${property['city']}, ${property['state']} ${property['zip']}'),
          pw.Paragraph(
              text: 'Owner: ${property['owner_name'] ?? 'Unknown'}'),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Units (${units.length})'),
          pw.TableHelper.fromTextArray(
            headers: ['Unit', 'BR/BA', 'Rent', 'Status'],
            data: units.map((u) => [
              u['unit_number'] as String? ?? '',
              '${u['bedrooms']}/${u['bathrooms']}',
              currencyFormat
                  .format((u['rent_amount'] as num?)?.toDouble() ?? 0),
              (u['is_occupied'] as int?) == 1 ? 'Occupied' : 'Vacant',
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 24),
          pw.Header(level: 1, text: 'Maintenance Requests'),
          maintenance.isEmpty
              ? pw.Paragraph(text: 'No maintenance requests')
              : pw.TableHelper.fromTextArray(
                  headers: ['Title', 'Priority', 'Status', 'Date'],
                  data: maintenance.map((m) => [
                    m['title'] as String? ?? '',
                    m['priority'] as String? ?? '',
                    m['status'] as String? ?? '',
                    dateFormat
                        .format(DateTime.parse(m['created_at'] as String)),
                  ]).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blue800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
        ],
      ),
    );

    await _saveAndShare(pdf,
        'property_${property['name']}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  Future<void> exportMaintenanceReport() async {
    final requests = await _db.queryAll('maintenance_requests');
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Maintenance Report'),
        ),
        build: (context) => [
          pw.Paragraph(
              text:
                  'Total Requests: ${requests.length} | Generated: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Title', 'Priority', 'Status', 'Date'],
            data: requests.map((r) => [
              r['title'] as String? ?? '',
              r['priority'] as String? ?? '',
              r['status'] as String? ?? '',
              dateFormat.format(DateTime.parse(r['created_at'] as String)),
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300)),
            ),
          ),
          pw.SizedBox(height: 24),
          _buildSummaryBox(context, requests),
        ],
      ),
    );

    await _saveAndShare(pdf,
        'maintenance_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  pw.Widget _buildSummaryBox(
      pw.Context context, List<Map<String, dynamic>> requests) {
    final pending = requests.where((r) => r['status'] == 'Pending').length;
    final inProgress =
        requests.where((r) => r['status'] == 'In Progress').length;
    final completed =
        requests.where((r) => r['status'] == 'Completed').length;
    final emergency =
        requests.where((r) => r['priority'] == 'Emergency').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 4),
          pw.Text('Pending: $pending | In Progress: $inProgress | Completed: $completed'),
          pw.Text('Emergency: $emergency'),
        ],
      ),
    );
  }

  Future<String> _saveToFile(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _saveAndShare(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final path = await _saveToFile(bytes, filename);
    await Share.shareXFiles(
      [XFile(path)],
      subject: filename,
    );
  }
}
