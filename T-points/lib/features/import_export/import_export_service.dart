/// Import/Export service for CSV and Excel files.
library;

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:t_points/features/calculation/calculation_engine.dart';
import 'package:t_points/features/sessions/session_model.dart';
import 'package:uuid/uuid.dart';

class ImportExportService {
  static const _uuid = Uuid();

  /// Import pairs from a CSV file.
  /// Format: System Name, b, T (3 columns).
  static Future<List<ScoreSystem>?> importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.single.bytes;
    if (bytes == null) return null;
    final content = utf8.decode(bytes, allowMalformed: true);

    // Auto-detect delimiter: semicolon ';' (often used in Russian Excel/Numbers) or comma ','
    String delimiter = ',';
    if (content.contains(';') && !content.contains('\t')) {
      delimiter = ';';
    }

    final rows = CsvToListConverter(fieldDelimiter: delimiter).convert(content);

    return _parseRows(rows);
  }

  /// Import pairs from an Excel file.
  /// Format: System Name, b, T (3 columns).
  static Future<List<ScoreSystem>?> importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.single.bytes;
    if (bytes == null) return null;
    final excel = xl.Excel.decodeBytes(bytes);

    final rows = <List<dynamic>>[];
    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      for (final row in sheet.rows) {
        if (row.length >= 3) {
           rows.add([row[0]?.value, row[1]?.value, row[2]?.value]);
        } else if (row.length == 2) {
           rows.add(['Импорт', row[0]?.value, row[1]?.value]);
        }
      }
      break; // Only first sheet
    }
    return _parseRows(rows);
  }

  static List<ScoreSystem> _parseRows(List<List<dynamic>> rows) {
    final systemsMap = <String, ScoreSystem>{};

    for (final row in rows) {
      if (row.length < 2) continue;
      
      String sysName = 'Импорт';
      double? b;
      int? t;

      if (row.length >= 3) {
        sysName = row[0].toString().trim();
        final bStr = row[1].toString().replaceAll(',', '.').replaceAll(' ', '').trim();
        b = double.tryParse(bStr);
        final tStr = row[2].toString().replaceAll(' ', '').trim();
        t = int.tryParse(tStr);
      } else {
        final bStr = row[0].toString().replaceAll(',', '.').replaceAll(' ', '').trim();
        b = double.tryParse(bStr);
        final tStr = row[1].toString().replaceAll(' ', '').trim();
        t = int.tryParse(tStr);
      }

      if (b == null || t == null) continue;
      if (t < 30) continue;

      if (!systemsMap.containsKey(sysName)) {
        systemsMap[sysName] = ScoreSystem(id: _uuid.v4(), name: sysName, pairs: []);
      }
      
      final sys = systemsMap[sysName]!;
      final pair = ScorePair(systemId: sys.id, b: b, t: t);
      systemsMap[sysName] = sys.copyWith(pairs: [...sys.pairs, pair]);
    }

    return systemsMap.values.toList();
  }

  /// Export systems to CSV.
  static Future<void> exportCsv(List<ScoreSystem> systems, Map<String, ComputationResult?> results) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить как CSV',
      fileName: 't_points_systems.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (outputPath == null) return;

    final rows = <List<dynamic>>[
      ['System Name', 'b', 'T'],
    ];

    for (final sys in systems) {
      for (final pair in sys.pairs) {
        rows.add([sys.name, pair.b, pair.t]);
      }
    }

    rows.addAll([[], ['Результаты систем']]);
    
    for (final sys in systems) {
      final res = results[sys.id];
      if (res?.globalBounds != null) {
        final gb = res!.globalBounds!;
        rows.addAll([
          [sys.name],
          ['s_min', gb.sMin.toStringAsFixed(4)],
          ['s_max', gb.sMax.toStringAsFixed(4)],
          ['m_min', gb.mMin.toStringAsFixed(4)],
          ['m_max', gb.mMax.toStringAsFixed(4)],
          [],
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(rows);
    await File(outputPath).writeAsString(csv);
  }

  /// Export systems to Excel.
  static Future<void> exportExcel(List<ScoreSystem> systems, Map<String, ComputationResult?> results) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить как Excel',
      fileName: 't_points_systems.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (outputPath == null) return;

    final excel = xl.Excel.createExcel();
    final sheet = excel['T-points'];

    // Header
    sheet.appendRow([
      xl.TextCellValue('System Name'),
      xl.TextCellValue('b'),
      xl.TextCellValue('T'),
    ]);

    // Data
    for (final sys in systems) {
      for (final pair in sys.pairs) {
        sheet.appendRow([
          xl.TextCellValue(sys.name),
          xl.DoubleCellValue(pair.b),
          xl.IntCellValue(pair.t),
        ]);
      }
    }

    // Results
    sheet.appendRow([]);
    sheet.appendRow([xl.TextCellValue('Результаты систем')]);
    
    for (final sys in systems) {
      final res = results[sys.id];
      if (res?.globalBounds != null) {
        final gb = res!.globalBounds!;
        sheet.appendRow([xl.TextCellValue(sys.name)]);
        sheet.appendRow([xl.TextCellValue('s_min'), xl.DoubleCellValue(gb.sMin)]);
        sheet.appendRow([xl.TextCellValue('s_max'), xl.DoubleCellValue(gb.sMax)]);
        sheet.appendRow([xl.TextCellValue('m_min'), xl.DoubleCellValue(gb.mMin)]);
        sheet.appendRow([xl.TextCellValue('m_max'), xl.DoubleCellValue(gb.mMax)]);
        sheet.appendRow([]);
      }
    }

    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes != null) {
      await File(outputPath).writeAsBytes(bytes);
    }
  }
}
