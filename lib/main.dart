import 'package:Wicore/app_router.dart';
import 'package:Wicore/providers/auth_provider.dart';
import 'package:Wicore/providers/sign_up_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'services/config_service.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native splash screen visible
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const Wicore());
}

class Wicore extends StatefulWidget {
  const Wicore({Key? key}) : super(key: key);

  @override
  State<Wicore> createState() => _WicoreState();
}

class _WicoreState extends State<Wicore> {
  bool _isInitialized = false;
  bool _initializationSuccess = false;
  String? _apiBaseUrl;
  final _configService = ConfigService();
  AuthService? _authService;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // First load the configuration
      await _configService.loadConfig();

      // Get the API base URL from the configuration
      _apiBaseUrl = _configService.getPrimaryApiEndpoint();

      if (_apiBaseUrl == null) {
        throw Exception('No API endpoint found in configuration');
      }

      // Now configure Amplify
      await _configureAmplify();

      // Initialize AuthService
      _authService = AuthService(baseUrl: _apiBaseUrl!);

      // Initialize the auth service (check current auth state)
      debugPrint('🔄 Initializing AuthService...');
      await _authService!.init();
      debugPrint('✅ AuthService initialized successfully');

      setState(() {
        _isInitialized = true;
        _initializationSuccess = true;
      });
    } catch (e) {
      debugPrint('❌ Error initializing app: $e');
      setState(() {
        _isInitialized = true;
        _initializationSuccess = false;
        _errorMessage = e.toString();
      });
    } finally {
      // Remove the native splash screen once initialization is complete
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _configureAmplify() async {
    try {
      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/amplifyconfiguration.json',
      );

      // Add Amplify plugins
      final authPlugin = AmplifyAuthCognito();
      final apiPlugin = AmplifyAPI();

      await Amplify.addPlugins([authPlugin, apiPlugin]);

      // Configure Amplify
      await Amplify.configure(jsonString);

      debugPrint('✅ Amplify configured successfully');
    } catch (e) {
      debugPrint('❌ Error configuring Amplify: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing while initializing (native splash screen is visible)
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    // Show error screen if initialization failed
    if (!_initializationSuccess ||
        _apiBaseUrl == null ||
        _authService == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize application',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Unknown error occurred',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isInitialized = false;
                        _initializationSuccess = false;
                        _errorMessage = null;
                      });
                      // Show splash screen again
                      FlutterNativeSplash.preserve(
                        widgetsBinding: WidgetsBinding.instance,
                      );
                      _initializeApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Main app with GoRouter and multiple providers
    return MultiProvider(
      providers: [
        // Provide the AuthService
        ChangeNotifierProvider.value(value: _authService!),
        // Provide the SignUpProvider that depends on AuthService
        ChangeNotifierProxyProvider<AuthService, SignUpProvider>(
          create: (context) => SignUpProvider(_authService!),
          update:
              (context, authService, previous) =>
                  previous ?? SignUpProvider(authService),
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          final router = AppRouter.createRouter(authService);

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Wicore',
            theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
