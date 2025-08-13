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

// ✅ Helper method for onboarding flow handling
Future<String?> _handleOnboardingFlow(
  String currentPath,
  dynamic onboardingManager,
  bool isUserOnboarded,
  Ref ref,
) async {
  try {
    print('🎯 Onboarding Flow - Starting onboarding flow handler');
    print('🎯 Onboarding Flow - Current path: $currentPath');
    print('🎯 Onboarding Flow - User onboarded status: $isUserOnboarded');

    // Check if we should show onboarding today
    final shouldShowOnboarding = await onboardingManager.shouldShowOnboarding(
      isUserOnboarded: isUserOnboarded,
    );

    print('🎯 Onboarding Flow - Should show onboarding: $shouldShowOnboarding');

    if (shouldShowOnboarding) {
      // Allow staying in onboarding flow
      final onboardingPaths = ['/onboarding', '/phone-input', '/prep-done'];

      if (onboardingPaths.contains(currentPath)) {
        print(
          '🎯 Onboarding Flow - User in onboarding flow, staying on current screen: $currentPath',
        );
        return null;
      }

      // Redirect to start of onboarding and mark as shown for today
      print(
        '🎯 Onboarding Flow - Starting onboarding flow, redirecting to /onboarding',
      );
      await onboardingManager.markOnboardingPromptShown();
      return '/onboarding';
    } else {
      // Already showed onboarding today, skip for now
      print(
        '🎯 Onboarding Flow - Skipping onboarding for today, going to main app',
      );

      // If user is currently on onboarding screens but we're not showing today, redirect to main
      final onboardingPaths = ['/onboarding', '/phone-input', '/prep-done'];
      if (onboardingPaths.contains(currentPath)) {
        print(
          '🎯 Onboarding Flow - User on onboarding screen but skipping today, redirecting to /navigation',
        );
        return '/navigation';
      }
    }

    print('🎯 Onboarding Flow - No redirect needed, returning null');
    return null;
  } catch (error) {
    print('🎯 Onboarding Flow - ERROR in onboarding flow: $error');
    // On error, default to showing onboarding
    print('🎯 Onboarding Flow - Defaulting to onboarding due to error');
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

      print('🔄 Router - ===== REDIRECT LOGIC START =====');
      print('🔄 Router - Path: $currentPath');
      print('🔄 Router - Auth Status: ${authState.status}');
      print('🔄 Router - Is Authenticated: $isAuthenticated');
      print('🔄 Router - Is Initialized: $isInitialized');
      print('🔄 Router - User state: ${userAsyncValue.toString()}');

      // Early redirect for /home to /navigation
      if (currentPath == '/home') {
        print('🔄 Router - Redirecting /home to /navigation');
        return '/navigation';
      }

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
        print(
          '🔄 Router - User is authenticated and initialized, processing user data...',
        );

        // ✅ IMPROVED: Better handling of user data loading states
        return userAsyncValue.when(
          data: (userResponse) {
            print('🔄 Router - User data loaded successfully');
            print('🔄 Router - User response: ${userResponse?.toString()}');

            // ✅ FIX: Treat null onboarded status as false (not onboarded)
            final onboardedValue = userResponse?.data?.onboarded;
            final isUserOnboarded = onboardedValue ?? false;

            print('🔄 Router - Raw onboarded value from API: $onboardedValue');
            print(
              '🔄 Router - Processed onboarded status (null treated as false): $isUserOnboarded',
            );
            print(
              '🔄 Router - Full user data: ${userResponse?.data?.toJson()}',
            );

            if (!isUserOnboarded) {
              print(
                '🔄 Router - User is NOT onboarded, handling onboarding flow...',
              );
              return _handleOnboardingFlow(
                currentPath,
                onboardingManager,
                isUserOnboarded,
                ref,
              );
            }

            print(
              '🔄 Router - User IS onboarded, proceeding with normal flow...',
            );

            // ✅ FIX: Handle splash screen for authenticated, onboarded users
            if (currentPath == '/splash') {
              print(
                '🔄 Router - Authenticated, onboarded user on splash, redirecting to navigation',
              );
              return '/navigation';
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

            // ✅ Allow staying on current screen if it's a valid app screen
            print('🔄 Router - User can stay on current screen: $currentPath');
            return null;
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
            print('🔄 Router - User provider ERROR: $error');
            print('🔄 Router - Stack trace: $stackTrace');

            // On error fetching user data, try to refresh
            Future.microtask(() {
              print('🔄 Router - Attempting to refresh user data after error');
              ref.read(userProvider.notifier).getCurrentUserProfile();
            });

            // For now, assume not onboarded and handle accordingly
            print('🔄 Router - Treating user as not onboarded due to error');
            return _handleOnboardingFlow(
              currentPath,
              onboardingManager,
              false, // Assume not onboarded on error
              ref,
            );
          },
        );
      }

      // Handle unauthenticated users - redirect protected routes to login
      if (!isAuthenticated && isInitialized) {
        print('🔄 Router - User is unauthenticated but initialized');

        final protectedPaths = [
          '/navigation',
          '/home',
          '/personal-info-input',
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
          print(
            '🔄 Router - Redirecting unauthenticated user from protected path to login',
          );
          return '/login';
        }

        print(
          '🔄 Router - Unauthenticated user on non-protected path, allowing',
        );
      }

      print('🔄 Router - ===== REDIRECT LOGIC END (no redirect) =====');
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) {
          print('🏗️ Building splash screen');
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) {
          print('🏗️ Building welcome screen');
          return WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/name-input',
        name: 'name-input',
        builder: (context, state) {
          print('🏗️ Building name input screen');
          return const NameInputScreen();
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          print('🏗️ Building login screen');
          return const SignInScreen();
        },
      ),
      GoRoute(
        path: '/email-input',
        name: 'email-input',
        builder: (context, state) {
          print('🏗️ Building email input screen');
          return const EmailInputScreen();
        },
      ),
      GoRoute(
        path: '/password-input',
        name: 'password-input',
        builder: (context, state) {
          print('🏗️ Building password input screen');
          return const PasswordInputScreen();
        },
      ),
      GoRoute(
        path: '/password-re-enter',
        name: 'password-re-enter',
        builder: (context, state) {
          print('🏗️ Building password re-enter screen');
          return const PasswordConfirmationScreen();
        },
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email-verification',
        builder: (context, state) {
          print('🏗️ Building email verification screen');
          return EmailVerificationScreen();
        },
      ),
      GoRoute(
        path: '/success-verification',
        name: 'success-verification',
        builder: (context, state) {
          print('🏗️ Building success verification screen');
          return const EmailVerificationSuccessScreen();
        },
      ),
      GoRoute(
        path: '/terms-and-conditions',
        name: 'terms-and-conditions',
        builder: (context, state) {
          print('🏗️ Building terms and conditions screen');
          return const TermsAgreementScreen();
        },
      ),
      GoRoute(
        path: '/sign-up-complete',
        name: 'sign-up-complete',
        builder: (context, state) {
          print('🏗️ Building sign up complete screen');
          return const SignupCompleteScreen();
        },
      ),

      // Password Reset Flow Routes
      GoRoute(
        path: '/password-reset',
        name: 'password-reset',
        builder: (context, state) {
          print('🏗️ Building password reset screen');
          return const PasswordResetScreen();
        },
      ),
      GoRoute(
        path: '/password-reset-new',
        name: 'password-reset-new',
        builder: (context, state) {
          print('🏗️ Building password reset new screen');
          final email = state.extra as String;
          return PasswordResetNewPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/password-reset-confirm',
        name: 'password-reset-confirm',
        builder: (context, state) {
          print('🏗️ Building password reset confirm screen');
          final resetData = state.extra as Map<String, String>;
          return PasswordResetConfirmScreen(resetData: resetData);
        },
      ),
      GoRoute(
        path: '/password-reset-otp',
        name: 'password-reset-otp',
        builder: (context, state) {
          print('🏗️ Building password reset OTP screen');
          final resetData = state.extra as Map<String, String>;
          return PasswordResetOTPScreen(resetData: resetData);
        },
      ),
      GoRoute(
        path: '/password-reset-success',
        name: 'password-reset-success',
        builder: (context, state) {
          print('🏗️ Building password reset success screen');
          return PasswordResetSuccessScreen();
        },
      ),

      // Onboarding and main app routes
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) {
          print('🎯 Building onboarding screen (PersonalInfoInputScreen)');
          try {
            final screen = PersonalInfoInputScreen();
            print('🎯 Onboarding screen created successfully');
            return screen;
          } catch (error) {
            print('🎯 ERROR creating onboarding screen: $error');
            rethrow;
          }
        },
      ),
      GoRoute(
        path: '/phone-input',
        name: 'phone-input',
        builder: (context, state) {
          print('🏗️ Building phone input screen');
          return PhoneInputScreen();
        },
      ),
      GoRoute(
        path: '/prep-done',
        name: 'prep-done',
        builder: (context, state) {
          print('🏗️ Building prep done screen');
          return const PrepDoneScreen();
        },
      ),
      GoRoute(
        path: '/navigation',
        name: 'navigation',
        builder: (context, state) {
          print('🏗️ Building main navigation screen');
          return const MainNavigation();
        },
      ),
      GoRoute(
        path: '/qr-scan-screen',
        builder: (context, state) {
          print('🏗️ Building QR scan screen');
          return Scaffold(
            body: QRScannerWidget(
              onQRScanned: (qrCode) {
                context.go('/home?qrResult=$qrCode');
              },
              onBackPressed: () {
                context.go('/home');
              },
            ),
          );
        },
      ),
      GoRoute(
        path: '/device-details',
        builder: (context, state) {
          print('🏗️ Building device details screen');
          final deviceId = state.uri.queryParameters['deviceId'] ?? 'UNKNOWN';
          return DeviceDetailsWidget(deviceId: deviceId);
        },
      ),
      GoRoute(
        path: '/calendar-screen',
        name: 'calendar-screen',
        builder: (context, state) {
          print('🏗️ Building calendar screen');
          return CalendarScreen();
        },
      ),
      GoRoute(
        path: '/device-history-screen',
        name: 'device-history-screen',
        builder: (context, state) {
          print('🏗️ Building device history screen');
          return DeviceHistoryScreen();
        },
      ),
      GoRoute(
        path: '/personal-info-display-screen',
        name: 'personal-info-display-screen',
        builder: (context, state) {
          print('🏗️ Building personal info display screen');
          return const PersonalInfoDisplayScreen();
        },
      ),
      GoRoute(
        path: '/notifications-settings',
        name: 'notifications-settings',
        builder: (context, state) {
          print('🏗️ Building notifications settings screen');
          return const NotificationSettingsScreen();
        },
      ),
      GoRoute(
        path: '/terms-of-use',
        name: 'terms-of-use',
        builder: (context, state) {
          print('🏗️ Building terms of use screen');
          return const TermsOfServiceScreen();
        },
      ),
      GoRoute(
        path: '/re-save-phone-number-screen',
        name: 're-save-phone-number-screen',
        builder: (context, state) {
          print('🏗️ Building re-save phone number screen');
          return ResavePhoneNumberScreen();
        },
      ),
      GoRoute(
        path: '/password-reset-confirmation-screen',
        name: 'password-reset-confirmation-screen',
        builder: (context, state) {
          print('🏗️ Building password reset confirmation screen');
          return PasswordResetConfirmationScreen();
        },
      ),
      GoRoute(
        path: '/date-stats-screen',
        name: 'date-stats-screen',
        builder: (context, state) {
          print('🏗️ Building date stats screen');
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
    errorBuilder: (context, state) {
      print('❌ Router ERROR - Path: ${state.matchedLocation}');
      print('❌ Router ERROR - Error: ${state.error}');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found: ${state.matchedLocation}'),
              const SizedBox(height: 8),
              Text('Error: ${state.error?.toString() ?? "Unknown error"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/navigation'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
  );
});

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

  bool? _safeGetOnboardedStatus(AsyncValue<UserResponse?>? asyncValue) {
    if (asyncValue == null) return null;

    return asyncValue.when(
      data: (response) {
        final onboarded = response?.data?.onboarded;
        print('🔄 Router - Extracted onboarded status: $onboarded');
        return onboarded;
      },
      loading: () {
        print('🔄 Router - User state is loading, onboarded status unknown');
        return null;
      },
      error: (error, stackTrace) {
        print(
          '🔄 Router - User state error, returning null for onboarded status: $error',
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
