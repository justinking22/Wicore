import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/user_provider.dart';

import 'package:Wicore/screens/calendar_screen.dart';
import 'package:Wicore/screens/date_stats_screen.dart';
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
import 'package:Wicore/screens/personal_info_input_screen.dart'; // ✅ Make sure this import exists
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
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterRefreshStream(ref),
    redirect: (context, state) async {
      final authState = ref.read(authNotifierProvider);
      final userState = ref.read(userProvider);
      final onboardingManager = ref.read(onboardingManagerProvider);

      final isInitialized = authState.status != AuthStatus.unknown;
      final isAuthenticated = authState.isAuthenticated;

      // Get onboarded status from API
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
        // ✅ FIXED: Better onboarding logic
        if (!isUserOnboarded) {
          // Check if we should show onboarding today (once per day until completed)
          final shouldShowOnboarding = await onboardingManager
              .shouldShowOnboarding(isUserOnboarded: isUserOnboarded);

          print('🔄 Router - Should show onboarding: $shouldShowOnboarding');

          if (shouldShowOnboarding) {
            // Allow staying in onboarding flow
            final onboardingPaths = [
              '/onboarding',
              '/phone-input',
              '/prep-done',
            ];

            if (onboardingPaths.contains(currentPath)) {
              print(
                '🔄 Router - User in onboarding flow, staying on current screen',
              );
              return null;
            }

            // Redirect to start of onboarding and mark as shown for today
            print('🔄 Router - Starting onboarding flow');
            await onboardingManager.markOnboardingPromptShown();
            return '/onboarding';
          } else {
            // Already showed onboarding today, skip for now
            print(
              '🔄 Router - Skipping onboarding for today, going to main app',
            );

            // If user is currently on onboarding screens but we're not showing today, redirect to main
            final onboardingPaths = [
              '/onboarding',
              '/phone-input',
              '/prep-done',
            ];
            if (onboardingPaths.contains(currentPath)) {
              return '/navigation';
            }
          }
        }

        // User is fully onboarded - redirect from auth screens to main app
        final authScreens = [
          '/login',
          '/register',
          '/welcome',
          '/name-input',
          '/email-input',
          '/password-input',
          '/password-re-enter',
          '/forgot-password',
        ];

        if (authScreens.contains(currentPath)) {
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

      // Handle unauthenticated users - redirect protected routes to login
      if (!isAuthenticated && isInitialized) {
        final protectedPaths = [
          '/navigation',
          '/home',
          '/personal-info-input',
          '/phone-input',
          '/prep-done',
          '/calendar-screen',
          '/device-history-screen',
          '/personal-info-display-screen',
          '/notifications-settings',
          '/terms-of-use',
          '/qr-scan-screen',
        ];

        final isProtectedPath = protectedPaths.any(
          (path) => currentPath == path || currentPath.startsWith('${path}/'),
        );

        if (isProtectedPath) {
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
      // ✅ Make sure this route exists and the widget is properly imported
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder:
            (context, state) =>
                PersonalInfoInputScreen(), // Ensure this widget exists
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
        builder: (context, state) => CalendarScreen(),
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
      GoRoute(
        path: '/date-stats-screen',
        name: 'date-stats-screen',
        builder: (context, state) {
          DateTime selectedDate;

          if (state.extra != null && state.extra is DateTime) {
            selectedDate = state.extra as DateTime;
          } else {
            selectedDate = DateTime.now();
          }

          return DateStatsScreen(selectedDate: selectedDate);
        },
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
