import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:with_force/providers/auth_provider.dart';
import 'package:with_force/screens/email_input_screen.dart';
import 'package:with_force/screens/email_verification_screen.dart';
import 'package:with_force/screens/email_verification_success_screen.dart';
import 'package:with_force/screens/password_input_screen.dart';
import 'package:with_force/screens/password_re_enter_screen.dart';
import 'package:with_force/screens/password_reset_screen.dart';
import 'package:with_force/screens/password_reset_succes_screen.dart';
import 'package:with_force/screens/sign_in_screen.dart';
import 'package:with_force/screens/sign_up_complete_screen.dart';
import 'package:with_force/screens/splash_screen.dart';
import 'package:with_force/screens/terms_and_conditions_screen.dart';
import 'package:with_force/screens/welcome_screen.dart';
import 'package:with_force/screens/login_screen.dart';
import 'package:with_force/screens/register_screen.dart';
import 'package:with_force/screens/home_screen.dart';
import 'package:with_force/screens/forgot_password_screen.dart';
import 'package:with_force/screens/name_input_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authService,
      redirect: (context, state) {
        final isInitialized = authService.authStatus != AuthStatus.unknown;
        final isAuthenticated = authService.isAuthenticated;
        final currentPath = state.matchedLocation;

        // Don't redirect if we're still initializing
        if (!isInitialized && currentPath != '/splash') {
          return '/splash';
        }

        // If initialized, handle navigation flow
        if (isInitialized) {
          // Authenticated users should go to home unless they're on allowed routes
          if (isAuthenticated &&
              (currentPath == '/login' ||
                  currentPath == '/register' ||
                  currentPath == '/welcome' ||
                  currentPath == '/name-input' ||
                  currentPath == '/splash')) {
            return '/home';
          }

          // Non-authenticated users should go to login unless they're on allowed routes
          if (!isAuthenticated &&
              (currentPath == '/home' || currentPath == '/splash')) {
            return '/login';
          }
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => SplashScreen(),
        ),
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/name-input',
          name: 'name-input',
          builder: (context, state) => NameInputScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => SignInScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          path: '/email-input',
          name: 'email-input',
          builder: (context, state) => EmailInputScreen(),
        ),
        GoRoute(
          path: '/password-input',
          name: 'password-input',
          builder: (context, state) => PasswordInputScreen(),
        ),
        GoRoute(
          path: '/password-re-enter',
          name: 'password-re-enter',
          builder: (context, state) => PasswordConfirmationScreen(),
        ),
        GoRoute(
          path: '/email-verification',
          name: 'email-verification',
          builder: (context, state) => EmailVerificationScreen(),
        ),
        GoRoute(
          path: '/success-verification',
          name: 'success-verification',
          builder: (context, state) => const EmailVerificationSuccessScreen(),
        ),
        GoRoute(
          path: '/terms-and-conditions',
          name: 'terms-and-conditions',
          builder: (context, state) => const TermsAgreementScreen(),
        ),
        GoRoute(
          path: '/sign-up-complete',
          name: 'sign-up-complete',
          builder: (context, state) => const SignupCompleteScreen(),
        ),
        GoRoute(
          path: '/password-reset',
          name: 'password-reset',
          builder: (context, state) => const PasswordResetScreen(),
        ),
        GoRoute(
          path: '/password-reset-success',
          name: 'password-reset-success',
          builder: (context, state) => const PasswordResetSuccessScreen(),
        ),
      ],
      errorBuilder:
          (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Page not found: ${state.matchedLocation}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
