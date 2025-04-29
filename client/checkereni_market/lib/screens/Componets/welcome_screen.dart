import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../Clients/product_list.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.75);

    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.85);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.65);
    var secondEndPoint = Offset(size.width, size.height * 0.75);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class PlantIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PlantIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: PlantPainter(color: color),
    );
  }
}

class PlantPainter extends CustomPainter {
  final Color color;

  PlantPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final stemPath =
        Path()
          ..moveTo(size.width / 2, size.height)
          ..lineTo(size.width / 2, size.height * 0.4);

    // Left leaf
    final leftLeafPath =
        Path()
          ..moveTo(size.width / 2, size.height * 0.7)
          ..quadraticBezierTo(
            size.width * 0.25,
            size.height * 0.6,
            size.width * 0.2,
            size.height * 0.7,
          );

    // Right leaf
    final rightLeafPath =
        Path()
          ..moveTo(size.width / 2, size.height * 0.55)
          ..quadraticBezierTo(
            size.width * 0.75,
            size.height * 0.45,
            size.width * 0.8,
            size.height * 0.55,
          );

    // Top leaf
    final topLeafPath =
        Path()
          ..moveTo(size.width / 2, size.height * 0.4)
          ..quadraticBezierTo(
            size.width * 0.4,
            size.height * 0.2,
            size.width * 0.5,
            size.height * 0.15,
          )
          ..quadraticBezierTo(
            size.width * 0.6,
            size.height * 0.2,
            size.width / 2,
            size.height * 0.4,
          );

    canvas.drawPath(stemPath, paint);
    canvas.drawPath(leftLeafPath, paint);
    canvas.drawPath(rightLeafPath, paint);
    canvas.drawPath(topLeafPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BouncingPlant extends StatefulWidget {
  final double size;

  const BouncingPlant({super.key, required this.size});

  @override
  _BouncingPlantState createState() => _BouncingPlantState();
}

class _BouncingPlantState extends State<BouncingPlant>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: PlantIcon(size: widget.size, color: Colors.green.shade100),
        );
      },
    );
  }
}

class RotatingFruit extends StatefulWidget {
  final double size;
  final Color color;

  const RotatingFruit({super.key, required this.size, required this.color});

  @override
  _RotatingFruitState createState() => _RotatingFruitState();
}

class _RotatingFruitState extends State<RotatingFruit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background with wave pattern
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade800, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Decorative elements
          Positioned(
            top: size.height * 0.1,
            right: size.width * 0.1,
            child: RotatingFruit(
              size: 24,
              color: Colors.grey.shade300.withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: size.width * 0.1,
            child: RotatingFruit(
              size: 32,
              color: Colors.white60.withOpacity(0.5),
            ),
          ),
          Positioned(
            top: size.height * 0.2,
            left: size.width * 0.15,
            child: BouncingPlant(size: 60),
          ),
          Positioned(
            bottom: size.height * 0.25,
            right: size.width * 0.15,
            child: BouncingPlant(size: 70),
          ),

          // Content
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: PlantIcon(
                            size: 60,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      SizedBox(height: 40),

                      // Title
                      Text(
                        "Karibu Chekereni Market",
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.grey.shade800,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),

                      // Subtitle
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        // decoration: BoxDecoration(
                        //   color: Colors.green.withOpacity(0.1),
                        //   // borderRadius: BorderRadius.circular(20),
                        // ),
                        child: Text(
                          "Soko la Mazao ya Msimu",
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            shadows: [
                              Shadow(
                                color: Colors.grey.shade800,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 60),

                      // Button
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 0,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>ProductListScreen(),
                                transitionsBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  var begin = Offset(1.0, 0.0);
                                  var end = Offset.zero;
                                  var curve = Curves.easeInOut;
                                  var tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Get Started",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
