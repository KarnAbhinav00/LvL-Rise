import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class RunTrackerScreen extends StatefulWidget {
  const RunTrackerScreen({super.key});

  @override
  State<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends State<RunTrackerScreen> {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

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
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _accelStream?.cancel();
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
            // Mock run simulation: 1.5m to 2.5m per second (approx 5-9 km/h)
            final double stepDistance = (1.5 + (0.5 * (_secondsElapsed % 3))) / 1000.0;
            _distanceKm += stepDistance;
            
            // Pace calculation: (minutes / distance)
            final minutesElapsed = _secondsElapsed / 60.0;
            _paceMinPerKm = _distanceKm > 0 ? (minutesElapsed / _distanceKm) : 0.0;

            // Calories burn estimation
            _caloriesBurned = (_distanceKm * 65).round();

            // Mock sensor activity: add normal walking/running swings
            _accelReadings.add(9.8 + (_secondsElapsed % 2));
            if (_accelReadings.length > 50) _accelReadings.removeAt(0);
          } else {
            // Real GPS calculations
            final minutesElapsed = _secondsElapsed / 60.0;
            _paceMinPerKm = _distanceKm > 0 ? (minutesElapsed / _distanceKm) : 0.0;
            _caloriesBurned = (_distanceKm * 65).round();
          }
        });
      }
    });

    if (!_isSimulationMode) {
      // 1. Geolocator permissions & streams
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
              ) / 1000.0; // convert to km

              // Anti-Cheat Speed Check (detect impossible speed, e.g., in a car or teleporting)
              final double timeDeltaSeconds =
                  (position.timestamp.difference(_lastPosition!.timestamp)).inSeconds.toDouble();

              if (timeDeltaSeconds > 0) {
                final double currentSpeedKmh = (distanceDelta / (timeDeltaSeconds / 3600.0));
                
                if (currentSpeedKmh > _maxSpeedRecorded) {
                  _maxSpeedRecorded = currentSpeedKmh;
                }

                // If running speed > 35 km/h (Bolt is 44km/h max, average runner is 10-15km/h)
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

      // 2. Sensors_plus accelerometer listener for physical activity check
      _accelStream = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
        if (_isPaused) return;

        // Calculate magnitude of acceleration
        final double magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
        _accelReadings.add(magnitude);
        if (_accelReadings.length > 50) _accelReadings.removeAt(0);

        // Anti-Cheat: check if device is stationary but GPS moves (mock GPS hack)
        if (_distanceKm > 0.05 && _accelReadings.isNotEmpty) {
          final double avgMagnitude =
              _accelReadings.reduce((a, b) => a + b) / _accelReadings.length;
          
          // A running/walking person always causes accelerometer fluctuation (avg magnitude > 0.5)
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

    final xpEarned = (_distanceKm * 150).round(); // 150 XP per km
    final goldEarned = (_distanceKm * 100).round(); // 100 GOLD per km

    if (_distanceKm > 0.1 && _user != null) {
      // Save workout
      await _firestore.saveWorkout(
        uid: _user.uid,
        type: 'Run',
        metricValue: _distanceKm,
        durationMinutes: _secondsElapsed ~/ 60,
        xpEarned: xpEarned,
        goldEarned: goldEarned,
      );

      // Trigger potential monster encounter if verified
      if (!_isCheatingDetected && _distanceKm > 0.5) {
        _triggerMonsterEncounter();
      }
    }

    setState(() {
      _isTracking = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Run saved! Completed ${_distanceKm.toStringAsFixed(2)} km. Earned $xpEarned XP & $goldEarned GOLD!',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _triggerMonsterEncounter() {
    // Navigate or show bottom sheet for catching a monster
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Random monster generation
        final elements = ['Fire', 'Water', 'Wind', 'Electric', 'Nature'];
        final element = (elements..shuffle()).first;
        final monsterId = 'mon_${DateTime.now().millisecondsSinceEpoch % 50}';
        final monsterName = '$element Guardian';

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Color(0xFF0F121F),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.catching_pokemon,
                size: 64,
                color: AppColors.secondary,
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
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text(
                  'CATCH MONSTER (100% Success)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
          padding: const EdgeInsets.all(24.0),
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
              const SizedBox(height: 20),

              // ── Anti-Cheat Status HUD ───────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: _isCheatingDetected
                      ? Colors.red.withValues(alpha: 0.15)
                      : AppColors.surface,
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

              const Spacer(),

              // ── Primary Timer display ──────────────────────
              Text(
                _formatDuration(_secondsElapsed),
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ELAPSED TIME',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              // ── Metrics Grid ──────────────────────────────
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
                  const SizedBox(width: 16),
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
              const SizedBox(height: 16),
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
                  const SizedBox(width: 16),
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
                    ElevatedButton(
                      onPressed: _startRun,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'START RUN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Pause/Resume button
                    GestureDetector(
                      onTap: _pauseResumeRun,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPaused ? AppColors.secondary : AppColors.surface,
                          border: Border.all(
                            color: _isPaused ? AppColors.secondary : Colors.white12,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          size: 32,
                          color: _isPaused ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Stop button
                    GestureDetector(
                      onTap: _stopRun,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
