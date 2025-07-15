import 'package:Wicore/providers/auth_provider.dart';
import 'package:Wicore/screens/calendar_screen.dart';
import 'package:Wicore/screens/device_history_screen.dart';
import 'package:Wicore/screens/email_input_screen.dart';
import 'package:Wicore/screens/email_verification_screen.dart';
import 'package:Wicore/screens/email_verification_success_screen.dart';
import 'package:Wicore/screens/forgot_password_screen.dart';
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
import 'package:Wicore/screens/register_screen.dart';
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
import 'package:go_router/go_router.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authService,
      redirect: (context, state) {
        final isInitialized = authService.authStatus != AuthStatus.unknown;
        final isAuthenticated = authService.isAuthenticated;
        final currentPath = state.matchedLocation;

        // CRITICAL: Never redirect away from splash screen
        if (currentPath == '/splash') {
          return null;
        }

        // Only redirect to splash if we're truly not initialized AND not already there
        if (!isInitialized && currentPath != '/splash') {
          return '/splash';
        }

        // Handle authenticated users
        if (isAuthenticated) {
          // Redirect authenticated users from auth screens to main app
          if (currentPath == '/login' ||
              currentPath == '/register' ||
              currentPath == '/welcome' ||
              currentPath == '/name-input' ||
              currentPath == '/home' ||
              currentPath == '/forgot-password') {
            return '/navigation';
          }
        }

        // Handle unauthenticated users
        if (!isAuthenticated && isInitialized) {
          // Only redirect to login from protected routes
          if (currentPath == '/navigation' || currentPath == '/home') {
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
        GoRoute(
          path: '/personal-info-input',
          name: 'personal-info-input',
          builder: (context, state) => PersonalInfoInputScreen(),
        ),
        GoRoute(
          path: '/phone-input',
          name: '/phone-input',
          builder: (context, state) => PhoneInputScreen(),
        ),
        GoRoute(
          path: '/prep-done',
          name: '/prep-done',
          builder: (context, state) => PrepDoneScreen(),
        ),
        GoRoute(
          path: '/navigation',
          name: 'navigation',
          builder: (context, state) => MainNavigation(),
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
                // Add your bottom navigation bar here if needed
                // bottomNavigationBar: YourBottomNavigationBar(),
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
          builder: (context, state) => ChronologicalListScreen(),
        ),
        GoRoute(
          path: '/personal-info-display-screen',
          name: 'personal-info-display-screen',
          builder: (context, state) => PersonalInfoDisplayScreen(),
        ),
        GoRoute(
          path: '/notificatios-settings',
          name: 'notificatios-settings',
          builder: (context, state) => NotificationSettingsScreen(),
        ),
        GoRoute(
          path: '/terms-of-use',
          name: 'terms-of-use',
          builder: (context, state) => TermsOfServiceScreen(),
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
                    onPressed:
                        () => context.go('/navigation'), // Changed from '/home'
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
