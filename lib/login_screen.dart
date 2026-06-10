import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'screens/auth_options_screen.dart';

class LVLRISELoginScreen extends StatefulWidget {
  const LVLRISELoginScreen({super.key});

  @override
  State<LVLRISELoginScreen> createState() => _LVLRISELoginScreenState();
}

class _LVLRISELoginScreenState extends State<LVLRISELoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen Image Background ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/levelrise-hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),

          // ── Dark overlay for readability at bottom ────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0B1F17).withValues(alpha: 0.4),
                    const Color(0xFF0F2B1F),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Grid Lines ──────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                lineColor: AppColors.gridLine,
                spacing: 44.0,
                thickness: 1.1,
              ),
            ),
          ),

          // ── Glow Blobs ────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(
              radius: 280,
              colors: const [
                Color(0xFF2AE8A0),
                Color(0xFF134D42),
              ],
            ),
          ),
          Positioned(
            top: 320,
            right: -100,
            child: _GlowBlob(
              radius: 250,
              colors: const [
                Color(0xFF1CCBFF),
                Color(0xFF0D2A35),
              ],
            ),
          ),
          Positioned(
            bottom: 220,
            left: -80,
            child: _GlowBlob(
              radius: 300,
              colors: const [
                Color(0xFF6CFFB4),
                Color(0xFF0E3A28),
              ],
            ),
          ),

          // ── Content: Text + Buttons at bottom ────
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LevelRise + Tagline
                    Text(
                      'LevelRise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Rise Strong. Play Hard.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Login (White Pill)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AuthOptionsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          foregroundColor: const Color(0xFF0A2A1D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 6,
                          shadowColor: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A2A1D),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Create an Account (Glass Pill)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AuthOptionsScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.loginCardGlass,
                          side: const BorderSide(
                            color: AppColors.loginCardStroke,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Create an Account',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.lineColor,
    required this.spacing,
    required this.thickness,
  });

  final Color lineColor;
  final double spacing;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.thickness != thickness;
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.radius, required this.colors});

  final double radius;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.first.withValues(alpha: 0.3),
            colors.last.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
