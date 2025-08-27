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
import 'package:Wicore/screens/password_reset_otp_screen.dart';
import 'package:Wicore/screens/password_reset_screen.dart';
import 'package:Wicore/screens/password_reset_succes_screen.dart';
import 'package:Wicore/screens/personal_info_display_screen.dart';
import 'package:Wicore/screens/personal_info_input_screen.dart';
import 'package:Wicore/screens/phone_input_screen.dart';
import 'package:Wicore/screens/prep_done_screen.dart';
import 'package:Wicore/screens/qr_acanner_screen.dart';
import 'package:Wicore/screens/resave_phone_number_screen.dart';
import 'package:Wicore/screens/reset_password_new_input_screen.dart';
import 'package:Wicore/screens/reset_password_reenter_screen.dart';
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

Future<String?> _handleOnboardingFlow(
  String currentPath,
  dynamic onboardingManager,
  bool isUserOnboarded,
  Ref ref,
) async {
  try {
    // If already onboarded according to API, never show onboarding
    if (isUserOnboarded) {
      print(
        '🔄 Router - API says user is onboarded, redirecting to navigation',
      );
      return '/navigation';
    }

    // Handle users in onboarding flow
    final onboardingPaths = ['/onboarding', '/phone-input', '/prep-done'];
    if (onboardingPaths.contains(currentPath)) {
      print('🔄 Router - User in onboarding flow, staying on current screen');
      return null;
    }

    // Not onboarded and not in onboarding flow - start onboarding
    print('🔄 Router - Starting onboarding flow');
    return '/onboarding';
  } catch (error) {
    print('❌ Router - Error in onboarding flow: $error');
    return '/onboarding';
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // ✅ CRITICAL: Watch the auto-fetch provider to ensure it's triggered
  ref.watch(autoFetchCurrentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterRefreshStream(ref),
    redirect: (context, state) async {
      final authState = ref.read(authNotifierProvider);
      final userAsyncValue = ref.read(userProvider);
      final onboardingManager = ref.read(onboardingManagerProvider);

      final isInitialized = authState.status != AuthStatus.unknown;
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.matchedLocation;

      print(
        '🔄 Router - Path: $currentPath, Auth: $isAuthenticated, Initialized: $isInitialized',
      );
      print('🔄 Router - User state: ${userAsyncValue.toString()}');

      // Never redirect away from splash screen if not initialized
      if (currentPath == '/splash' && !isInitialized) {
        print('🔄 Router - Staying on splash (not initialized yet)');
        return null;
      }

      // Redirect to splash if not initialized
      if (!isInitialized && currentPath != '/splash') {
        print('🔄 Router - Redirecting to splash (not initialized)');
        return '/splash';
      }

      // Handle authenticated users
      if (isAuthenticated && isInitialized) {
        // ✅ UPDATED: Better handling with null checking
        return userAsyncValue.when(
          data: (userResponse) async {
            // Debug logging
            print('🔄 Router - Current path: $currentPath');
            print(
              '🔄 Router - User onboarded status: ${userResponse?.data?.onboarded}',
            );
            print(
              '🔄 Router - Full user data: ${userResponse?.data?.toJson()}',
            );

            final isUserOnboarded = userResponse?.data?.onboarded ?? false;

            // If user is onboarded, they should never see onboarding screens
            if (isUserOnboarded) {
              print('🔄 Router - User is onboarded, checking current path');

              // List of onboarding screens
              final onboardingScreens = [
                '/onboarding',
                '/phone-input',
                '/prep-done',
                '/personal-info-input',
              ];

              // If on any onboarding screen but user is onboarded, redirect to main app
              if (onboardingScreens.contains(currentPath)) {
                print(
                  '🔄 Router - Redirecting onboarded user from onboarding to navigation',
                );
                return '/navigation';
              }

              // If already on a main app screen, stay there
              print(
                '🔄 Router - User is onboarded and on valid screen, staying put',
              );
              return null;
            }

            // If not onboarded, handle onboarding flow
            print('🔄 Router - User not onboarded, checking onboarding flow');
            return await _handleOnboardingFlow(
              currentPath,
              onboardingManager,
              isUserOnboarded,
              ref,
            );
          },
          loading: () {
            print('🔄 Router - User data still loading...');

            // If we're authenticated but user data is loading, stay on splash
            // unless we're already in the app flow
            final appPaths = [
              '/navigation',
              '/home',
              '/onboarding',
              '/phone-input',
              '/prep-done',
            ];
            if (appPaths.contains(currentPath)) {
              print('🔄 Router - User in app flow while loading, staying put');
              return null;
            }

            // For auth screens while loading, redirect to splash to wait
            final authScreens = ['/login', '/register', '/welcome'];
            if (authScreens.contains(currentPath)) {
              print('🔄 Router - User data loading, staying on splash');
              return '/splash';
            }

            return null;
          },
          error: (error, stackTrace) {
            print('🔄 Router - User provider error: $error');
            // On error fetching user data, try to refresh
            Future.microtask(() {
              print('🔄 Router - Attempting to refresh user data after error');
              ref.read(userProvider.notifier).getCurrentUserProfile();
            });

            // 🔧 UPDATED: On error, assume not onboarded (false) and handle accordingly
            print('🔄 Router - API error, treating as not onboarded');
            return _handleOnboardingFlow(
              currentPath,
              onboardingManager,
              false, // Treat error as not onboarded
              ref,
            );
          },
        );
      }

      // Handle unauthenticated users - redirect protected routes to login
      if (!isAuthenticated && isInitialized) {
        final protectedPaths = [
          '/navigation',
          '/home',
          '/onboarding',
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
          (path) => currentPath == path || currentPath.startsWith('$path/'),
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

      // Password Reset Flow Routes
      GoRoute(
        path: '/password-reset',
        name: 'password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: '/password-reset-new',
        name: 'password-reset-new',
        builder: (context, state) {
          final email = state.extra as String;
          return PasswordResetNewPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/password-reset-confirm',
        name: 'password-reset-confirm',
        builder: (context, state) {
          final resetData = state.extra as Map<String, String>;
          return PasswordResetConfirmScreen(resetData: resetData);
        },
      ),
      GoRoute(
        path: '/password-reset-otp',
        name: 'password-reset-otp',
        builder: (context, state) {
          final resetData = state.extra as Map<String, String>;
          return PasswordResetOTPScreen(resetData: resetData);
        },
      ),
      GoRoute(
        path: '/password-reset-success',
        name: 'password-reset-success',
        builder: (context, state) {
          return PasswordResetSuccessScreen();
        },
      ),

      // Onboarding and main app routes
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const PersonalInfoInputScreen(),
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

// ✅ Complete RouterRefreshStream with proper null handling
class RouterRefreshStream extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription _authSubscription;
  late final ProviderSubscription _userSubscription;

  RouterRefreshStream(this._ref) {
    // Listen to auth state changes
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

      // Also trigger on authentication state changes
      if (previous?.isAuthenticated != next.isAuthenticated) {
        print(
          '🔄 Router - Auth authenticated changed: ${previous?.isAuthenticated} -> ${next.isAuthenticated}',
        );
        notifyListeners();
      }
    });

    // Listen to user provider changes
    _userSubscription = _ref.listen<AsyncValue<UserResponse?>>(userProvider, (
      previous,
      next,
    ) {
      print('🔄 Router - User provider state changed');
      print('  Previous: ${previous?.toString()}');
      print('  Next: ${next?.toString()}');

      final previousOnboarded = _safeGetOnboardedStatus(previous);
      final nextOnboarded = _safeGetOnboardedStatus(next);

      // 🔧 IMPORTANT: Also trigger when value changes from null to false or vice versa
      if (previousOnboarded != nextOnboarded) {
        print(
          '🔄 Router - User onboarded status changed: $previousOnboarded -> $nextOnboarded',
        );
        notifyListeners();
      }

      // Also trigger on state type changes (loading -> data, error -> data, etc.)
      final previousHasData =
          previous?.maybeWhen(
            data: (response) => response?.data != null,
            orElse: () => false,
          ) ??
          false;

      final nextHasData = next.maybeWhen(
        data: (response) => response?.data != null,
        orElse: () => false,
      );

      if (previousHasData != nextHasData) {
        print(
          '🔄 Router - User data availability changed: $previousHasData -> $nextHasData',
        );
        notifyListeners();
      }
    });
  }

  // ✅ Updated method with proper null handling
  bool? _safeGetOnboardedStatus(AsyncValue<UserResponse?>? asyncValue) {
    if (asyncValue == null) return null;

    return asyncValue.when(
      data: (response) {
        final onboarded = response?.data?.onboarded;

        // 🔧 IMPORTANT: Log both the raw value and the treated value
        print('🔄 Router - Raw onboarded value from API: $onboarded');

        // Treat null as false for routing decisions
        final treatedValue = onboarded ?? false;
        print(
          '🔄 Router - Treated onboarded status (null=false): $treatedValue',
        );

        return treatedValue;
      },
      loading: () {
        print('🔄 Router - User state is loading, onboarded status unknown');
        return null;
      },
      error: (error, stackTrace) {
        print(
          '🔄 Router - User state error, returning false for onboarded status: $error',
        );
        return false; // Treat errors as not onboarded
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
