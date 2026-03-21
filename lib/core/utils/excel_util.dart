import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelUtil {
  static Future<void> generateAndShareReport(List<Map<String, dynamic>> data) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Filter Report'];
    excel.delete('Sheet1');

    // Add Headers
    sheetObject.appendRow([
      TextCellValue('Timestamp'),
      TextCellValue('Current Filter'),
      TextCellValue('System Status'),
      TextCellValue('Remaining Time'),
    ]);

    // Add Data Rows
    for (var row in data) {
      sheetObject.appendRow([
        TextCellValue(row['timestamp'] ?? ''),
        TextCellValue(row['current_filter'] ?? ''),
        TextCellValue(row['system_status'] ?? ''),
        TextCellValue(row['remaining_time'] ?? ''),
      ]);
    }

    // Save File
    var fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/filter_report.xlsx');
      await file.writeAsBytes(fileBytes);

      // Share File
      await Share.shareXFiles([XFile(file.path)], text: 'Filter System Report');
    }
  }
}
