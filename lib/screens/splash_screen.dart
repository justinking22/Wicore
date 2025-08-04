import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _colorController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  bool _hasNavigated = false; // Prevent multiple navigation

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

    if (mounted && !_hasNavigated) {
      _navigateAfterAnimation();
    }
  }

  void _navigateAfterAnimation() {
    if (_hasNavigated) return;

    setState(() {
      _hasNavigated = true;
    });

    try {
      final authState = ref.read(authNotifierProvider);

      print('Auth status on splash: ${authState.status}');
      print('Is authenticated: ${authState.isAuthenticated}');

      switch (authState.status) {
        case AuthStatus.authenticated:
          print('Navigating to home - user is authenticated');
          context.go('/home');
          break;
        case AuthStatus.unauthenticated:
          print('Navigating to login - user is not authenticated');
          context.go('/login');
          break;
        case AuthStatus.needsConfirmation:
          print('Navigating to confirmation - user needs confirmation');
          context.push('/email-verification');
          break;
        case AuthStatus.unknown:
        default:
          print('Auth status unknown, defaulting to login');
          // Wait a bit more for auth state to resolve, then default to login
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_hasNavigated) {
              context.go('/login');
            }
          });
          break;
      }
    } catch (e) {
      print('Error during navigation: $e');
      // Fallback navigation
      if (mounted) {
        context.go('/login');
      }
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
    // Listen to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // Only navigate if animations are likely complete and we haven't navigated yet
      if (!_hasNavigated &&
          _colorController.isCompleted &&
          next.status != AuthStatus.unknown) {
        _navigateAfterAnimation();
      }
    });

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
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if image doesn't exist
                              return Container(
                                width: 394,
                                height: 197,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
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
