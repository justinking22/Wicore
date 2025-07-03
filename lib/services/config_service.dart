import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  Map<String, dynamic>? _configData;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  
  // Load and parse the Amplify configuration file
  Future<void> loadConfig() async {
    if (_isLoaded) return;
    
    try {
      final configString = await rootBundle.loadString('assets/amplifyconfiguration.json');
      _configData = json.decode(configString);
      _isLoaded = true;
      debugPrint('Configuration loaded successfully');
    } catch (e) {
      debugPrint('Error loading configuration: $e');
      rethrow;
    }
  }

  // Get the API endpoint URL for the specified API name
  String? getApiEndpoint(String apiName) {
    if (!_isLoaded || _configData == null) {
      throw Exception('Configuration not loaded');
    }
    
    try {
      final apiConfig = _configData!['api']['plugins']['awsAPIPlugin'][apiName];
      if (apiConfig != null && apiConfig['endpoint'] != null) {
        return apiConfig['endpoint'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting API endpoint for $apiName: $e');
      return null;
    }
  }
  
  // Get all available API names
  List<String> getAvailableApiNames() {
    if (!_isLoaded || _configData == null) {
      throw Exception('Configuration not loaded');
    }
    
    try {
      final Map<String, dynamic> apis = _configData!['api']['plugins']['awsAPIPlugin'];
      return apis.keys.toList();
    } catch (e) {
      debugPrint('Error getting API names: $e');
      return [];
    }
  }
  
  // Get Cognito User Pool information
  Map<String, dynamic>? getCognitoUserPoolInfo() {
    if (!_isLoaded || _configData == null) {
      throw Exception('Configuration not loaded');
    }
    
    try {
      return _configData!['auth']['plugins']['awsCognitoAuthPlugin']['CognitoUserPool']['Default'];
    } catch (e) {
      debugPrint('Error getting Cognito User Pool info: $e');
      return null;
    }
  }
  
  // Get the primary API endpoint from the configuration
  String? getPrimaryApiEndpoint() {
    if (!_isLoaded || _configData == null) {
      throw Exception('Configuration not loaded');
    }
    
    try {


         final deviceApi = getApiEndpoint('DeviceApi');
      if (deviceApi != null) {
        return deviceApi;
      }

      // First try to get the SoundApi endpoint as the primary
      final soundApi = getApiEndpoint('SoundApi');
      if (soundApi != null) {
        return soundApi;
      }
      
      // If SoundApi doesn't exist, try DeviceApi
   
      
      // If neither exists, get the first available API endpoint
      final apiNames = getAvailableApiNames();
      if (apiNames.isNotEmpty) {
        return getApiEndpoint(apiNames.first);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting primary API endpoint: $e');
      return null;
    }
  }
  
  // Get raw config data (useful for debugging)
  Map<String, dynamic>? getRawConfig() {
    return _isLoaded ? _configData : null;
  }
}