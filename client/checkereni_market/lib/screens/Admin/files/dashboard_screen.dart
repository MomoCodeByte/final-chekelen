import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart'; // For animations
import 'package:intl/intl.dart'; // For number formatting

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Sample data - replace with API data
  final List<Map<String, dynamic>> _recentOrders = [
    {
      'id': '#4832',
      'customer': 'Alice Chen',
      'status': 'Delivered',
      'amount': 235.00,
    },
    {
      'id': '#4831',
      'customer': 'Bob Smith',
      'status': 'Processing',
      'amount': 178.50,
    },
    {
      'id': '#4830',
      'customer': 'Carol Davis',
      'status': 'Pending',
      'amount': 320.75,
    },
  ];

  final List<Map<String, dynamic>> _cropTrends = [
    {'name': 'Corn', 'growth': 23, 'color': Colors.amber},
    {'name': 'Wheat', 'growth': 15, 'color': Colors.orange[300]},
    {'name': 'Soybeans', 'growth': 28, 'color': Colors.green[300]},
    {'name': 'Rice', 'growth': 10, 'color': Colors.blueGrey},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    final primaryGreen = const Color(0xFF2E7D32);
    final lightGreen = const Color(0xFF81C784);
    final backgroundColor = Colors.white;
    final accentColor = const Color(0xFF7C4DFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Dashboard Header with Date
              FadeIn(
                duration: const Duration(milliseconds: 800),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy',
                          ).format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: primaryGreen,
                      radius: 24,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Stats Row
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 800),
                child: Row(
                  children: [
                    _buildAnimatedStatCard(
                      'Total Users',
                      '1,568',
                      Icons.people,
                      primaryGreen,
                      delay: 100,
                    ),
                    const SizedBox(width: 16),
                    _buildAnimatedStatCard(
                      'Active Users',
                      '892',
                      Icons.person_outline,
                      lightGreen,
                      delay: 200,
                    ),
                    const SizedBox(width: 16),
                    _buildAnimatedStatCard(
                      'New Orders',
                      '45',
                      Icons.shopping_bag,
                      accentColor,
                      delay: 300,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Main content area
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Chart Section
                          FadeInLeft(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              height: 280,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Budget Allocation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: SlideInUp(
                                      duration: const Duration(
                                        milliseconds: 1000,
                                      ),
                                      child: PieChart(
                                        PieChartData(
                                          pieTouchData: PieTouchData(
                                            touchCallback: (event, response) {
                                              // API: Handle touch events for detailed view
                                            },
                                          ),
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 40,
                                          sections: [
                                            PieChartSectionData(
                                              value: 40,
                                              title: '40%',
                                              radius: 60,
                                              color: primaryGreen,
                                              titleStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            PieChartSectionData(
                                              value: 30,
                                              title: '30%',
                                              radius: 60,
                                              color: accentColor.withOpacity(
                                                0.8,
                                              ),
                                              titleStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            PieChartSectionData(
                                              value: 15,
                                              title: '15%',
                                              radius: 60,
                                              color: lightGreen,
                                              titleStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            PieChartSectionData(
                                              value: 15,
                                              title: '15%',
                                              radius: 60,
                                              color: Colors.amber,
                                              titleStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Legend
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem('Sales', primaryGreen),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(
                                        'Marketing',
                                        accentColor.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(
                                        'Development',
                                        lightGreen,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(
                                        'Operations',
                                        Colors.amber,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Crop Trends
                          FadeInUp(
                            delay: const Duration(milliseconds: 500),
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Crop Growth Trends',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // API: Replace with dynamic data from API
                                  ..._cropTrends
                                      .map((crop) => _buildCropTrendItem(crop))
                                      .toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Right Column
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Weather Widget
                          FadeInRight(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [primaryGreen, lightGreen],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Weather',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Icon(
                                        Icons.wb_sunny,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // API: Replace with dynamic weather data
                                  const Text(
                                    '72°F',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Sunny',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildWeatherItem(
                                        'Humidity',
                                        '65%',
                                        Icons.water_drop_outlined,
                                      ),
                                      _buildWeatherItem(
                                        'Wind',
                                        '8 mph',
                                        Icons.air,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Recent Orders
                          FadeInRight(
                            delay: const Duration(milliseconds: 500),
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recent Orders',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // API: Navigate to detailed orders view
                                        },
                                        child: Text(
                                          'View All',
                                          style: TextStyle(color: accentColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // API: Replace with dynamic order data
                                  ..._recentOrders
                                      .map(
                                        (order) => _buildOrderItem(
                                          order,
                                          primaryGreen,
                                        ),
                                      )
                                      .toList(),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Task Completion
                          FadeInUp(
                            delay: const Duration(milliseconds: 600),
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Task Completion',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // API: Replace with dynamic task data
                                  _buildProgressBar(
                                    'Daily Goals',
                                    0.75,
                                    primaryGreen,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildProgressBar(
                                    'Weekly Tasks',
                                    0.6,
                                    lightGreen,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildProgressBar(
                                    'Monthly Targets',
                                    0.4,
                                    accentColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: BottomNavigationBar(
            selectedItemColor: primaryGreen,
            unselectedItemColor: Colors.grey[500],
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: 0,
            onTap: (index) {
              // API: Handle navigation
            },
          ),
          //
        ),
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    int delay = 0,
  }) {
    return Expanded(
      child: SlideInUp(
        delay: Duration(milliseconds: delay),
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            color: color,
                            size: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCropTrendItem(Map<String, dynamic> crop) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              crop['name'],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '${crop['growth']}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: crop['color'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: crop['growth'] / 100),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[200],
                color: crop['color'],
                minHeight: 8,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildWeatherItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order, Color primaryColor) {
    Color statusColor;
    switch (order['status']) {
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'Processing':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(Icons.receipt, color: primaryColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['customer'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  order['id'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${order['amount'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order['status'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    final percentage = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[200],
                color: color,
                minHeight: 8,
              ),
            );
          },
        ),
      ],
    );
  }
}
