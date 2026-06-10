import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  UserProfile _profile = UserProfile(
    name: '',
    gender: '',
    age: 0,
    heightCm: 0.0,
    weightKg: 0.0,
    goals: const [],
  );

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<String> _goalOptions = [
    'Lose Weight',
    'Build Muscle',
    'Improve Endurance',
    'Better Sleep',
    'Eat Healthier',
    'Stay Active',
  ];

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.person_outline_rounded,
      title: "What's your name?",
      subtitle: 'Let us know what to call you!',
      color: Color(0xFF2AE8A0),
    ),
    _OnboardingPage(
      icon: Icons.wc_rounded,
      title: 'Gender',
      subtitle: 'This helps us personalize your plan.',
      color: Color(0xFF1CCBFF),
    ),
    _OnboardingPage(
      icon: Icons.cake_rounded,
      title: 'Age',
      subtitle: 'How old are you?',
      color: Color(0xFF6CFFB4),
    ),
    _OnboardingPage(
      icon: Icons.height_rounded,
      title: 'Height',
      subtitle: 'Enter your height in cm.',
      color: Color(0xFF9A80FF),
    ),
    _OnboardingPage(
      icon: Icons.monitor_weight_rounded,
      title: 'Weight',
      subtitle: 'Enter your weight in kg.',
      color: Color(0xFF2AE8A0),
    ),
    _OnboardingPage(
      icon: Icons.flag_rounded,
      title: 'Your Goals',
      subtitle: 'Select all that apply.',
      color: Color(0xFF1CCBFF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _slideController.reset();
      _slideController.forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _slideController.reset();
      _slideController.forward();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnboardingSuccessScreen(profile: _profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B1F17),
              Color(0xFF0F2B1F),
              Color(0xFF0A1E16),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  lineColor: const Color(0x1A4E8B),
                  spacing: 44.0,
                  thickness: 1.1,
                ),
              ),
            ),

            // Glow blobs
            Positioned(
              top: -60,
              left: -40,
              child: _GlowBlob(
                radius: 240,
                colors: const [Color(0xFF2AE8A0), Color(0xFF134D42)],
              ),
            ),
            Positioned(
              top: 280,
              right: -90,
              child: _GlowBlob(
                radius: 210,
                colors: const [Color(0xFF1CCBFF), Color(0xFF0D2A35)],
              ),
            ),
            Positioned(
              bottom: 180,
              left: -70,
              child: _GlowBlob(
                radius: 260,
                colors: const [Color(0xFF6CFFB4), Color(0xFF0E3A28)],
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _pages.length,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _pages[_currentPage].color,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),

                  // Page indicator dots
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? _pages[_currentPage].color
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _OnboardingPageContent(
                          page: _pages[index],
                          profile: _profile,
                          goalOptions: _goalOptions,
                          onProfileUpdate: (updated) {
                            setState(() => _profile = updated);
                          },
                        );
                      },
                    ),
                  ),

                  // Navigation buttons
                  SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
                      child: Row(
                        children: [
                          if (_currentPage > 0)
                            Expanded(
                              child: _GlassButton(
                                label: 'Back',
                                isPrimary: false,
                                onPressed: _prevPage,
                              ),
                            ),
                          if (_currentPage > 0) const SizedBox(width: 14),
                          Expanded(
                            child: _GlassButton(
                              label: _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              isPrimary: true,
                              accentColor: _pages[_currentPage].color,
                              onPressed: _nextPage,
                            ),
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
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _OnboardingPageContent extends StatefulWidget {
  final _OnboardingPage page;
  final UserProfile profile;
  final List<String> goalOptions;
  final ValueChanged<UserProfile> onProfileUpdate;

  const _OnboardingPageContent({
    required this.page,
    required this.profile,
    required this.goalOptions,
    required this.onProfileUpdate,
  });

  @override
  State<_OnboardingPageContent> createState() =>
      _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<_OnboardingPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleAnim = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon with glowing orb
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.page.color.withValues(alpha: 0.35),
                            widget.page.color.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.page.color.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.page.icon,
                        size: 64,
                        color: widget.page.color,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                widget.page.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                widget.page.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 44),

              // Content
              _buildPageContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (widget.page.icon) {
      case Icons.person_outline_rounded:
        return _buildNameField();
      case Icons.wc_rounded:
        return _buildGenderField();
      case Icons.cake_rounded:
        return _buildAgeField();
      case Icons.height_rounded:
        return _buildHeightField();
      case Icons.monitor_weight_rounded:
        return _buildWeightField();
      case Icons.flag_rounded:
        return _buildGoalsField();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameField() {
    final controller = TextEditingController(text: widget.profile.name);
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: _glassInputDecoration(
          hintText: 'Enter your name',
          suffixIcon: Icons.person_rounded,
        ),
        onChanged: (value) {
          widget.onProfileUpdate(widget.profile.copyWith(name: value));
        },
      ),
    );
  }

  Widget _buildGenderField() {
    final genders = ['Male', 'Female', 'Other'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: genders.map((gender) {
        final isSelected = widget.profile.gender == gender;
        return GestureDetector(
          onTap: () {
            widget.onProfileUpdate(widget.profile.copyWith(gender: gender));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.elasticOut,
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? widget.page.color.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: isSelected
                    ? widget.page.color
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: widget.page.color.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              gender == 'Male'
                  ? Icons.male_rounded
                  : gender == 'Female'
                      ? Icons.female_rounded
                      : Icons.person_rounded,
              size: 40,
              color: isSelected ? widget.page.color : Colors.white70,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgeField() {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: _glassInputDecoration(
          hintText: 'Enter your age',
          suffixIcon: Icons.cake_rounded,
        ),
        onChanged: (value) {
          final age = int.tryParse(value) ?? 0;
          widget.onProfileUpdate(widget.profile.copyWith(age: age));
        },
      ),
    );
  }

  Widget _buildHeightField() {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: _glassInputDecoration(
          hintText: 'Enter height in cm',
          suffixIcon: Icons.height_rounded,
        ),
        onChanged: (value) {
          final height = double.tryParse(value) ?? 0.0;
          widget.onProfileUpdate(widget.profile.copyWith(heightCm: height));
        },
      ),
    );
  }

  Widget _buildWeightField() {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: _glassInputDecoration(
          hintText: 'Enter weight in kg',
          suffixIcon: Icons.monitor_weight_rounded,
        ),
        onChanged: (value) {
          final weight = double.tryParse(value) ?? 0.0;
          widget.onProfileUpdate(widget.profile.copyWith(weightKg: weight));
        },
      ),
    );
  }

  Widget _buildGoalsField() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: widget.goalOptions.map((goal) {
        final isSelected = widget.profile.goals.contains(goal);
        return GestureDetector(
          onTap: () {
            final updatedGoals = List<String>.from(widget.profile.goals);
            if (isSelected) {
              updatedGoals.remove(goal);
            } else {
              updatedGoals.add(goal);
            }
            widget.onProfileUpdate(
              widget.profile.copyWith(goals: updatedGoals),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.elasticOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.page.color.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? widget.page.color
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: widget.page.color.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Text(
              goal,
              style: TextStyle(
                color: isSelected ? widget.page.color : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _glassInputDecoration({
    required String hintText,
    required IconData suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: widget.page.color,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      suffixIcon: Icon(suffixIcon, color: Colors.white.withValues(alpha: 0.5)),
    );
  }
}

class OnboardingSuccessScreen extends StatefulWidget {
  final UserProfile profile;

  const OnboardingSuccessScreen({super.key, required this.profile});

  @override
  State<OnboardingSuccessScreen> createState() =>
      _OnboardingSuccessScreenState();
}

class _OnboardingSuccessScreenState extends State<OnboardingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _checkDrawProgress;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _scaleAnim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _checkDrawProgress = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B1F17),
              Color(0xFF0F2B1F),
              Color(0xFF0A1E16),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  lineColor: const Color(0x1A4E8B),
                  spacing: 44.0,
                  thickness: 1.1,
                ),
              ),
            ),
            Positioned(
              top: -60,
              left: -40,
              child: _GlowBlob(
                radius: 240,
                colors: const [Color(0xFF2AE8A0), Color(0xFF134D42)],
              ),
            ),
            Positioned(
              top: 280,
              right: -90,
              child: _GlowBlob(
                radius: 210,
                colors: const [Color(0xFF1CCBFF), Color(0xFF0D2A35)],
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Animated success circle
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF2AE8A0).withValues(alpha: 0.4),
                              const Color(0xFF2AE8A0).withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2AE8A0).withValues(alpha: 0.5),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _CheckmarkPainter(
                            progress: _checkDrawProgress.value,
                            color: const Color(0xFF2AE8A0),
                          ),
                          size: const Size(150, 150),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        'Welcome, ${widget.profile.name}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              height: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        'Your profile is ready!\nLet\'s start your fitness journey.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const Spacer(),

                    // Confetti particles
                    ...List.generate(12, (index) {
                      return _ConfettiParticle(
                        delay: Duration(milliseconds: 150 * index),
                        color: [
                          const Color(0xFF2AE8A0),
                          const Color(0xFF1CCBFF),
                          const Color(0xFF6CFFB4),
                          const Color(0xFF9A80FF),
                          const Color(0xFFFFD700),
                        ][index % 5],
                      );
                    }),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to Home (placeholder)
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0A2A1D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 6,
                              shadowColor: Colors.white.withValues(alpha: 0.3),
                            ),
                            child: const Text(
                              'Start Your Journey',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0A2A1D),
                              ),
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
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    // Outer circle
    canvas.drawCircle(center, radius, paint);

    // Animated checkmark
    if (progress > 0) {
      final checkProgress = (progress - 0.3) / 0.7;
      if (checkProgress > 0) {
        final start = Offset(center.dx - 28, center.dy);
        final mid = Offset(center.dx - 5, center.dy + 22);
        final end = Offset(center.dx + 32, center.dy - 22);

        if (checkProgress <= 0.5) {
          final p = checkProgress * 2;
          canvas.drawLine(start, Offset.lerp(start, mid, p)!, paint);
        } else {
          canvas.drawLine(start, mid, paint);
          final p = (checkProgress - 0.5) * 2;
          canvas.drawLine(mid, Offset.lerp(mid, end, p)!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiParticle extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _ConfettiParticle({required this.delay, required this.color});

  @override
  State<_ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<_ConfettiParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final progress = _anim.value;
        return Positioned(
          top: 100 + (progress * 300) % 200,
          left: (progress * 400) % (MediaQuery.of(context).size.width - 40),
          child: Opacity(
            opacity: (1 - progress).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: progress,
              child: Container(
                width: 6 + (progress * 4),
                height: 6 + (progress * 4),
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.7),
                      blurRadius: 8,
                      spreadRadius: 1,
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

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.isPrimary,
    this.accentColor,
    required this.onPressed,
  });

  final String label;
  final bool isPrimary;
  final Color? accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withValues(alpha: 0.95),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isPrimary
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: (accentColor ?? const Color(0xFF2AE8A0)).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? null : Colors.transparent,
          foregroundColor: isPrimary ? const Color(0xFF0A2A1D) : Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isPrimary ? const Color(0xFF0A2A1D) : Colors.white,
          ),
        ),
      ),
    );
  }
}
