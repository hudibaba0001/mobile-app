class ExportData {
  final String sheetName;
  final List<String> headers;
  final List<List<dynamic>> rows;

  ExportData({
    this.sheetName = 'Data',
    required this.headers,
    required this.rows,
  });
}
