import 'package:csv/csv.dart';
import '../models/export_data.dart';

class CsvExporter {
  static String export(ExportData data) {
    final List<List<dynamic>> rows = [];
    rows.add(data.headers);
    rows.addAll(data.rows);

    return const ListToCsvConverter().convert(rows) + '\r\n';
  }
}
