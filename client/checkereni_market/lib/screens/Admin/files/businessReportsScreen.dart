import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class BusinessReportsScreen extends StatefulWidget {
  const BusinessReportsScreen({super.key});

  @override
  _BusinessReportsScreenState createState() => _BusinessReportsScreenState();
}

class _BusinessReportsScreenState extends State<BusinessReportsScreen>
    with SingleTickerProviderStateMixin {
  // Report data
  Map<String, dynamic> usersReport = {'data': []};
  Map<String, dynamic> ordersReport = {'data': []};
  Map<String, dynamic> transactionsReport = {};
  Map<String, dynamic> cropsReport = {};
  Map<String, dynamic> dailyOrdersReport = {};
  List<Map<String, dynamic>> monthlySalesData = [];

  // UI state
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedReportType = 'All';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // Theme colors
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color accentColor = const Color(0xFF4CAF50);
  final Color secondaryAccentColor = const Color(0xFF8BC34A);
  final Color tertiaryColor = const Color(0xFFE8F5E9);

  // Animation controller
  late TabController _tabController;
  final List<String> _reportTabs = [
    'Overview',
    'Users',
    'Orders',
    'Sales',
    'Crops',
  ];

  // Storage
  final _secureStorage = const FlutterSecureStorage();

  // Scaling factors for responsiveness
  double _cardHeight = 180;
  int _crossAxisCount = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _reportTabs.length, vsync: this);
    _generateMonthlySalesData();
    _fetchAllReports();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setResponsiveValues();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setResponsiveValues() {
    final width = MediaQuery.of(context).size.width;
    if (mounted) {
      setState(() {
        if (width < 600) {
          _crossAxisCount = 1;
          _cardHeight = 150;
        } else if (width < 900) {
          _crossAxisCount = 2;
          _cardHeight = 160;
        } else {
          _crossAxisCount = 3;
          _cardHeight = 180;
        }
      });
    }
  }

  void _generateMonthlySalesData() {
    final now = DateTime.now();
    final formatter = DateFormat('MMM');
    monthlySalesData = List.generate(6, (index) {
      final month = now.subtract(Duration(days: 30 * (5 - index)));
      return {
        'month': formatter.format(month),
        'sales': 5000 + (index * 1200) + (index % 2 == 0 ? 800 : -500),
      };
    });
  }

  Future<void> _fetchAllReports() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final token =
          await _secureStorage.read(key: 'auth_token') ?? 'dummy_token';

      // Uncomment this section to use real API
      /*
      final responses = await Future.wait([
        _fetchReport('/api/business/users', token),
        _fetchReport('/api/business/orders', token),
        _fetchReport('/api/business/transactions', token),
        _fetchReport('/api/business/crops', token),
        _fetchReport('/api/business/daily-orders', token),
      ]).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      setState(() {
        usersReport = _parseApiResponse(responses[0], 'data');
        ordersReport = _parseApiResponse(responses[1], 'data');
        transactionsReport = _parseApiResponse(responses[2]);
        cropsReport = _parseApiResponse(responses[3]);
        dailyOrdersReport = _parseApiResponse(responses[4]);
        _isLoading = false;
      });
      */

      // Using dummy data for development
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() {
        usersReport = {
          'data': [
            {'role': 'Admin', 'total': 5},
            {'role': 'Farmer', 'total': 50},
            {'role': 'Customer', 'total': 200},
          ],
        };

        ordersReport = {
          'data': [
            {'order_status': 'Completed', 'total': 30},
            {'order_status': 'Pending', 'total': 10},
            {'order_status': 'Cancelled', 'total': 5},
          ],
        };

        transactionsReport = {
          'total_sales': 12500.75,
          'success_rate': 85,
          'pending_rate': 10,
          'failure_rate': 5,
          'avg_order_value': 125.50,
        };

        cropsReport = {
          'active_crops': 120,
          'ready_for_harvest': 45,
          'unique_crop_types': 8,
        };

        dailyOrdersReport = {'daily_orders': 15};

        _isLoading = false;
      });

      if (_isRefreshing && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reports refreshed successfully'),
            backgroundColor: primaryColor,
          ),
        );
        setState(() => _isRefreshing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _parseApiResponse(dynamic response, [String? dataKey]) {
    try {
      if (response is Map<String, dynamic>) {
        if (dataKey != null && response.containsKey(dataKey)) {
          final data = response[dataKey];
          if (data is List) {
            return {
              ...response,
              dataKey: List<Map<String, dynamic>>.from(
                data.whereType<Map<String, dynamic>>(),
              ),
            };
          }
        }
        return response;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _fetchReport(
    String endpoint,
    String token,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('http://localhost:3000$endpoint'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Token si sahihi');
      } else {
        throw Exception('Failed to load $endpoint: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Data format error: ${e.message}');
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: accentColor,
              onSurface: Colors.black,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange && mounted) {
      setState(() {
        _dateRange = picked;
        _isRefreshing = true;
      });
      _fetchAllReports();
    }
  }

  Future<void> _exportToPdf() async {
    _showExportingDialog('Generating PDF');

    try {
      final pdf = pw.Document();
      final ByteData logoData = await rootBundle.load(
        'assets/company_logo.png',
      );
      pw.MemoryImage? logoImage;

      if (logoData != null) {
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      }

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            theme: pw.ThemeData.withFont(
              base: await PdfGoogleFonts.robotoRegular(),
              bold: await PdfGoogleFonts.robotoBold(),
            ),
          ),
          header:
              (context) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (logoImage != null) pw.Image(logoImage, width: 60),
                  pw.Text(
                    'Business Analytics Report',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
          footer:
              (context) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on ${DateFormat.yMMMMd().format(DateTime.now())}',
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                  ),
                ],
              ),
          build:
              (context) => [
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Report Period: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '${DateFormat.yMMMd().format(_dateRange.start)} - ${DateFormat.yMMMd().format(_dateRange.end)}',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, text: 'Executive Summary'),
                pw.Paragraph(
                  text:
                      'This report provides a comprehensive overview of business operations.',
                ),
                pw.SizedBox(height: 10),
                pw.Header(level: 2, text: 'Key Metrics'),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPdfMetricBox(
                      'Total Users',
                      usersReport['data']?.fold(
                            0,
                            (sum, item) => sum + (item['total'] as num),
                          ) ??
                          0,
                    ),
                    _buildPdfMetricBox(
                      'Today\'s Orders',
                      dailyOrdersReport['daily_orders'] ?? 0,
                    ),
                    _buildPdfMetricBox(
                      'Total Sales',
                      '\$${(transactionsReport['total_sales'] ?? 0).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/business_report.pdf');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      Navigator.pop(context);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'business_report.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Container _buildPdfMetricBox(String title, dynamic value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green700),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      width: 150,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value.toString(),
            style: const pw.TextStyle(fontSize: 18),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel() async {
    _showExportingDialog('Generating Excel');

    try {
      final excelFile = excel.Excel.createExcel();
      final usersSheet = excelFile['Users'];
      usersSheet.appendRow(['Role', 'Count']);

      for (final item in (usersReport['data'] as List? ?? [])) {
        if (item is Map<String, dynamic>) {
          usersSheet.appendRow([
            item['role']?.toString() ?? '',
            item['total']?.toString() ?? '',
          ]);
        }
      }

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/business_report.xlsx');
      final bytes = excelFile.save();

      if (bytes != null) {
        await file.writeAsBytes(bytes);
        if (!mounted) return;
        Navigator.pop(context);
        await Share.shareFiles([file.path], text: 'Business Report');
      } else {
        throw Exception('Failed to generate Excel file');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Export Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportToPdf();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.table_chart, color: Colors.green),
                  ),
                  title: const Text('Export as Excel'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportToExcel();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    dynamic value,
    IconData icon, [
    Color? customColor,
  ]) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (customColor ?? primaryColor).withOpacity(0.05),
              (customColor ?? primaryColor).withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (customColor ?? primaryColor).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: customColor ?? primaryColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: customColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildPieChart(Map<String, dynamic> data, String title) {
    final pieData =
        (data['data'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
        [];
    final total = pieData.fold<double>(0, (sum, item) {
      final value = item.values.first;
      return sum + (value is num ? value.toDouble() : 0);
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  sections:
                      pieData.map((item) {
                        final value = item.values.first;
                        final numValue = value is num ? value.toDouble() : 0;
                        return PieChartSectionData(
                          color: _getColorForIndex(pieData.indexOf(item)),
                          value: numValue.toDouble(),
                          title:
                              total > 0
                                  ? '${(numValue / total * 100).toStringAsFixed(1)}%'
                                  : '',
                          radius: 20,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  pieData.map((item) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: _getColorForIndex(pieData.indexOf(item)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.keys.first,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Color _getColorForIndex(int index) {
    final colors = [
      primaryColor,
      accentColor,
      secondaryAccentColor,
      Colors.amber,
      Colors.blue,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }

  Widget _buildBarChart(Map<String, dynamic> data, String title) {
    final barData =
        (data['data'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
        [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (barData.fold<double>(0, (max, item) {
                            final value = item.values.first;
                            final numValue =
                                value is num ? value.toDouble() : 0;
                            return numValue > max ? numValue.toDouble() : max;
                          }) *
                          1.2),
                  barGroups:
                      barData.map((item) {
                        final value = item.values.first;
                        return BarChartGroupData(
                          x: barData.indexOf(item),
                          barRods: [
                            BarChartRodData(
                              toY: value is num ? value.toDouble() : 0,
                              color: _getColorForIndex(barData.indexOf(item)),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              barData[value.toInt()].keys.first,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, String title) {
    final spots =
        data.map((item) {
          return FlSpot(
            data.indexOf(item).toDouble(),
            (item['sales'] as num?)?.toDouble() ?? 0,
          );
        }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: accentColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              data[value.toInt()]['month'],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildDataTable(
    List<Map<String, dynamic>> data,
    List<String> columns,
    String title,
  ) {
    final validData = data.whereType<Map<String, dynamic>>().toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns:
                    columns
                        .map(
                          (column) => DataColumn(
                            label: Text(
                              column,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                rows:
                    validData
                        .map(
                          (row) => DataRow(
                            cells:
                                columns
                                    .map(
                                      (column) => DataCell(
                                        Text(row[column]?.toString() ?? 'N/A'),
                                      ),
                                    )
                                    .toList(),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildTransactionsWidget() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildProgressIndicator(
                  'Success Rate',
                  (transactionsReport['success_rate'] as num?)?.toDouble() ?? 0,
                  Colors.green,
                ),
                _buildProgressIndicator(
                  'Pending Rate',
                  (transactionsReport['pending_rate'] as num?)?.toDouble() ?? 0,
                  Colors.orange,
                ),
                _buildProgressIndicator(
                  'Failure Rate',
                  (transactionsReport['failure_rate'] as num?)?.toDouble() ?? 0,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Total Sales: \$${(transactionsReport['total_sales'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 700.ms);
  }

  Widget _buildProgressIndicator(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[200],
                  color: color,
                  strokeWidth: 10,
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNoDataPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets1.lottiefiles.com/packages/lf20_0s6tfbuc.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchAllReports,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            _reportTabs.map((tab) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tab),
                  selected: _selectedReportType == tab,
                  onSelected: (selected) {
                    if (mounted) setState(() => _selectedReportType = tab);
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: primaryColor.withOpacity(0.2),
                  checkmarkColor: primaryColor,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (usersReport['data']?.isEmpty ?? true) {
      return _buildNoDataPlaceholder();
    }

    switch (_selectedReportType) {
      case 'Users':
        return Column(
          children: [
            _buildPieChart(usersReport, 'Users by Role'),
            const SizedBox(height: 16),
            _buildDataTable(
              (usersReport['data'] as List?)
                      ?.whereType<Map<String, dynamic>>()
                      .toList() ??
                  [],
              ['Role', 'Count', 'Percentage'],
              'User Distribution',
            ),
          ],
        );
      case 'Orders':
        return Column(
          children: [
            _buildBarChart(ordersReport, 'Orders by Status'),
            const SizedBox(height: 16),
            _buildDataTable(
              (ordersReport['data'] as List?)
                      ?.whereType<Map<String, dynamic>>()
                      .toList() ??
                  [],
              ['Status', 'Count', 'Percentage'],
              'Order Distribution',
            ),
          ],
        );
      case 'Sales':
        return Column(
          children: [
            _buildTransactionsWidget(),
            const SizedBox(height: 16),
            _buildLineChart(monthlySalesData, 'Monthly Sales Trend'),
          ],
        );
      case 'Crops':
        return Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: _crossAxisCount,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildSummaryCard(
                  'Active Crops',
                  cropsReport['active_crops'] ?? 0,
                  Icons.eco,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Ready for Harvest',
                  cropsReport['ready_for_harvest'] ?? 0,
                  Icons.agriculture,
                  Colors.amber,
                ),
                if (_crossAxisCount > 1)
                  _buildSummaryCard(
                    'Unique Types',
                    cropsReport['unique_crop_types'] ?? 0,
                    Icons.category,
                    Colors.purple,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPieChart({
              'data': [
                {'Tomatoes': 120},
                {'Potatoes': 80},
                {'Carrots': 60},
                {'Lettuce': 40},
                {'Onions': 30},
                {'Others': 50},
              ],
            }, 'Crop Distribution'),
          ],
        );
      default: // Overview
        return Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: _crossAxisCount,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildSummaryCard(
                  'Total Users',
                  (usersReport['data'] as List?)?.fold<int>(
                        0,
                        (sum, item) =>
                            sum + ((item as Map)['total'] as int? ?? 0),
                      ) ??
                      0,
                  Icons.people,
                ),
                _buildSummaryCard(
                  'Today\'s Orders',
                  dailyOrdersReport['daily_orders'] ?? 0,
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                _buildSummaryCard(
                  'Total Sales',
                  '\$${(transactionsReport['total_sales'] ?? 0).toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.blue,
                ),
                if (_crossAxisCount > 1)
                  _buildSummaryCard(
                    'Active Crops',
                    cropsReport['active_crops'] ?? 0,
                    Icons.eco,
                    Colors.green,
                  ),
                if (_crossAxisCount > 1)
                  _buildSummaryCard(
                    'Avg Order Value',
                    '\$${(transactionsReport['avg_order_value'] ?? 0).toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                if (_crossAxisCount > 1)
                  _buildSummaryCard(
                    'Completed Orders',
                    (ordersReport['data'] as List?)?.firstWhere(
                          (item) =>
                              (item as Map)['order_status'] == 'Completed',
                          orElse: () => {'total': 0},
                        )['total'] ??
                        0,
                    Icons.check_circle,
                    Colors.teal,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLineChart(monthlySalesData, 'Monthly Sales Trend'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPieChart(usersReport, 'Users by Role')),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBarChart(ordersReport, 'Orders by Status'),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildTabsView() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: _reportTabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: primaryColor,
          isScrollable: true,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children:
                _reportTabs.map((tab) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildReportContent(),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _showExportOptions,
          ),
          IconButton(
            icon: Icon(_isRefreshing ? Icons.sync : Icons.refresh),
            onPressed: () {
              if (mounted) setState(() => _isRefreshing = true);
              _fetchAllReports();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchAllReports,
                color: primaryColor,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, tertiaryColor.withOpacity(0.3)],
                    ),
                  ),
                  child:
                      isTablet
                          ? _buildTabsView()
                          : SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildFilterChips(),
                                  const SizedBox(height: 16),
                                  _buildReportContent(),
                                ],
                              ),
                            ),
                          ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExportOptions,
        backgroundColor: primaryColor,
        child: const Icon(Icons.save_alt, color: Colors.white),
      ),
    );
  }
}
