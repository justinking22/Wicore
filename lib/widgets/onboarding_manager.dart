// lib/widgets/onboarding_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingManager {
  // 🔧 SIMPLIFIED: Only check API for onboarding status - no daily limits
  Future<bool> shouldShowOnboarding({required bool isUserOnboarded}) async {
    print(
      '🔍 OnboardingManager - Checking if should show onboarding (API-only)',
    );
    print(
      '🔍 OnboardingManager - User onboarded status from API: $isUserOnboarded',
    );

    // 🎯 SIMPLE LOGIC: If user is onboarded in API, don't show onboarding
    if (isUserOnboarded) {
      print(
        '✅ OnboardingManager - User is onboarded in API, not showing onboarding',
      );
      return false;
    }

    // 🎯 If not onboarded (or null treated as false), show onboarding
    print('✅ OnboardingManager - User not onboarded, should show onboarding');
    return true;
  }

  // 🔧 REMOVED: No more daily prompt tracking - always check API
  Future<void> markOnboardingPromptShown() async {
    print('📅 OnboardingManager - No daily tracking, always check API');
    // This method is kept for compatibility but does nothing
  }

  // Mark as completed (for local tracking only)
  Future<void> markOnboardingCompleted() async {
    print(
      '✅ OnboardingManager - Onboarding completed (API will be updated separately)',
    );
    // Note: The actual onboarded status is managed via API calls in the screens
  }

  // Clear onboarding data (for testing or logout)
  Future<void> clearOnboardingData() async {
    print(
      '🧹 OnboardingManager - No local data to clear, everything is API-based',
    );
    // This method is kept for compatibility but does nothing since we're API-only
  }

  // Get days since last onboarding prompt (not used anymore)
  Future<int> daysSinceLastPrompt() async {
    print('🔍 OnboardingManager - No daily tracking, returning -1');
    return -1; // Not applicable since we check API every time
  }

  // Mark personal info step as completed (for tracking progress)
  Future<void> markPersonalInfoCompleted() async {
    print('✅ OnboardingManager - Marked personal info step as completed');
    // This is just for internal progress tracking
  }
}

// Provider for OnboardingManager
final onboardingManagerProvider = Provider<OnboardingManager>((ref) {
  return OnboardingManager();
});

// 🔧 SIMPLIFIED: Provider to check if onboarding should be shown (API-only)
final shouldShowOnboardingProvider = FutureProvider.family<bool, bool>((
  ref,
  isUserOnboarded,
) async {
  final onboardingManager = ref.read(onboardingManagerProvider);
  return await onboardingManager.shouldShowOnboarding(
    isUserOnboarded: isUserOnboarded,
  );
});
