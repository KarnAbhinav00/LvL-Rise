import 'package:flutter/material.dart';

import 'email_auth_screen.dart';
import 'onboarding/onboarding_flow.dart';

class AuthOptionsScreen extends StatefulWidget {
  const AuthOptionsScreen({super.key});

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen>
    with TickerProviderStateMixin {
  bool _loadingGoogle = false;
  bool _loadingEmail = false;

  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleAuth() async {
    if (_loadingGoogle) return;
    setState(() => _loadingGoogle = true);

    try {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OnboardingFlow(),
        ),
      );
    } catch (e) {
      debugPrint('Google auth failed: $e');
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    if (_loadingEmail) return;
    setState(() => _loadingEmail = true);

    try {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const EmailAuthScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Email auth failed: $e');
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _handleAppleAuth() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign in with Apple coming soon!'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A14),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── Top Branding Header ──────────────────
                Expanded(
                  flex: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo / Icon
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF2AE8A0).withValues(alpha: 0.4),
                                const Color(0xFF2AE8A0).withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2AE8A0).withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 48,
                            color: Color(0xFF2AE8A0),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Text(
                          'LevelRise',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Your fitness journey starts here',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Buttons ───────────────────────
                Expanded(
                  flex: 60,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Google - Brand White Button
                        _BrandSignInButton(
                          label: 'Continue with Google',
                          backgroundColor: Colors.white,
                          textColor: const Color(0xFF1F1F1F),
                          icon: Icons.g_mobiledata_rounded,
                          iconColor: const Color(0xFF4285F4),
                          loading: _loadingGoogle,
                          onPressed: _handleGoogleAuth,
                        ),

                        const SizedBox(height: 14),

                        // Email - Blue accent
                        _BrandSignInButton(
                          label: 'Sign in with Email',
                          backgroundColor: const Color(0xFF0F2B1F),
                          textColor: Colors.white,
                          icon: Icons.email_rounded,
                          iconColor: const Color(0xFF1DA1F2),
                          loading: _loadingEmail,
                          onPressed: _handleEmailAuth,
                        ),

                        const SizedBox(height: 14),

                        // Apple - Black/Dark
                        _BrandSignInButton(
                          label: 'Sign in with Apple',
                          backgroundColor: const Color(0xFF000000),
                          textColor: Colors.white,
                          icon: Icons.apple_rounded,
                          iconColor: Colors.white,
                          onPressed: _handleAppleAuth,
                        ),

                        const SizedBox(height: 20),

                        // Quick Start Guest
                        TextButton.icon(
                          onPressed: _handleAppleAuth,
                          icon: Icon(
                            Icons.person_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          label: Text(
                            'Continue as Guest',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandSignInButton extends StatelessWidget {
  const _BrandSignInButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.iconColor,
    this.loading = false,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.7),
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white54,
                ),
              )
            else
              Icon(
                icon,
                color: iconColor,
                size: 26,
              ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
