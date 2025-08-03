class AppInitializationState {
  final bool isInitialized;
  final bool initializationSuccess;
  final String? apiBaseUrl;
  final String? errorMessage;

  const AppInitializationState({
    this.isInitialized = false,
    this.initializationSuccess = false,
    this.apiBaseUrl,
    this.errorMessage,
  });

  AppInitializationState copyWith({
    bool? isInitialized,
    bool? initializationSuccess,
    String? apiBaseUrl,
    String? errorMessage,
  }) {
    return AppInitializationState(
      isInitialized: isInitialized ?? this.isInitialized,
      initializationSuccess:
          initializationSuccess ?? this.initializationSuccess,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      errorMessage: errorMessage,
    );
  }
}
