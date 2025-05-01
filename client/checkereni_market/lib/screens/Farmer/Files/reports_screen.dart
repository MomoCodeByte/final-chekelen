import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';

// Models for API responses
class CropsReport {
  final int totalCrops;

  CropsReport({required this.totalCrops});

  factory CropsReport.fromJson(dynamic json) {
    if (json is List && json.isNotEmpty) {
      final map = json[0] as Map<String, dynamic>;
      return CropsReport(
        totalCrops: (map['total_crops'] as num?)?.toInt() ?? 0,
      );
    } else if (json is Map<String, dynamic>) {
      return CropsReport(
        totalCrops: (json['total_crops'] as num?)?.toInt() ?? 0,
      );
    } else {
      throw Exception('Unexpected JSON format for CropsReport');
    }
  }
}

class OrdersReport {
  final List<Map<String, Object>> orders;

  OrdersReport({required this.orders});

  factory OrdersReport.fromJson(List<dynamic> json) {
    return OrdersReport(
      orders:
          json.map((item) {
            final map = item as Map<String, dynamic>;
            return <String, Object>{
              'order_status': map['order_status']?.toString() ?? 'unknown',
              'total': (map['total'] as num?)?.toInt() ?? 0,
            };
          }).toList(),
    );
  }
}

class TransactionsReport {
  final double totalCompleted;
  final double totalPending;
  final double totalFailed;

  TransactionsReport({
    required this.totalCompleted,
    required this.totalPending,
    required this.totalFailed,
  });

  factory TransactionsReport.fromJson(dynamic json) {
    if (json is List && json.isNotEmpty) {
      final map = json[0] as Map<String, dynamic>;
      return TransactionsReport(
        totalCompleted: (map['total_completed'] as num?)?.toDouble() ?? 0.0,
        totalPending: (map['total_pending'] as num?)?.toDouble() ?? 0.0,
        totalFailed: (map['total_failed'] as num?)?.toDouble() ?? 0.0,
      );
    } else if (json is Map<String, dynamic>) {
      return TransactionsReport(
        totalCompleted: (json['total_completed'] as num?)?.toDouble() ?? 0.0,
        totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0.0,
        totalFailed: (json['total_failed'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      throw Exception('Unexpected JSON format for TransactionsReport');
    }
  }

  double get total => totalCompleted + totalPending + totalFailed;
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  CropsReport? _cropsReport;
  OrdersReport? _ordersReport;
  TransactionsReport? _transactionsReport;
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(symbol: "\$", decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'No token found. Please log in.';
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        _fetchCropsReport(token),
        _fetchOrdersReport(token),
        _fetchTransactionsReport(token),
      ]);

      setState(() {
        _cropsReport = results[0] as CropsReport?;
        _ordersReport = results[1] as OrdersReport?;
        _transactionsReport = results[2] as TransactionsReport?;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching reports: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<CropsReport?> _fetchCropsReport(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/crops'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CropsReport.fromJson(jsonData);
      } else {
        throw Exception('Failed to load crops report: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching crops report: $e');
      return null;
    }
  }

  Future<OrdersReport?> _fetchOrdersReport(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OrdersReport.fromJson(jsonData);
      } else {
        throw Exception('Failed to load orders report: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders report: $e');
      return null;
    }
  }

  Future<TransactionsReport?> _fetchTransactionsReport(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TransactionsReport.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load transactions report: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching transactions report: $e');
      return null;
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();

      final font = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      pw.Widget _createHeader(String title) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          color: PdfColors.green700,
          child: pw.Text(
            title,
            style: pw.TextStyle(
              font: boldFont,
              color: PdfColors.white,
              fontSize: 18,
            ),
          ),
        );
      }

      String _formatCurrency(double value) {
        return currencyFormat.format(value);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Farm Management Reports',
                    style: pw.TextStyle(font: boldFont, fontSize: 24),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            );
          },
          build:
              (pw.Context context) => [
                _createHeader('Crops Report'),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                    border: pw.Border.all(color: PdfColors.green200),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Active Crops:',
                        style: pw.TextStyle(font: boldFont, fontSize: 16),
                      ),
                      pw.Text(
                        '${_cropsReport?.totalCrops ?? 'N/A'}',
                        style: pw.TextStyle(font: font, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                _createHeader('Orders Report'),
                pw.SizedBox(height: 10),
                if (_ordersReport != null && _ordersReport!.orders.isNotEmpty)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: PdfColors.green200),
                    ),
                    child: pw.Table.fromTextArray(
                      headerStyle: pw.TextStyle(
                        font: boldFont,
                        color: PdfColors.green900,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.green100,
                      ),
                      headerHeight: 30,
                      cellHeight: 40,
                      cellAlignments: {
                        0: pw.Alignment.centerLeft,
                        1: pw.Alignment.centerRight,
                      },
                      headers: ['Order Status', 'Total Orders'],
                      data:
                          _ordersReport!.orders
                              .map(
                                (order) => [
                                  order['order_status'] as String,
                                  (order['total'] as int).toString(),
                                ],
                              )
                              .toList(),
                    ),
                  )
                else
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: PdfColors.green200),
                    ),
                    child: pw.Text('No orders available.'),
                  ),
                pw.SizedBox(height: 20),

                _createHeader('Transactions Report'),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                    border: pw.Border.all(color: PdfColors.green200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildTransactionRow(
                        'Completed Transactions',
                        _transactionsReport?.totalCompleted,
                      ),
                      pw.SizedBox(height: 8),
                      _buildTransactionRow(
                        'Pending Transactions',
                        _transactionsReport?.totalPending,
                      ),
                      pw.SizedBox(height: 8),
                      _buildTransactionRow(
                        'Failed Transactions',
                        _transactionsReport?.totalFailed,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Divider(thickness: 1),
                      pw.SizedBox(height: 8),
                      _buildTransactionRow(
                        'Total Transactions Value',
                        _transactionsReport?.total,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/farm_reports_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF report exported successfully!'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildTransactionRow(
    String label,
    double? value, {
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: isBold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
            fontSize: 14,
          ),
        ),
        pw.Text(
          value != null ? currencyFormat.format(value) : 'N/A',
          style: pw.TextStyle(
            font: isBold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _exportToExcel() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          throw Exception('Storage permission denied');
        }
      }

      final excel = ex.Excel.createExcel();
      final sheet = excel['Farm Reports'];

      final titleStyle = ex.CellStyle(
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
        fontSize: 16,
      );

      sheet.merge(
        ex.CellIndex.indexByString('A1'),
        ex.CellIndex.indexByString('E1'),
      );
      final titleCell = sheet.cell(ex.CellIndex.indexByString('A1'));
      titleCell.value = 'Farm Management Reports';
      titleCell.cellStyle = titleStyle;

      sheet.merge(
        ex.CellIndex.indexByString('A2'),
        ex.CellIndex.indexByString('E2'),
      );
      final dateCell = sheet.cell(ex.CellIndex.indexByString('A2'));
      dateCell.value =
          'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}';
      dateCell.cellStyle = ex.CellStyle(
        horizontalAlign: ex.HorizontalAlign.Center,
        fontSize: 10,
      );

      final headerStyle = ex.CellStyle(
        bold: true,
        backgroundColorHex: '#E8F5E9',
        horizontalAlign: ex.HorizontalAlign.Center,
      );

      sheet.merge(
        ex.CellIndex.indexByString('A4'),
        ex.CellIndex.indexByString('E4'),
      );
      final cropsHeaderCell = sheet.cell(ex.CellIndex.indexByString('A4'));
      cropsHeaderCell.value = 'CROPS REPORT';
      cropsHeaderCell.cellStyle = headerStyle;

      sheet.cell(ex.CellIndex.indexByString('A5')).value = 'Total Active Crops';
      sheet.cell(ex.CellIndex.indexByString('B5')).value =
          _cropsReport?.totalCrops ?? 'N/A';

      sheet.merge(
        ex.CellIndex.indexByString('A7'),
        ex.CellIndex.indexByString('E7'),
      );
      final ordersHeaderCell = sheet.cell(ex.CellIndex.indexByString('A7'));
      ordersHeaderCell.value = 'ORDERS REPORT';
      ordersHeaderCell.cellStyle = headerStyle;

      sheet.cell(ex.CellIndex.indexByString('A8')).value = 'Order Status';
      sheet.cell(ex.CellIndex.indexByString('A8')).cellStyle = ex.CellStyle(
        bold: true,
      );
      sheet.cell(ex.CellIndex.indexByString('B8')).value = 'Total Orders';
      sheet.cell(ex.CellIndex.indexByString('B8')).cellStyle = ex.CellStyle(
        bold: true,
      );

      if (_ordersReport != null && _ordersReport!.orders.isNotEmpty) {
        for (var i = 0; i < _ordersReport!.orders.length; i++) {
          final order = _ordersReport!.orders[i];
          sheet.cell(ex.CellIndex.indexByString('A${i + 9}')).value =
              order['order_status'] as String;
          sheet.cell(ex.CellIndex.indexByString('B${i + 9}')).value =
              (order['total'] as int).toString();
        }
      } else {
        sheet.cell(ex.CellIndex.indexByString('A9')).value =
            'No orders available.';
      }

      final startRow = (_ordersReport?.orders.length ?? 1) + 11;

      sheet.merge(
        ex.CellIndex.indexByString('A$startRow'),
        ex.CellIndex.indexByString('E$startRow'),
      );
      final transHeaderCell = sheet.cell(
        ex.CellIndex.indexByString('A$startRow'),
      );
      transHeaderCell.value = 'TRANSACTIONS REPORT';
      transHeaderCell.cellStyle = headerStyle;

      sheet.cell(ex.CellIndex.indexByString('A${startRow + 1}')).value =
          'Total Completed';
      sheet.cell(ex.CellIndex.indexByString('B${startRow + 1}')).value =
          _transactionsReport != null
              ? currencyFormat.format(_transactionsReport!.totalCompleted)
              : 'N/A';

      sheet.cell(ex.CellIndex.indexByString('A${startRow + 2}')).value =
          'Total Pending';
      sheet.cell(ex.CellIndex.indexByString('B${startRow + 2}')).value =
          _transactionsReport != null
              ? currencyFormat.format(_transactionsReport!.totalPending)
              : 'N/A';

      sheet.cell(ex.CellIndex.indexByString('A${startRow + 3}')).value =
          'Total Failed';
      sheet.cell(ex.CellIndex.indexByString('B${startRow + 3}')).value =
          _transactionsReport != null
              ? currencyFormat.format(_transactionsReport!.totalFailed)
              : 'N/A';

      sheet.cell(ex.CellIndex.indexByString('A${startRow + 5}')).value =
          'TOTAL TRANSACTIONS VALUE';
      sheet
          .cell(ex.CellIndex.indexByString('A${startRow + 5}'))
          .cellStyle = ex.CellStyle(bold: true);

      if (_transactionsReport != null) {
        final total = _transactionsReport!.total;
        sheet
            .cell(ex.CellIndex.indexByString('B${startRow + 5}'))
            .value = currencyFormat.format(total);
        sheet
            .cell(ex.CellIndex.indexByString('B${startRow + 5}'))
            .cellStyle = ex.CellStyle(bold: true);
      } else {
        sheet.cell(ex.CellIndex.indexByString('B${startRow + 5}')).value =
            'N/A';
      }

      for (var i = 0; i < 5; i++) {
        sheet.setColWidth(i, 20);
      }

      final excelBytes = excel.encode();
      if (excelBytes == null) {
        throw Exception('Failed to encode Excel file');
      }

      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/farm_reports_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
      );
      await file.writeAsBytes(excelBytes);

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open Excel file: ${result.message}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Excel report exported successfully!'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionPieChart() {
    if (_transactionsReport == null) return const SizedBox.shrink();

    final completed = _transactionsReport!.totalCompleted;
    final pending = _transactionsReport!.totalPending;
    final failed = _transactionsReport!.totalFailed;
    final total = completed + pending + failed;

    if (total <= 0)
      return const Center(child: Text('No transaction data available'));

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: completed,
              title: '${(completed / total * 100).toStringAsFixed(1)}%',
              color: Colors.green,
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: pending,
              title: '${(pending / total * 100).toStringAsFixed(1)}%',
              color: Colors.orange,
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: failed,
              title: '${(failed / total * 100).toStringAsFixed(1)}%',
              color: Colors.red,
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildOrdersBarChart() {
    if (_ordersReport == null || _ordersReport!.orders.isEmpty) {
      return const Center(child: Text('No orders data available'));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY:
                _ordersReport!.orders
                    .map((e) => (e['total'] as num).toDouble())
                    .reduce((a, b) => a > b ? a : b) *
                1.2,
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= _ordersReport!.orders.length) {
                      return const SizedBox.shrink();
                    }
                    final status =
                        _ordersReport!.orders[value.toInt()]['order_status']
                            .toString();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  reservedSize: 30,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              _ordersReport!.orders.length,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY:
                        (_ordersReport!.orders[index]['total'] as num)
                            .toDouble(),
                    color: Colors.green[700],
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsDetail() {
    if (_transactionsReport == null)
      return const Center(child: Text('No transaction data available'));

    final completed = _transactionsReport!.totalCompleted;
    final pending = _transactionsReport!.totalPending;
    final failed = _transactionsReport!.totalFailed;
    final total = completed + pending + failed;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transactions Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTransactionDetailRow(
            'Completed',
            completed,
            total,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildTransactionDetailRow('Pending', pending, total, Colors.orange),
          const SizedBox(height: 8),
          _buildTransactionDetailRow('Failed', failed, total, Colors.red),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[400]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Value:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailRow(
    String label,
    double value,
    double total,
    Color color,
  ) {
    final percentage = total > 0 ? (value / total * 100) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(
              '${currencyFormat.format(value)} (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.grass), text: 'Crops'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Orders'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Transactions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchReports,
            tooltip: 'Refresh Reports',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Export Reports',
            onSelected: (value) {
              if (value == 'pdf') {
                _exportToPDF();
              } else if (value == 'excel') {
                _exportToExcel();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Export as PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Export as Excel'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text('Loading reports...'),
                  ],
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchReports,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Container(
                color: Colors.grey[100],
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCropsTab(),
                    _buildOrdersTab(),
                    _buildTransactionsTab(),
                  ],
                ),
              ),
    );
  }

  Widget _buildCropsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.grass,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Active Crops',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_cropsReport?.totalCrops ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total crops currently being managed',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Crop Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildInfoCard(
                'Planted Area',
                '${(_cropsReport?.totalCrops ?? 0) * 0.5} acres',
                Icons.landscape,
                Colors.green[700]!,
              ),
              _buildInfoCard(
                'Water Usage',
                '${(_cropsReport?.totalCrops ?? 0) * 100} liters',
                Icons.water_drop,
                Colors.blue[700]!,
              ),
              _buildInfoCard(
                'Est. Yield',
                '${(_cropsReport?.totalCrops ?? 0) * 25} kg',
                Icons.eco,
                Colors.amber[700]!,
              ),
              _buildInfoCard(
                'Est. Harvest',
                '${(_cropsReport?.totalCrops ?? 0) > 0 ? "In 45 days" : "N/A"}',
                Icons.calendar_today,
                Colors.purple[700]!,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm Health Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildHealthIndicator('Soil Health', 0.8),
                  const SizedBox(height: 12),
                  _buildHealthIndicator('Pest Control', 0.65),
                  const SizedBox(height: 12),
                  _buildHealthIndicator('Irrigation', 0.9),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String label, double value) {
    Color color;
    if (value > 0.7) {
      color = Colors.green;
    } else if (value > 0.4) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_ordersReport == null || _ordersReport!.orders.isEmpty) {
      return const Center(child: Text('No orders data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOrderStatCard(
                          'Total Orders',
                          _ordersReport!.orders.fold(
                            0,
                            (sum, item) => sum + (item['total'] as int),
                          ),
                          Icons.shopping_cart,
                          Colors.blue[700]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOrderStatCard(
                          'Completed',
                          _getOrderCountByStatus('completed'),
                          Icons.check_circle,
                          Colors.green[700]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOrderStatCard(
                          'Processing',
                          _getOrderCountByStatus('processing'),
                          Icons.hourglass_bottom,
                          Colors.orange[700]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOrderStatCard(
                          'Cancelled',
                          _getOrderCountByStatus('cancelled'),
                          Icons.cancel,
                          Colors.red[700]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildOrdersBarChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ordersReport!.orders.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final order = _ordersReport!.orders[index];
                      final status = order['order_status'].toString();
                      Color statusColor;
                      IconData statusIcon;

                      switch (status.toLowerCase()) {
                        case 'completed':
                          statusColor = Colors.green;
                          statusIcon = Icons.check_circle;
                          break;
                        case 'processing':
                          statusColor = Colors.orange;
                          statusIcon = Icons.hourglass_bottom;
                          break;
                        case 'cancelled':
                          statusColor = Colors.red;
                          statusIcon = Icons.cancel;
                          break;
                        default:
                          statusColor = Colors.blue;
                          statusIcon = Icons.info;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Icon(statusIcon, color: statusColor),
                        ),
                        title: Text(
                          status,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Count: ',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              '${order['total']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getOrderCountByStatus(String status) {
    if (_ordersReport == null) return 0;

    final order = _ordersReport!.orders.firstWhere(
      (order) =>
          (order['order_status'] as String).toLowerCase() ==
          status.toLowerCase(),
      orElse: () => {'total': 0},
    );

    return order['total'] as int;
  }

  Widget _buildOrderStatCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_transactionsReport != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 30,
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Total Transaction Value',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currencyFormat.format(_transactionsReport!.total),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Across all transaction statuses',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTransactionPieChart(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Completed', Colors.green),
                      const SizedBox(width: 24),
                      _buildLegendItem('Pending', Colors.orange),
                      const SizedBox(width: 24),
                      _buildLegendItem('Failed', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: _buildTransactionsDetail(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

extension on ex.Sheet {
  void setColWidth(int i, int j) {}
}
