import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

// ── Glowing Border Painter for Run Screen ──────────────────────────────────
class _RunGlowBorderPainter extends CustomPainter {
  final Color color;
  final double intensity;

  _RunGlowBorderPainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(rect, glowPaint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.35 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RunGlowBorderPainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.color != color;
}

class RunTrackerScreen extends StatefulWidget {
  const RunTrackerScreen({super.key});

  @override
  State<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends State<RunTrackerScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  late AnimationController _pulseController;

  // Running State variables
  bool _isTracking = false;
  bool _isPaused = false;
  int _secondsElapsed = 0;
  double _distanceKm = 0.0;
  double _paceMinPerKm = 0.0;
  int _caloriesBurned = 0;

  // Streams & Timers
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<UserAccelerometerEvent>? _accelStream;

  // Anti-Cheat Telemetry
  int _trustScore = 100;
  String _verificationStatus = '✓ Verified';
  double _maxSpeedRecorded = 0.0;
  final List<double> _accelReadings = [];
  bool _isCheatingDetected = false;

  // Simulation mode toggle
  bool _isSimulationMode = false;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _accelStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Helper to format duration to HH:MM:SS
  String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Starts run tracking
  Future<void> _startRun() async {
    setState(() {
      _isTracking = true;
      _isPaused = false;
      _secondsElapsed = 0;
      _distanceKm = 0.0;
      _paceMinPerKm = 0.0;
      _caloriesBurned = 0;
      _trustScore = 100;
      _verificationStatus = '✓ Verified';
      _isCheatingDetected = false;
      _accelReadings.clear();
      _maxSpeedRecorded = 0.0;
      _lastPosition = null;
    });

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _secondsElapsed++;
          
          if (_isSimulationMode) {
            final double stepDistance = (1.5 + (0.5 * (_secondsElapsed % 3))) / 1000.0;
            _distanceKm += stepDistance;
            
            final minutesElapsed = _secondsElapsed / 60.0;
            _paceMinPerKm = _distanceKm > 0 ? (minutesElapsed / _distanceKm) : 0.0;
            _caloriesBurned = (_distanceKm * 65).round();

            _accelReadings.add(9.8 + (_secondsElapsed % 2));
            if (_accelReadings.length > 50) _accelReadings.removeAt(0);
          } else {
            final minutesElapsed = _secondsElapsed / 60.0;
            _paceMinPerKm = _distanceKm > 0 ? (minutesElapsed / _distanceKm) : 0.0;
            _caloriesBurned = (_distanceKm * 65).round();
          }
        });
      }
    });

    if (!_isSimulationMode) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          if (_isPaused) return;

          setState(() {
            if (_lastPosition != null) {
              final double distanceDelta = Geolocator.distanceBetween(
                _lastPosition!.latitude,
                _lastPosition!.longitude,
                position.latitude,
                position.longitude,
              ) / 1000.0;

              final double timeDeltaSeconds =
                  (position.timestamp.difference(_lastPosition!.timestamp)).inSeconds.toDouble();

              if (timeDeltaSeconds > 0) {
                final double currentSpeedKmh = (distanceDelta / (timeDeltaSeconds / 3600.0));
                
                if (currentSpeedKmh > _maxSpeedRecorded) {
                  _maxSpeedRecorded = currentSpeedKmh;
                }

                if (currentSpeedKmh > 35.0) {
                  _flagCheating('Impossible Speed: ${currentSpeedKmh.toStringAsFixed(1)} km/h');
                }
              }

              _distanceKm += distanceDelta;
            }
            _lastPosition = position;
          });
        });
      }

      _accelStream = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
        if (_isPaused) return;

        final double magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
        _accelReadings.add(magnitude);
        if (_accelReadings.length > 50) _accelReadings.removeAt(0);

        if (_distanceKm > 0.05 && _accelReadings.isNotEmpty) {
          final double avgMagnitude =
              _accelReadings.reduce((a, b) => a + b) / _accelReadings.length;
          
          if (avgMagnitude < 0.08 && _secondsElapsed > 15) {
            _flagCheating('No physical movement detected (Mock GPS)');
          }
        }
      });
    }
  }

  void _flagCheating(String reason) {
    if (_isCheatingDetected) return;
    setState(() {
      _isCheatingDetected = true;
      _trustScore = (_trustScore - 40).clamp(0, 100);
      _verificationStatus = '⚠️ Reviewing: $reason';
    });
  }

  void _pauseResumeRun() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _stopRun() async {
    _timer?.cancel();
    _positionStream?.cancel();
    _accelStream?.cancel();

    final xpEarned = (_distanceKm * 150).round();
    final goldEarned = (_distanceKm * 100).round();

    if (_distanceKm > 0.1 && _user != null) {
      await _firestore.saveWorkout(
        uid: _user.uid,
        type: 'Run',
        metricValue: _distanceKm,
        durationMinutes: _secondsElapsed ~/ 60,
        xpEarned: xpEarned,
        goldEarned: goldEarned,
      );

      if (!_isCheatingDetected && _distanceKm > 0.5) {
        _triggerMonsterEncounter();
      }
    }

    setState(() {
      _isTracking = false;
    });

    if (mounted) {
      _showSuccessOverlay(_distanceKm, xpEarned, goldEarned);
    }
  }

  String _getMonsterAsset(String element) {
    switch (element) {
      case 'Fire':
        return 'assets/monsters/fire_guardian.png';
      case 'Water':
        return 'assets/monsters/ice_guardian.png';
      case 'Wind':
        return 'assets/monsters/shadow_guardian.png';
      case 'Electric':
        return 'assets/monsters/thunder_guardian.png';
      case 'Nature':
        return 'assets/monsters/nature_guardian.png';
      default:
        return 'assets/monsters/fire_guardian.png';
    }
  }

  Color _getElementColor(String element) {
    switch (element) {
      case 'Fire':
        return Colors.redAccent;
      case 'Water':
        return AppColors.secondary;
      case 'Wind':
        return Colors.greenAccent;
      case 'Electric':
        return Colors.amber;
      case 'Nature':
        return const Color(0xFF50C878);
      default:
        return Colors.white;
    }
  }

  void _triggerMonsterEncounter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final elements = ['Fire', 'Water', 'Wind', 'Electric', 'Nature'];
        final element = (elements..shuffle()).first;
        final monsterId = 'mon_${DateTime.now().millisecondsSinceEpoch % 50}';
        final monsterName = '$element Guardian';
        final elementColor = _getElementColor(element);
        final monsterAsset = _getMonsterAsset(element);

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F121F).withValues(alpha: 0.95),
                    const Color(0xFF090A12).withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(
                  color: elementColor.withValues(alpha: 0.25),
                  width: 1,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: elementColor.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: elementColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipOval(
                      child: Image.asset(
                        monsterAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.pets_rounded,
                          color: elementColor,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MONSTER ENCOUNTER!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A wild $monsterName appeared because of your hard work!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_user != null) {
                        await _firestore.addMonsterToCollection(_user.uid, monsterId);
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Caught $monsterName! Added to collection.'),
                          backgroundColor: const Color(0xFF50C878),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: elementColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.black),
                    label: const Text(
                      'CATCH MONSTER (100% Success)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // ── Header & Simulation Toggle ──────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GPS Tracker',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Simulate',
                        style: TextStyle(
                          color: _isSimulationMode ? AppColors.secondary : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Switch(
                        value: _isSimulationMode,
                        activeTrackColor: AppColors.secondary,
                        onChanged: _isTracking
                            ? null
                            : (val) {
                                setState(() {
                                  _isSimulationMode = val;
                                });
                              },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Anti-Cheat Status HUD (Glassmorphic) ───────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _isCheatingDetected
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.01),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isCheatingDetected
                            ? Colors.redAccent.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Anti-Cheat Status:',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _verificationStatus,
                          style: TextStyle(
                            color: _isCheatingDetected ? Colors.redAccent : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),
              // ── Running Lottie Animation Card (Glowing Circular Ring) ─────
              Center(
                child: CustomPaint(
                  foregroundPainter: _RunGlowBorderPainter(
                    color: _isTracking
                        ? (_isPaused ? AppColors.secondary : AppColors.primary)
                        : Colors.white24,
                    intensity: _isTracking ? (0.8 + (_pulseController.value * 0.2)) : 0.5,
                  ),
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    child: ClipOval(
                      child: _buildRunningLottie(),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // ── Primary Timer display ──────────────────────
              Text(
                _formatDuration(_secondsElapsed),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ELAPSED TIME',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const Spacer(),

              // ── Metrics Grid (Glassmorphic) ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'DISTANCE',
                      value: '${_distanceKm.toStringAsFixed(2)} km',
                      icon: Icons.directions_run_rounded,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'PACE',
                      value: _paceMinPerKm == 0.0
                          ? '0:00 /km'
                          : '${_paceMinPerKm.toInt()}:${((_paceMinPerKm % 1) * 60).toInt().toString().padLeft(2, '0')} /km',
                      icon: Icons.speed_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'CALORIES',
                      value: '$_caloriesBurned kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'TRUST SCORE',
                      value: '$_trustScore / 100',
                      icon: Icons.shield_rounded,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Control Buttons ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isTracking)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.2 + (_pulseController.value * 0.15),
                                ),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: ElevatedButton(
                        onPressed: _startRun,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'START RUN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Pause/Resume button
                    GestureDetector(
                      onTap: _pauseResumeRun,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPaused ? AppColors.secondary : AppColors.surface,
                          border: Border.all(
                            color: _isPaused ? AppColors.secondary : Colors.white12,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          size: 28,
                          color: _isPaused ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Stop button
                    GestureDetector(
                      onTap: _stopRun,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunningLottie() {
    if (!_isTracking) {
      return const Center(
        child: Icon(
          Icons.directions_run_rounded,
          size: 64,
          color: Colors.white10,
        ),
      );
    }

    String url = _isPaused
        ? 'https://lottie.host/802613d9-a78d-4a11-8977-628d098e91e5/q3eZz5x7wQ.json'
        : 'https://lottie.host/e6629d89-9eb1-4322-95f2-959c9973273e/o7H1WwVeaF.json';

    return Lottie.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            _isPaused ? Icons.pause_circle_filled_rounded : Icons.directions_run_rounded,
            size: 64,
            color: _isPaused ? AppColors.secondary : AppColors.primaryLight,
          ),
        );
      },
    );
  }

  void _showSuccessOverlay(double distance, int xp, int gold) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F121F).withValues(alpha: 0.95),
                      const Color(0xFF1B1D30).withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Lottie.network(
                        'https://lottie.host/f7f1837f-5dc9-478b-9442-7cf3f8373b96/T5dZg7j3w3.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'RUN COMPLETED!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Distance: ${distance.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+$xp XP   •   +$gold GOLD',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
