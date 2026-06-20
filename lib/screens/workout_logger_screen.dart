import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class WorkoutLoggerScreen extends StatefulWidget {
  const WorkoutLoggerScreen({super.key});

  @override
  State<WorkoutLoggerScreen> createState() => _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends State<WorkoutLoggerScreen> {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

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

    // Calculate XP and GOLD rewards based on sets, reps, and difficulty
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log Strength Workout',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // ── Dynamic Exercise Lottie Animation Card ────
              Center(
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildWorkoutLottie(_selectedExercise),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Dropdowns row ─────────────────────────────
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
                  const SizedBox(width: 16),
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
              const SizedBox(height: 20),

              // ── Duration & Difficulty ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_durationMinutes > 5) {
                                    setState(() => _durationMinutes -= 5);
                                  }
                                },
                                child: const Icon(Icons.remove_circle_outline, color: Colors.white70),
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
                                child: const Icon(Icons.add_circle_outline, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
              const SizedBox(height: 24),

              // ── Sets Section ──────────────────────────────
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
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Reps Input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REPS',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (set['reps']! > 1) {
                                        setState(() => set['reps'] = set['reps']! - 1);
                                      }
                                    },
                                    child: const Icon(Icons.remove, color: Colors.white54, size: 16),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      '${set['reps']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => set['reps'] = set['reps']! + 1);
                                    },
                                    child: const Icon(Icons.add, color: Colors.white54, size: 16),
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
                                style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (set['weight']! > 0) {
                                        setState(() => set['weight'] = set['weight']! - 5);
                                      }
                                    },
                                    child: const Icon(Icons.remove, color: Colors.white54, size: 16),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      '${set['weight']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => set['weight'] = set['weight']! + 5);
                                    },
                                    child: const Icon(Icons.add, color: Colors.white54, size: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Delete Button
                        IconButton(
                          onPressed: () => _removeSet(index),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── Log Workout Button ────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'LOG WORKOUT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
            ),
          ),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surfaceVariant,
            iconEnabledColor: Colors.white70,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
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
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F121F),
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
        );
      },
    );
  }
}
