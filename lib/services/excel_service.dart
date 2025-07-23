import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:idvault/models/aadhaar_record.dart';

class ExcelService {
  /// Export Aadhaar records to Excel file
  static Future<File> exportToExcel(List<AadhaarRecord> records) async {
    try {
      // Create new Excel document
      final excel = Excel.createExcel();
      final sheet = excel['Aadhaar Records'];

      // Remove default sheet if it exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Add headers
      const headers = [
        'ID',
        'Aadhaar Number',
        'Full Name',
        'Guardian Name',
        'Date of Birth',
        'Gender',
        'Full Address',
        'Created At',
        'Updated At',
      ];

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Add data rows
      for (int row = 0; row < records.length; row++) {
        final record = records[row];
        final rowIndex = row + 1;

        final rowData = [
          record.id?.toString() ?? '',
          record.aadhaarNumber,
          record.fullName,
          record.guardianName ?? 'N/A',
          record.dob ?? 'N/A',
          record.gender ?? 'N/A',
          record.fullAddress,
          _formatDateTime(record.createdAt),
          _formatDateTime(record.updatedAt),
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[col]);
        }
      }

      // Auto-fit columns
      for (int col = 0; col < headers.length; col++) {
        sheet.setColumnAutoFit(col);
      }

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'aadhaar_records_$timestamp.xlsx';
      final file = File('${directory.path}/$fileName');

      // Save Excel file
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        return file;
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      throw Exception('Failed to export to Excel: $e');
    }
  }

  /// Share Excel file
  static Future<void> shareExcelFile(File excelFile) async {
    try {
      if (!excelFile.existsSync()) {
        throw Exception('Excel file does not exist');
      }

      await Share.shareXFiles(
        [XFile(excelFile.path)],
        text: 'Aadhaar Records Export',
        subject: 'iDVault - Aadhaar Records',
      );
    } catch (e) {
      throw Exception('Failed to share Excel file: $e');
    }
  }

  /// Generate CSV export as alternative
  static Future<File> exportToCsv(List<AadhaarRecord> records) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'aadhaar_records_$timestamp.csv';
      final file = File('${directory.path}/$fileName');

      // CSV headers
      const headers = [
        'ID',
        'Aadhaar Number',
        'Full Name',
        'Guardian Name',
        'Date of Birth',
        'Gender',
        'Full Address',
        'Created At',
        'Updated At',
      ];

      final csvBuffer = StringBuffer();

      // Add headers
      csvBuffer.writeln(headers.map((h) => '"$h"').join(','));

      // Add data rows
      for (final record in records) {
        final rowData = [
          record.id?.toString() ?? '',
          record.aadhaarNumber,
          record.fullName,
          record.guardianName ?? 'N/A',
          record.dob ?? 'N/A',
          record.gender ?? 'N/A',
          record.fullAddress.replaceAll('"', '""'),
          _formatDateTime(record.createdAt),
          _formatDateTime(record.updatedAt),
        ];

        csvBuffer.writeln(rowData.map((field) => '"$field"').join(','));
      }

      await file.writeAsString(csvBuffer.toString());
      return file;
    } catch (e) {
      throw Exception('Failed to export to CSV: $e');
    }
  }

  /// Create summary report
  static Future<File> createSummaryReport(List<AadhaarRecord> records) async {
    try {
      final excel = Excel.createExcel();

      // Summary Sheet
      final summarySheet = excel['Summary'];
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Summary data
      final totalRecords = records.length;
      final recordsWithGuardian = records
          .where((r) => r.guardianName != null)
          .length;
      final recordsWithDOB = records.where((r) => r.dob != null).length;
      final recordsWithGender = records.where((r) => r.gender != null).length;
      final validRecords = records.where((r) => r.isValid).length;

      // Add summary information
      final summaryData = [
        ['Metric', 'Value'],
        ['Total Records', totalRecords.toString()],
        ['Records with Guardian Name', recordsWithGuardian.toString()],
        ['Record with Date of Birth', recordsWithDOB.toString()],
        ['Records with Gender', recordsWithGender.toString()],
        ['Valid Records', validRecords.toString()],
        ['Export Date', _formatDateTime(DateTime.now())],
      ];

      for (int row = 0; row < summaryData.length; row++) {
        for (int col = 0; col < summaryData[row].length; col++) {
          final cell = summarySheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
          );
          cell.value = TextCellValue(summaryData[row][col]);

          if (row == 0) {
            cell.cellStyle = CellStyle(bold: true);
          }
        }
      }

      // Data Sheet
      final dataSheet = excel['Records'];
      const headers = [
        'ID',
        'Aadhaar Number',
        'Date of Birth',
        'Full Name',
        'Guardian Name',
        'Gender',
        'Full Address',
        'Created At',
        'Updated At',
      ];

      for (int col = 0; col < headers.length; col++) {
        final cell = dataSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = CellStyle(bold: true);
      }

      for (int row = 0; row < records.length; row++) {
        final record = records[row];
        final rowData = [
          record.id?.toString() ?? '',
          record.aadhaarNumber,
          record.dob ?? 'N/A',
          record.fullName,
          record.guardianName ?? 'N/A',
          record.gender ?? 'N/A',
          record.fullAddress,
          _formatDateTime(record.createdAt),
          _formatDateTime(record.updatedAt),
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = dataSheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
          );
          cell.value = TextCellValue(rowData[col]);
        }
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'aadhaar_summary_report_$timestamp.xlsx';
      final file = File('${directory.path}/$fileName');

      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        return file;
      } else {
        throw Exception('Failed to encode summary report');
      }
    } catch (e) {
      throw Exception('Failed to create summary report: $e');
    }
  }

  /// Format DateTime for display
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get export file size
  static Future<String> getFileSize(File file) async {
    if (!file.existsSync()) return '0 B';

    final bytes = await file.length();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
