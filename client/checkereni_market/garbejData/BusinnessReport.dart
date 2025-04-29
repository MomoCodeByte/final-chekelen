// ime fanya kazi kwa kodi ulizo punguza ila logic aipo sasa naomba nikumbe izi ufix kwa ajiri yangu kaka

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
  Map<String, dynamic> usersReport = {};
  Map<String, dynamic> ordersReport = {};
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
      _setResponsiveValues();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setResponsiveValues() {
    final width = MediaQuery.of(context).size.width;
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

  void _generateMonthlySalesData() {
    // Generate sample monthly data (would come from API in production)
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
    setState(() => _isLoading = true);

    try {
      // Simulate token retrieval for authentication
      final token =
          await _secureStorage.read(key: 'auth_token') ?? 'dummy_token';

      final responses = await Future.wait([
        _fetchReport('/api/business/users', token),
        _fetchReport('/api/business/orders', token),
        _fetchReport('/api/business/transactions', token),
        _fetchReport('/api/business/crops', token),
        _fetchReport('/api/business/daily-orders', token),
      ]);

      setState(() {
        usersReport = responses[0];
        ordersReport = responses[1];
        transactionsReport = responses[2];
        cropsReport = responses[3];
        dailyOrdersReport = responses[4];
        _isLoading = false;
      });

      // Show success message
      if (_isRefreshing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reports refreshed successfully'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _isRefreshing = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reports: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchReport(
    String endpoint,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('http://localhost:3000$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load $endpoint: ${response.statusCode}');
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

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
        _isRefreshing = true;
      });
      // Here you would typically refetch data with the new date range
      _fetchAllReports();
    }
  }

  Future<void> _exportToPdf() async {
    // Show loading indicator
    _showExportingDialog('Generating PDF');

    try {
      // Create a PDF document
      final pdf = pw.Document();

      // Add logo and header
      final ByteData logoData = await rootBundle.load(
        'assets/company_logo.png',
      );
      pw.MemoryImage? logoImage;

      if (logoData != null) {
        final Uint8List logoBytes = logoData.buffer.asUint8List();
        logoImage = pw.MemoryImage(logoBytes);
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

                // Executive Summary
                pw.Header(level: 1, text: 'Executive Summary'),
                pw.Paragraph(
                  text:
                      'This report provides a comprehensive overview of business operations including user statistics, order fulfillment, financial transactions, and agricultural production for the selected period.',
                ),
                pw.SizedBox(height: 10),

                // Key Metrics
                pw.Header(level: 2, text: 'Key Metrics'),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPdfMetricBox(
                      'Total Users',
                      usersReport['data']?.fold(
                            0,
                            (sum, item) => sum + item['total'],
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
                pw.SizedBox(height: 20),

                // Users Report
                pw.Header(level: 1, text: 'User Statistics'),
                pw.Table.fromTextArray(
                  context: context,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.green100,
                  ),
                  headerHeight: 25,
                  cellHeight: 25,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                  },
                  data: [
                    ['Role', 'Count', 'Percentage'],
                    ...(usersReport['data'] as List? ?? []).map((item) {
                      final total =
                          usersReport['data']?.fold(
                            0,
                            (sum, i) => sum + i['total'],
                          ) ??
                          1;
                      final percentage = (item['total'] / total * 100)
                          .toStringAsFixed(1);
                      return [
                        item['role'],
                        item['total'].toString(),
                        '$percentage%',
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Orders Report
                pw.Header(level: 1, text: 'Order Statistics'),
                pw.Table.fromTextArray(
                  context: context,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.green100,
                  ),
                  headerHeight: 25,
                  cellHeight: 25,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                  },
                  data: [
                    ['Status', 'Count', 'Percentage'],
                    ...(ordersReport['data'] as List? ?? []).map((item) {
                      final total =
                          ordersReport['data']?.fold(
                            0,
                            (sum, i) => sum + i['total'],
                          ) ??
                          1;
                      final percentage = (item['total'] / total * 100)
                          .toStringAsFixed(1);
                      return [
                        item['order_status'],
                        item['total'].toString(),
                        '$percentage%',
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Financial Overview
                pw.Header(level: 1, text: 'Financial Overview'),
                pw.Paragraph(
                  text:
                      'Total Sales: \$${(transactionsReport['total_sales'] ?? 0).toStringAsFixed(2)}',
                ),
                pw.Paragraph(
                  text:
                      'Transaction Success Rate: ${transactionsReport['success_rate'] ?? 0}%',
                ),
                pw.SizedBox(height: 10),

                pw.Table.fromTextArray(
                  context: context,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.green100,
                  ),
                  headerHeight: 25,
                  cellHeight: 25,
                  data: [
                    ['Month', 'Sales'],
                    ...monthlySalesData.map(
                      (item) => [item['month'], '\$${item['sales']}'],
                    ),
                  ],
                ),

                // Crop Production
                pw.Header(level: 1, text: 'Crop Production'),
                pw.Paragraph(
                  text: 'Active Crops: ${cropsReport['active_crops'] ?? 0}',
                ),
                pw.Paragraph(
                  text:
                      'Crops Ready for Harvest: ${cropsReport['ready_for_harvest'] ?? 0}',
                ),

                // Recommendations
                pw.Header(level: 1, text: 'Recommendations'),
                pw.Bullet(
                  text:
                      'Focus on increasing customer engagement to boost order volume',
                ),
                pw.Bullet(
                  text:
                      'Investigate causes of failed transactions to improve conversion rate',
                ),
                pw.Bullet(
                  text:
                      'Consider expanding crop variety based on seasonal demands',
                ),

                // Disclaimer
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    'This report is generated for internal use only. The data presented here is based on the business activities recorded in our system during the specified period.',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
        ),
      );

      // Get temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/business_report.pdf');

      // Save PDF
      await file.writeAsBytes(await pdf.save());

      // Hide loading dialog
      Navigator.pop(context);

      // Show preview and share options
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'business_report.pdf',
      );
    } catch (e) {
      // Hide loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting to PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
    _showExportingDialog('Generating Excel file');

    try {
      // Create excel instance
      final excelFile = excel.Excel.createExcel();

      // Add Users Sheet
      final usersSheet = excelFile['Users'];
      usersSheet.appendRow(['Role', 'Count']);
      for (final item in (usersReport['data'] as List? ?? [])) {
        usersSheet.appendRow([item['role'], item['total']]);
      }

      // Add Orders Sheet
      final ordersSheet = excelFile['Orders'];
      ordersSheet.appendRow(['Status', 'Count']);
      for (final item in (ordersReport['data'] as List? ?? [])) {
        ordersSheet.appendRow([item['order_status'], item['total']]);
      }

      // Add Sales Sheet
      final salesSheet = excelFile['Sales'];
      salesSheet.appendRow(['Month', 'Sales']);
      for (final item in monthlySalesData) {
        salesSheet.appendRow([item['month'], item['sales']]);
      }

      // Add Summary Sheet
      final summarySheet = excelFile['Summary'];
      summarySheet.appendRow(['Metric', 'Value']);
      summarySheet.appendRow([
        'Total Users',
        usersReport['data']?.fold(0, (sum, item) => sum + item['total']) ?? 0,
      ]);
      summarySheet.appendRow([
        'Today\'s Orders',
        dailyOrdersReport['daily_orders'] ?? 0,
      ]);
      summarySheet.appendRow([
        'Total Sales',
        '\$${(transactionsReport['total_sales'] ?? 0).toStringAsFixed(2)}',
      ]);
      summarySheet.appendRow([
        'Active Crops',
        cropsReport['active_crops'] ?? 0,
      ]);

      // Get temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/business_report.xlsx');

      // Save Excel
      final encodedExcel = excelFile.save();
      if (encodedExcel != null) {
        await file.writeAsBytes(encodedExcel);
      } else {
        throw Exception('Failed to encode Excel file.');
      }

      // Hide loading dialog
      Navigator.pop(context);

      // Share file
      await Share.shareFiles(
        [file.path],
        text: 'Business Report',
        subject:
            'Business Analytics Report ${DateFormat.yMd().format(DateTime.now())}',
      );
    } catch (e) {
      // Hide loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting to Excel: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
                  subtitle: const Text(
                    'Complete report with charts and analysis',
                  ),
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
                  subtitle: const Text('Raw data in spreadsheet format'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportToExcel();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.share, color: Colors.blue),
                  ),
                  title: const Text('Share Summary'),
                  subtitle: const Text('Quick overview to share with team'),
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'Business Report Summary (${DateFormat.yMd().format(_dateRange.start)} - ${DateFormat.yMd().format(_dateRange.end)}):\n'
                      '- Total Users: ${usersReport['data']?.fold(0, (sum, item) => sum + item['total']) ?? 0}\n'
                      '- Today\'s Orders: ${dailyOrdersReport['daily_orders'] ?? 0}\n'
                      '- Total Sales: \$${(transactionsReport['total_sales'] ?? 0).toStringAsFixed(2)}\n'
                      '- Active Crops: ${cropsReport['active_crops'] ?? 0}',
                    );
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                      fontSize: 14,
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
    final pieChartData = data['data'] as List<Map<String, dynamic>>? ?? [];
    final total = pieChartData.fold<double>(
      0,
      (sum, item) => sum + (item.values.first as num).toDouble(),
    );

    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                          pieChartData.map((item) {
                            final value = (item.values.first as num).toDouble();
                            return PieChartSectionData(
                              color: _getColorForIndex(
                                pieChartData.indexOf(item),
                              ),
                              value: value,
                              title:
                                  '${(value / total * 100).toStringAsFixed(1)}%',
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
                      pieChartData.map((item) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: _getColorForIndex(
                                pieChartData.indexOf(item),
                              ),
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
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
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
    final barChartData = data['data'] as List<Map<String, dynamic>>? ?? [];

    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                          (barChartData.fold<double>(
                                0,
                                (max, item) =>
                                    (item.values.first as num).toDouble() > max
                                        ? (item.values.first as num).toDouble()
                                        : max,
                              ) *
                              1.2),
                      barGroups:
                          barChartData.map((item) {
                            return BarChartGroupData(
                              x: barChartData.indexOf(item),
                              barRods: [
                                BarChartRodData(
                                  toY: (item.values.first as num).toDouble(),
                                  color: _getColorForIndex(
                                    barChartData.indexOf(item),
                                  ),
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
                                  barChartData[value.toInt()].keys.first,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
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
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              );
                            },
                            interval: 1,
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, String title) {
    final spots =
        data.map((item) {
          return FlSpot(
            data.indexOf(item).toDouble(),
            (item['sales'] as num).toDouble(),
          );
        }).toList();

    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
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
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              );
                            },
                            interval: 1000,
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 1000.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildDataTable(
    List<Map<String, dynamic>> data,
    List<String> columns,
    String title,
  ) {
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
                headingRowColor: WidgetStateProperty.all(tertiaryColor),
                dataRowColor: WidgetStateProperty.all(Colors.white),
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
                    data
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
                  (transactionsReport['success_rate'] ?? 0) / 100,
                  Colors.green,
                ),
                _buildProgressIndicator(
                  'Pending Rate',
                  (transactionsReport['pending_rate'] ?? 0) / 100,
                  Colors.orange,
                ),
                _buildProgressIndicator(
                  'Failure Rate',
                  (transactionsReport['failure_rate'] ?? 0) / 100,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Total Sales: \$${(transactionsReport['total_sales'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Average Order Value: \$${(transactionsReport['avg_order_value'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
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
            'No data available for the selected period',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _selectDateRange(context);
            },
            icon: const Icon(Icons.date_range),
            label: const Text('Change Date Range'),
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
        children: [
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('All'),
            selected: _selectedReportType == 'All',
            onSelected: (selected) {
              setState(() {
                _selectedReportType = 'All';
              });
            },
            backgroundColor: Colors.grey[200],
            selectedColor: primaryColor.withOpacity(0.2),
            checkmarkColor: primaryColor,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Users'),
            selected: _selectedReportType == 'Users',
            onSelected: (selected) {
              setState(() {
                _selectedReportType = 'Users';
              });
            },
            backgroundColor: Colors.grey[200],
            selectedColor: primaryColor.withOpacity(0.2),
            checkmarkColor: primaryColor,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Orders'),
            selected: _selectedReportType == 'Orders',
            onSelected: (selected) {
              setState(() {
                _selectedReportType = 'Orders';
              });
            },
            backgroundColor: Colors.grey[200],
            selectedColor: primaryColor.withOpacity(0.2),
            checkmarkColor: primaryColor,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Sales'),
            selected: _selectedReportType == 'Sales',
            onSelected: (selected) {
              setState(() {
                _selectedReportType = 'Sales';
              });
            },
            backgroundColor: Colors.grey[200],
            selectedColor: primaryColor.withOpacity(0.2),
            checkmarkColor: primaryColor,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Crops'),
            selected: _selectedReportType == 'Crops',
            onSelected: (selected) {
              setState(() {
                _selectedReportType = 'Crops';
              });
            },
            backgroundColor: Colors.grey[200],
            selectedColor: primaryColor.withOpacity(0.2),
            checkmarkColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    if (_selectedReportType == 'Users') {
      return Column(
        children: [
          _buildPieChart({
            'data':
                usersReport['data']
                    ?.map((item) => {item['role']: item['total']})
                    .toList() ??
                [],
          }, 'Users by Role'),
          const SizedBox(height: 16),
          _buildDataTable(
            (usersReport['data'] as List? ?? [])
                .map(
                  (item) => {
                    'Role': item['role'],
                    'Count': item['total'].toString(),
                    'Percentage':
                        '${((item['total'] / (usersReport['data'] as List).fold<int>(0, (sum, i) => sum + (i['total'] as int))) * 100).toStringAsFixed(1)}%',
                  },
                )
                .toList(),
            ['Role', 'Count', 'Percentage'],
            'User Distribution',
          ),
        ],
      );
    } else if (_selectedReportType == 'Orders') {
      return Column(
        children: [
          _buildBarChart({
            'data':
                ordersReport['data']
                    ?.map((item) => {item['order_status']: item['total']})
                    .toList() ??
                [],
          }, 'Orders by Status'),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Daily Order Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 24),
                              FlSpot(1, 18),
                              FlSpot(2, 27),
                              FlSpot(3, 21),
                              FlSpot(4, 30),
                              FlSpot(5, 35),
                              FlSpot(6, 25),
                            ],
                            isCurved: true,
                            color: accentColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    days[value.toInt()],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
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
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                );
                              },
                              interval: 10,
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),
        ],
      );
    } else if (_selectedReportType == 'Sales') {
      return Column(
        children: [
          _buildTransactionsWidget(),
          const SizedBox(height: 16),
          _buildLineChart(monthlySalesData, 'Monthly Sales Trend'),
        ],
      );
    } else if (_selectedReportType == 'Crops') {
      return Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
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
              _buildSummaryCard(
                'Unique Crop Types',
                cropsReport['unique_crop_types'] ?? 0,
                Icons.category,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPieChart({
            'data': [
              {'crop': 'Tomatoes', 'count': 120},
              {'crop': 'Potatoes', 'count': 80},
              {'crop': 'Carrots', 'count': 60},
              {'crop': 'Lettuce', 'count': 40},
              {'crop': 'Onions', 'count': 30},
              {'crop': 'Others', 'count': 50},
            ],
          }, 'Crop Distribution'),
        ],
      );
    } else {
      // All or default view
      return Column(
        children: [
          // Summary Cards
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
                usersReport['data']?.fold(
                      0,
                      (sum, item) => sum + item['total'],
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
              _buildSummaryCard(
                'Active Crops',
                cropsReport['active_crops'] ?? 0,
                Icons.eco,
                Colors.green,
              ),
              _buildSummaryCard(
                'Avg Order Value',
                '\$${(transactionsReport['avg_order_value'] ?? 0).toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.purple,
              ),
              _buildSummaryCard(
                'Completed Orders',
                ordersReport['data']?.firstWhere(
                      (item) => item['order_status'] == 'Completed',
                      orElse: () => {'total': 0},
                    )['total'] ??
                    0,
                Icons.check_circle,
                Colors.teal,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Key charts
          _buildLineChart(monthlySalesData, 'Monthly Sales Trend'),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPieChart({
                  'data':
                      usersReport['data']
                          ?.map((item) => {item['role']: item['total']})
                          .toList() ??
                      [],
                }, 'Users by Role'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBarChart({
                  'data':
                      ordersReport['data']
                          ?.map((item) => {item['order_status']: item['total']})
                          .toList() ??
                      [],
                }, 'Orders by Status'),
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
        SizedBox(
          height:
              MediaQuery.of(context).size.height -
              220, // Adjust height based on screen size
          child: TabBarView(
            controller: _tabController,
            children: [
              // Overview Tab
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Summary Cards
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
                          usersReport['data']?.fold(
                                0,
                                (sum, item) => sum + item['total'],
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
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildLineChart(monthlySalesData, 'Monthly Sales Trend'),
                  ],
                ),
              ),

              // Users Tab
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPieChart({
                      'data':
                          usersReport['data']
                              ?.map((item) => {item['role']: item['total']})
                              .toList() ??
                          [],
                    }, 'Users by Role'),
                    const SizedBox(height: 16),
                    _buildDataTable(
                      (usersReport['data'] as List? ?? [])
                          .map(
                            (item) => {
                              'Role': item['role'],
                              'Count': item['total'].toString(),
                              'Percentage':
                                  '${((item['total'] / (usersReport['data'] as List).fold<int>(0, (sum, i) => sum + (i['total'] as int))) * 100).toStringAsFixed(1)}%',
                            },
                          )
                          .toList(),
                      ['Role', 'Count', 'Percentage'],
                      'User Distribution',
                    ),
                  ],
                ),
              ),

              // Orders Tab
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBarChart({
                      'data':
                          ordersReport['data']
                              ?.map(
                                (item) => {item['order_status']: item['total']},
                              )
                              .toList() ??
                          [],
                    }, 'Orders by Status'),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Daily Order Trend',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        FlSpot(0, 24),
                                        FlSpot(1, 18),
                                        FlSpot(2, 27),
                                        FlSpot(3, 21),
                                        FlSpot(4, 30),
                                        FlSpot(5, 35),
                                        FlSpot(6, 25),
                                      ],
                                      isCurved: true,
                                      color: accentColor,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: true),
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final days = [
                                            'Mon',
                                            'Tue',
                                            'Wed',
                                            'Thu',
                                            'Fri',
                                            'Sat',
                                            'Sun',
                                          ];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              days[value.toInt()],
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black,
                                              ),
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
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black,
                                            ),
                                          );
                                        },
                                        interval: 10,
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: true),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sales Tab
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTransactionsWidget(),
                    const SizedBox(height: 16),
                    _buildLineChart(monthlySalesData, 'Monthly Sales Trend'),
                  ],
                ),
              ),

              // Crops Tab
              SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 3 : 2,
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
                        _buildSummaryCard(
                          'Unique Crop Types',
                          cropsReport['unique_crop_types'] ?? 0,
                          Icons.category,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPieChart({
                      'data': [
                        {'crop': 'Tomatoes', 'count': 120},
                        {'crop': 'Potatoes', 'count': 80},
                        {'crop': 'Carrots', 'count': 60},
                        {'crop': 'Lettuce', 'count': 40},
                        {'crop': 'Onions', 'count': 30},
                        {'crop': 'Others', 'count': 50},
                      ],
                    }, 'Crop Distribution'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _showExportOptions,
            tooltip: 'Export Reports',
          ),
          IconButton(
            icon: Icon(_isRefreshing ? Icons.sync : Icons.refresh),
            onPressed: () {
              setState(() => _isRefreshing = true);
              _fetchAllReports();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading reports...',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchAllReports,
                color: primaryColor,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, tertiaryColor.withOpacity(0.3)],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with date range
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 0,
                                color: tertiaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${DateFormat.yMMMd().format(_dateRange.start)} - ${DateFormat.yMMMd().format(_dateRange.end)}',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(),

                        const SizedBox(height: 16),

                        // Use tabs for tablets and above, filter chips for mobile
                        isTablet ? _buildTabsView() : _buildFilterChips(),

                        if (!isTablet) const SizedBox(height: 16),

                        // Report content based on filter for mobile
                        if (!isTablet) _buildReportContent(),
                      ],
                    ),
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExportOptions,
        backgroundColor: primaryColor,
        child: const Icon(Icons.save_alt),
      ),
    );
  }
}
