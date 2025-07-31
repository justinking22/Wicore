import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/screens/calendar_screen.dart';
import 'package:Wicore/screens/device_history_screen.dart';
import 'package:Wicore/screens/email_input_screen.dart';
import 'package:Wicore/screens/email_verification_screen.dart';
import 'package:Wicore/screens/email_verification_success_screen.dart';
import 'package:Wicore/screens/home_screen.dart';
import 'package:Wicore/screens/name_input_screen.dart';
import 'package:Wicore/screens/notifications_settings_screen.dart';
import 'package:Wicore/screens/password_input_screen.dart';
import 'package:Wicore/screens/password_re_enter_screen.dart';
import 'package:Wicore/screens/password_reset_confirmation_screen.dart';
import 'package:Wicore/screens/password_reset_screen.dart';
import 'package:Wicore/screens/password_reset_succes_screen.dart';
import 'package:Wicore/screens/personal_info_display_screen.dart';
import 'package:Wicore/screens/personal_info_input_screen.dart';
import 'package:Wicore/screens/phone_input_screen.dart';
import 'package:Wicore/screens/prep_done_screen.dart';
import 'package:Wicore/screens/qr_acanner_screen.dart';
import 'package:Wicore/screens/resave_phone_number_screen.dart';
import 'package:Wicore/screens/sign_in_screen.dart';
import 'package:Wicore/screens/sign_up_complete_screen.dart';
import 'package:Wicore/screens/splash_screen.dart';
import 'package:Wicore/screens/terms_and_conditions_screen.dart';
import 'package:Wicore/screens/terms_of_use_screen.dart';
import 'package:Wicore/screens/welcome_screen.dart';
import 'package:Wicore/utilities/main_navigation.dart';
import 'package:Wicore/widgets/device_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/auth_models.dart';

// Router provider for Riverpod
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterRefreshStream(ref),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isInitialized = authState.status != AuthStatus.unknown;
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.matchedLocation;

      print(
        'Router redirect - Path: $currentPath, Status: ${authState.status}, Authenticated: $isAuthenticated',
      );

      // CRITICAL: Never redirect away from splash screen
      if (currentPath == '/splash') {
        return null;
      }

      // Only redirect to splash if we're truly not initialized AND not already there
      if (!isInitialized && currentPath != '/splash') {
        print('Redirecting to splash - not initialized');
        return '/splash';
      }

      // Handle authenticated users
      if (isAuthenticated) {
        // Redirect authenticated users from auth screens to main app
        if (currentPath == '/login' ||
            currentPath == '/register' ||
            currentPath == '/welcome' ||
            currentPath == '/name-input' ||
            currentPath == '/email-input' ||
            currentPath == '/password-input' ||
            currentPath == '/password-re-enter' ||
            currentPath == '/forgot-password') {
          print('Redirecting authenticated user to navigation');
          return '/navigation';
        }

        // Redirect /home to /navigation for authenticated users
        if (currentPath == '/home') {
          return '/navigation';
        }
      }

      // Handle unauthenticated users
      if (!isAuthenticated && isInitialized) {
        // Only redirect to login from protected routes
        if (currentPath == '/navigation' ||
            currentPath == '/home' ||
            currentPath.startsWith('/device-') ||
            currentPath.startsWith('/personal-info-') ||
            currentPath.startsWith('/calendar-') ||
            currentPath.startsWith('/notifications-') ||
            currentPath.startsWith('/terms-of-use') ||
            currentPath.startsWith('/qr-scan-')) {
          print('Redirecting unauthenticated user to login');
          return '/login';
        }
      }

      // Handle users needing confirmation
      if (authState.status == AuthStatus.needsConfirmation) {
        if (currentPath != '/email-verification' &&
            currentPath != '/success-verification') {
          print('Redirecting to email verification');
          return '/email-verification';
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/name-input',
        name: 'name-input',
        builder: (context, state) => const NameInputScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/email-input',
        name: 'email-input',
        builder: (context, state) => const EmailInputScreen(),
      ),
      GoRoute(
        path: '/password-input',
        name: 'password-input',
        builder: (context, state) => const PasswordInputScreen(),
      ),
      GoRoute(
        path: '/password-re-enter',
        name: 'password-re-enter',
        builder: (context, state) => const PasswordConfirmationScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email-verification',
        builder: (context, state) {
          return EmailVerificationScreen();
        },
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
      GoRoute(
        path: '/personal-info-input',
        name: 'personal-info-input',
        builder: (context, state) => PersonalInfoInputScreen(),
      ),
      GoRoute(
        path: '/phone-input',
        name: 'phone-input',
        builder: (context, state) => PhoneInputScreen(),
      ),
      GoRoute(
        path: '/prep-done',
        name: 'prep-done',
        builder: (context, state) => const PrepDoneScreen(),
      ),
      GoRoute(
        path: '/navigation',
        name: 'navigation',
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: '/qr-scan-screen',
        builder:
            (context, state) => Scaffold(
              body: QRScannerWidget(
                onQRScanned: (qrCode) {
                  // Navigate back with result
                  context.go('/home?qrResult=$qrCode');
                },
                onBackPressed: () {
                  // Navigate back without result
                  context.go('/home');
                },
              ),
            ),
      ),
      GoRoute(
        path: '/device-details',
        builder: (context, state) {
          final deviceId = state.uri.queryParameters['deviceId'] ?? 'UNKNOWN';
          return DeviceDetailsWidget(deviceId: deviceId);
        },
      ),
      GoRoute(
        path: '/calendar-screen',
        name: 'calendar-screen',
        builder: (context, state) => KoreanCalendar(),
      ),
      GoRoute(
        path: '/device-history-screen',
        name: 'device-history-screen',
        builder: (context, state) => DeviceHistoryScreen(),
      ),
      GoRoute(
        path: '/personal-info-display-screen',
        name: 'personal-info-display-screen',
        builder: (context, state) => PersonalInfoDisplayScreen(),
      ),
      GoRoute(
        path: '/notifications-settings', // Fixed typo
        name: 'notifications-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/terms-of-use',
        name: 'terms-of-use',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/re-save-phone-number-screen',
        name: 're-save-phone-number-screen',
        builder: (context, state) => ResavePhoneNumberScreen(),
      ),
      GoRoute(
        path: '/password-reset-confirmation-screen',
        name: 'password-reset-confirmation-screen',
        builder: (context, state) => PasswordResetConfirmationScreen(),
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
                  onPressed: () => context.go('/navigation'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
  );
});

// Helper class to make GoRouter refresh when auth state changes
class RouterRefreshStream extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription _subscription;

  RouterRefreshStream(this._ref) {
    _subscription = _ref.listen<AuthState>(authNotifierProvider, (
      previous,
      next,
    ) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
