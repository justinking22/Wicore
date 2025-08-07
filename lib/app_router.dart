import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/user_provider.dart';

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
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/utilities/main_navigation.dart';
import 'package:Wicore/widgets/device_details_widget.dart';
import 'package:Wicore/models/user_response_model.dart';
import 'package:Wicore/widgets/onboarding_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterRefreshStream(ref),
    redirect: (context, state) async {
      final authState = ref.read(authNotifierProvider);
      final userState = ref.read(userProvider);
      final onboardingManager = ref.read(onboardingManagerProvider);

      final isInitialized = authState.status != AuthStatus.unknown;
      final isAuthenticated = authState.isAuthenticated;

      // ✅ Safe way to get onboarded status from API
      final isUserOnboarded = userState.when(
        data: (response) {
          final onboarded = response?.data?.onboarded ?? false;
          print('🔄 Router - User API onboarded status: $onboarded');
          return onboarded;
        },
        loading: () {
          print('🔄 Router - User provider loading, assuming not onboarded');
          return false;
        },
        error: (error, stackTrace) {
          print(
            '🔄 Router - User provider error, assuming not onboarded: $error',
          );
          return false;
        },
      );

      final currentPath = state.matchedLocation;

      print(
        '🔄 Router - Path: $currentPath, Auth: $isAuthenticated, Onboarded: $isUserOnboarded',
      );

      // Never redirect away from splash screen
      if (currentPath == '/splash') {
        return null;
      }

      // Redirect to splash if not initialized
      if (!isInitialized && currentPath != '/splash') {
        print('🔄 Router - Redirecting to splash (not initialized)');
        return '/splash';
      }

      // Handle authenticated users
      if (isAuthenticated) {
        // ✅ IMPROVED: Check if we should show onboarding screens
        if (!isUserOnboarded) {
          // Check if we should show onboarding today
          final shouldShowOnboarding = await onboardingManager
              .shouldShowOnboarding(isUserOnboarded: isUserOnboarded);

          print('🔄 Router - Should show onboarding: $shouldShowOnboarding');

          if (shouldShowOnboarding) {
            // Allow onboarding flow paths
            if (currentPath == '/personal-info-input' ||
                currentPath == '/phone-input' ||
                currentPath == '/prep-done') {
              print('🔄 Router - User in onboarding flow, allowing');
              return null; // Stay on current onboarding screen
            }

            // Redirect to start of onboarding
            print(
              '🔄 Router - Redirecting to onboarding (not completed, should show today)',
            );
            await onboardingManager.markOnboardingPromptShown();
            return '/personal-info-input';
          } else {
            // Don't show onboarding today, go to main app
            print(
              '🔄 Router - Not showing onboarding today, going to main app',
            );
            if (currentPath == '/personal-info-input' ||
                currentPath == '/phone-input' ||
                currentPath == '/prep-done') {
              return '/navigation';
            }
          }
        }

        // ✅ User is onboarded or we're not showing onboarding today
        // Redirect from auth screens to navigation
        if (currentPath == '/login' ||
            currentPath == '/register' ||
            currentPath == '/welcome' ||
            currentPath == '/name-input' ||
            currentPath == '/email-input' ||
            currentPath == '/password-input' ||
            currentPath == '/password-re-enter' ||
            currentPath == '/forgot-password') {
          print(
            '🔄 Router - Redirecting authenticated user from auth screen to navigation',
          );
          return '/navigation';
        }

        // Redirect /home to /navigation
        if (currentPath == '/home') {
          print('🔄 Router - Redirecting /home to /navigation');
          return '/navigation';
        }
      }

      // Handle unauthenticated users
      if (!isAuthenticated && isInitialized) {
        if (currentPath == '/navigation' ||
            currentPath == '/home' ||
            currentPath.startsWith('/device-') ||
            currentPath.startsWith('/personal-info-') ||
            currentPath.startsWith('/calendar-') ||
            currentPath.startsWith('/notifications-') ||
            currentPath.startsWith('/terms-of-use') ||
            currentPath.startsWith('/qr-scan-')) {
          print('🔄 Router - Redirecting unauthenticated user to login');
          return '/login';
        }
      }

      return null;
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
        builder: (context, state) => WelcomeScreen(),
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
                  context.go('/home?qrResult=$qrCode');
                },
                onBackPressed: () {
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
        builder: (context, state) => const PersonalInfoDisplayScreen(),
      ),
      GoRoute(
        path: '/notifications-settings',
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

// ✅ RouterRefreshStream remains the same
class RouterRefreshStream extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription _authSubscription;
  late final ProviderSubscription _userSubscription;

  RouterRefreshStream(this._ref) {
    _authSubscription = _ref.listen<AuthState>(authNotifierProvider, (
      previous,
      next,
    ) {
      if (previous?.status != next.status) {
        print(
          '🔄 Router - Auth status changed: ${previous?.status} -> ${next.status}',
        );
        notifyListeners();
      }
    });

    _userSubscription = _ref.listen<AsyncValue<UserResponse?>>(userProvider, (
      previous,
      next,
    ) {
      final previousOnboarded = _safeGetOnboardedStatus(previous);
      final nextOnboarded = _safeGetOnboardedStatus(next);

      if (previousOnboarded != nextOnboarded) {
        print(
          '🔄 Router - User onboarded status changed: $previousOnboarded -> $nextOnboarded',
        );
        notifyListeners();
      }
    });
  }

  bool? _safeGetOnboardedStatus(AsyncValue<UserResponse?>? asyncValue) {
    if (asyncValue == null) return null;

    return asyncValue.when(
      data: (response) => response?.data?.onboarded,
      loading: () => null,
      error: (error, stackTrace) {
        print(
          '🔄 Router - Error state detected, returning null for onboarded status',
        );
        return null;
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.close();
    _userSubscription.close();
    super.dispose();
  }
}
