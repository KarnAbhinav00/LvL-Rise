import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

// ── Glowing Border Painter for Workout Cards ───────────────────────────────
class _WorkoutGlowBorderPainter extends CustomPainter {
  final Color color;
  final double intensity;

  _WorkoutGlowBorderPainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );

    // Glow shadow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(rect, glowPaint);

    // Crisp border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.35 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WorkoutGlowBorderPainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.color != color;
}

class WorkoutLoggerScreen extends StatefulWidget {
  const WorkoutLoggerScreen({super.key});

  @override
  State<WorkoutLoggerScreen> createState() => _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends State<WorkoutLoggerScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  late AnimationController _pulseController;

  // Form selections
  String _selectedExercise = 'Squat';
  String _selectedMuscleGroup = 'Quads/Glutes';
  String _difficulty = 'Medium';
  int _durationMinutes = 30;

  // Sets details
  final List<Map<String, int>> _sets = [
    {'reps': 10, 'weight': 60},
  ];

  final List<String> _exercises = [
    'Squat',
    'Bench Press',
    'Deadlift',
    'Pull-up',
    'Push-up',
    'Overhead Press',
    'Dumbbell Bicep Curl',
    'Tricep Dips',
  ];

  final List<String> _muscleGroups = [
    'Quads/Glutes',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Core',
    'Full Body',
  ];

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
    _pulseController.dispose();
    super.dispose();
  }

  void _addSet() {
    setState(() {
      _sets.add({
        'reps': _sets.last['reps'] ?? 10,
        'weight': _sets.last['weight'] ?? 60,
      });
    });
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_user == null) return;

    double totalVolume = 0;
    for (var set in _sets) {
      totalVolume += (set['reps']! * set['weight']!);
    }

    final diffMultiplier = _difficulty == 'Easy' ? 1.0 : _difficulty == 'Medium' ? 1.2 : 1.5;
    final xpEarned = ((totalVolume / 10.0) * diffMultiplier).round().clamp(50, 500);
    final goldEarned = ((totalVolume / 20.0) * diffMultiplier).round().clamp(30, 300);

    await _firestore.saveWorkout(
      uid: _user.uid,
      type: 'Strength: $_selectedExercise',
      metricValue: _sets.length.toDouble(), // sets count
      durationMinutes: _durationMinutes,
      xpEarned: xpEarned,
      goldEarned: goldEarned,
    );

    if (mounted) {
      _showSuccessOverlay(xpEarned, goldEarned);
      // Reset input
      setState(() {
        _sets.clear();
        _sets.add({'reps': 10, 'weight': 60});
        _durationMinutes = 30;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log Strength Workout',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // ── Dynamic Exercise Lottie Animation Card (Glassmorphic) ──────
              Center(
                child: CustomPaint(
                  foregroundPainter: _WorkoutGlowBorderPainter(
                    color: AppColors.primary,
                    intensity: 0.8 + (_pulseController.value * 0.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.04),
                              Colors.white.withValues(alpha: 0.01),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _buildWorkoutLottie(_selectedExercise),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Dropdowns row (Glassmorphic) ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildCardDropdown(
                      label: 'EXERCISE',
                      value: _selectedExercise,
                      items: _exercises,
                      onChanged: (val) {
                        setState(() {
                          _selectedExercise = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCardDropdown(
                      label: 'MUSCLE GROUP',
                      value: _selectedMuscleGroup,
                      items: _muscleGroups,
                      onChanged: (val) {
                        setState(() {
                          _selectedMuscleGroup = val!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Duration & Difficulty (Glassmorphic) ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.04),
                                Colors.white.withValues(alpha: 0.01),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DURATION (MIN)',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_durationMinutes > 5) {
                                        setState(() => _durationMinutes -= 5);
                                      }
                                    },
                                    child: const Icon(Icons.remove_circle_outline, color: AppColors.secondary, size: 20),
                                  ),
                                  Text(
                                    '$_durationMinutes',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _durationMinutes += 5);
                                    },
                                    child: const Icon(Icons.add_circle_outline, color: AppColors.secondary, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCardDropdown(
                      label: 'DIFFICULTY',
                      value: _difficulty,
                      items: const ['Easy', 'Medium', 'Hard'],
                      onChanged: (val) {
                        setState(() {
                          _difficulty = val!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Sets Section Header ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sets & Reps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add, color: AppColors.secondary, size: 18),
                    label: const Text(
                      'Add Set',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Sets List (Animated/Glassmorphic) ────────────────────────
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  return TweenAnimationBuilder<double>(
                    key: ValueKey('set_${index}_${_sets.length}'),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.95 + (value * 0.05),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.04),
                                  Colors.white.withValues(alpha: 0.01),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Reps Input
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'REPS',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              if (set['reps']! > 1) {
                                                setState(() => set['reps'] = set['reps']! - 1);
                                              }
                                            },
                                            child: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white60, size: 18),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${set['reps']}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() => set['reps'] = set['reps']! + 1);
                                            },
                                            child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white60, size: 18),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Weight Input
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'WEIGHT (KG)',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              if (set['weight']! > 0) {
                                                setState(() => set['weight'] = set['weight']! - 5);
                                              }
                                            },
                                            child: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white60, size: 18),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${set['weight']}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() => set['weight'] = set['weight']! + 5);
                                            },
                                            child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white60, size: 18),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Delete Button
                                IconButton(
                                  onPressed: () => _removeSet(index),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Log Workout Button (Glowing & Gradient) ───────────────────
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(
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
                  onPressed: _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'LOG WORKOUT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              DropdownButton<String>(
                value: value,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: AppColors.surfaceVariant,
                iconEnabledColor: Colors.white70,
                iconSize: 20,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutLottie(String exercise) {
    String lottieUrl = '';
    switch (exercise) {
      case 'Squat':
        lottieUrl = 'https://lottie.host/cbef1210-911f-4ee6-bb4d-616c2c77d54b/v7jLpE7XvV.json';
        break;
      case 'Bench Press':
      case 'Overhead Press':
        lottieUrl = 'https://lottie.host/80a08e1d-c8ef-46c5-8461-1e967a3a5f9f/7Q5t7hWn3w.json';
        break;
      case 'Deadlift':
        lottieUrl = 'https://lottie.host/da80f922-263a-4467-bc18-bd83e8fa2989/Lp0F223w1P.json';
        break;
      case 'Dumbbell Bicep Curl':
        lottieUrl = 'https://lottie.host/d46b7a2d-ec2d-4f10-911f-c689d0b809a4/q1E3e7Wz5D.json';
        break;
      case 'Push-up':
      case 'Pull-up':
      case 'Tricep Dips':
      default:
        lottieUrl = 'https://lottie.host/de5183db-1d89-497f-9b16-f365d95ea72b/y26lH1Wwfa.json';
        break;
    }

    return Lottie.network(
      lottieUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.secondary),
              SizedBox(height: 8),
              Text(
                'Power Up Your Day!',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessOverlay(int xp, int gold) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 2500), () {
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
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
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
                      'WORKOUT LOGGED!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 1.5,
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
