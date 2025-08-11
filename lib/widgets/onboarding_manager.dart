// lib/services/onboarding_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingManager {
  static const String _lastOnboardingPromptKey = 'last_onboarding_prompt';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  // Check if we should show onboarding screen
  Future<bool> shouldShowOnboarding({
    required bool isUserOnboarded,
    bool forceCheck = false,
  }) async {
    print('🔍 OnboardingManager - Checking if should show onboarding');
    print('🔍 OnboardingManager - User onboarded status: $isUserOnboarded');

    // If user is fully onboarded, never show onboarding screens
    if (isUserOnboarded) {
      print('✅ OnboardingManager - User is onboarded, not showing onboarding');
      return false;
    }

    // If forcing check (like app restart), always respect the once-per-day logic
    if (!forceCheck) {
      final prefs = await SharedPreferences.getInstance();
      final lastPrompt = prefs.getString(_lastOnboardingPromptKey);

      if (lastPrompt != null) {
        final lastPromptDate = DateTime.parse(lastPrompt);
        final now = DateTime.now();
        final daysSinceLastPrompt = now.difference(lastPromptDate).inDays;

        print('🔍 OnboardingManager - Last prompt: $lastPromptDate');
        print(
          '🔍 OnboardingManager - Days since last prompt: $daysSinceLastPrompt',
        );

        // Only show once per day
        if (daysSinceLastPrompt < 1) {
          print('⏭️ OnboardingManager - Already shown today, skipping');
          return false;
        }
      }
    }

    print('✅ OnboardingManager - Should show onboarding');
    return true;
  }

  // Mark that we've shown the onboarding prompt today
  Future<void> markOnboardingPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastOnboardingPromptKey,
      DateTime.now().toIso8601String(),
    );
    print('📅 OnboardingManager - Marked onboarding prompt as shown today');
  }

  // Mark onboarding as completed (when user finishes the flow)
  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
    print('✅ OnboardingManager - Marked onboarding as completed');
  }

  // Check if user has ever completed onboarding (local storage)
  Future<bool> hasCompletedOnboardingLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  // Clear onboarding data (for testing or logout)
  Future<void> clearOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastOnboardingPromptKey);
    await prefs.remove(_hasCompletedOnboardingKey);
    print('🧹 OnboardingManager - Cleared onboarding data');
  }

  // Get days since last onboarding prompt
  Future<int> daysSinceLastPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPrompt = prefs.getString(_lastOnboardingPromptKey);

    if (lastPrompt == null) return -1; // Never shown

    final lastPromptDate = DateTime.parse(lastPrompt);
    final now = DateTime.now();
    return now.difference(lastPromptDate).inDays;
  }

  // Mark personal info step as completed (for tracking progress)
  Future<void> markPersonalInfoCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('personal_info_completed', true);
  }
}

// Provider for OnboardingManager
final onboardingManagerProvider = Provider<OnboardingManager>((ref) {
  return OnboardingManager();
});

// Provider to check if onboarding should be shown
final shouldShowOnboardingProvider = FutureProvider.family<bool, bool>((
  ref,
  isUserOnboarded,
) async {
  final onboardingManager = ref.read(onboardingManagerProvider);
  return await onboardingManager.shouldShowOnboarding(
    isUserOnboarded: isUserOnboarded,
  );
});
