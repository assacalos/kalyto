import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'export_file_io.dart' if (dart.library.html) 'export_file_web.dart' as io;

/// Service d'export des listes en CSV ou Excel (xlsx).
class ExportService {
  static const String _csvSep = ';';
  static const String _utf8Bom = '\uFEFF';

  static String cellStr(Object? v) {
    if (v == null) return '';
    if (v is DateTime) return DateFormat('dd/MM/yyyy').format(v);
    return v.toString();
  }

  static String _escapeCsv(String s) {
    if (s.contains(_csvSep) || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Génère le contenu CSV (pour partage ou fichier).
  static String buildCsv(List<String> headers, List<List<Object?>> rows) {
    final sb = StringBuffer(_utf8Bom);
    sb.writeln(headers.map(_escapeCsv).join(_csvSep));
    for (final row in rows) {
      sb.writeln(row.map((c) => _escapeCsv(cellStr(c))).join(_csvSep));
    }
    return sb.toString();
  }

  /// Exporte en CSV et partage le fichier (ou le texte sur Web).
  static Future<void> exportCsv({
    required List<String> headers,
    required List<List<Object?>> rows,
    required String filenameBase,
  }) async {
    final csv = buildCsv(headers, rows);
    final path = await io.writeTextToTemp('$filenameBase.csv', csv);
    if (path != null) {
      await Share.shareXFiles([XFile(path)]);
    } else {
      await Share.share(csv, subject: filenameBase);
    }
  }

  /// Exporte en Excel (xlsx) et partage le fichier. Sur Web, partage le CSV à la place.
  static Future<void> exportExcel({
    required List<String> headers,
    required List<List<Object?>> rows,
    required String filenameBase,
    String sheetName = 'Export',
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final v = row[c];
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        if (v is num) {
          cell.value = DoubleCellValue(v.toDouble());
        } else {
          cell.value = TextCellValue(cellStr(v));
        }
      }
    }
    final fileBytes = excel.encode();
    if (fileBytes == null) return;
    String? path;
    if (!kIsWeb) {
      path = await io.writeBytesToTemp('$filenameBase.xlsx', fileBytes);
    }
    if (path != null) {
      await Share.shareXFiles([XFile(path)]);
    } else {
      await exportCsv(headers: headers, rows: rows, filenameBase: filenameBase);
    }
  }
}
