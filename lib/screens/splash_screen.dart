import 'package:Wicore/providers/auth_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _colorController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize color animation controller
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create fade animation (from full opacity to slightly faded)
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Create color animation (from original to greenish)
    _colorAnimation = ColorTween(
      begin: null, // Will use original colors
      end: CustomColors.splashLimeColor, // Greenish color
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    // Start animations with delay
    _startAnimations();
  }

  void _startAnimations() async {
    // Wait a bit before starting
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if widget is still mounted before starting fade animation
    if (mounted) {
      _fadeController.forward();
    }

    // Start color animation slightly after fade
    await Future.delayed(const Duration(milliseconds: 300));

    // Check if widget is still mounted before starting color animation
    if (mounted) {
      _colorController.forward();
    }

    // Wait for animations to complete, then navigate
    await Future.delayed(
      const Duration(milliseconds: 1700),
    ); // Total: ~2.5 seconds

    if (mounted) {
      _navigateAfterAnimation();
    }
  }

  void _navigateAfterAnimation() {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } catch (e) {
      print('Error during navigation: $e');
      // Fallback navigation
      context.go('/login');
    }
  }

  @override
  void dispose() {
    // Stop any ongoing animations before disposing
    _fadeController.stop();
    _colorController.stop();

    _fadeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _colorAnimation]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: _colorAnimation.value,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Logo (background layer)
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                          child: Image.asset(
                            'assets/images/splash.png', // Replace with your logo asset path
                            width: 394,
                            height: 197,
                          ),
                        ),
                      );
                    },
                  ),

                  // Text overlay (foreground layer) - positioned lower
                  Positioned(
                    top: 100, // Adjust this value to move text up/down
                    child: AnimatedBuilder(
                      animation: _colorController,
                      builder: (context, child) {
                        return AnimatedOpacity(
                          opacity: _colorController.value,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            'WICORE',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 4.8,
                              fontFamily: TextStyles.kTitleFontfamily,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
