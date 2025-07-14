import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:with_force/app_router.dart';
import 'package:with_force/providers/auth_provider.dart';
import 'package:with_force/providers/sign_up_provider.dart';

import 'services/config_service.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isConfiguring = true;
  bool _configurationSuccess = false;
  String? _apiBaseUrl;
  final _configService = ConfigService();
  AuthService? _authService;

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
        _isConfiguring = false;
        _configurationSuccess = true;
      });
    } catch (e) {
      debugPrint('❌ Error initializing app: $e');
      setState(() {
        _isConfiguring = false;
        _configurationSuccess = false;
      });
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
    if (_isConfiguring) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading configuration...'),
              ],
            ),
          ),
        ),
      );
    }

    if (!_configurationSuccess || _apiBaseUrl == null || _authService == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to configure application'),
                const SizedBox(height: 8),
                Text(
                  _apiBaseUrl == null
                      ? 'No API endpoint found in configuration'
                      : 'Error configuring Amplify',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isConfiguring = true;
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
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
