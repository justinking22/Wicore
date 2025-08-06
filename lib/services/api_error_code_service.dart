/// API Error Codes Constants
/// Defines all possible error codes returned by the API
class ApiErrorCode {
  // Internal Server Errors
  static const int internalServerError = -1;
  static const int dataIsNull = -2;
  static const int dbApiError = -3;
  static const int dataIsInvalid = -4;
  static const int dataHaveNoRequiredAtt = -5;
  static const int dataHaveExclusiveAtt = -6;
  static const int invalidDate = -7;

  // Permission Errors
  static const int permissionInvalid = -21;
  static const int permissionNotMaster = -22;
  static const int permissionCannotMatchPlace = -23;

  // Token Errors
  static const int tokenExpired = -31;
  static const int tokenInvalid = -32;

  // Link Errors
  static const int linkNotMatchedType = -51;

  // Device Communication Errors
  static const int deviceCannotCom = -100;
  static const int deviceNotConnected = -101;
  static const int deviceActionTimeout = -102;
  static const int deviceControlError = -103;
  static const int deviceInvalid = -104;
  static const int firmwareInvalid = -105;
  static const int deviceAlreadyPaired = -106;

  // User Errors
  static const int userInvalid = -121;
  static const int userNameExist = -122;
  static const int userNameAlreadyExist = -123;
  static const int incorrectUsernameOrPassword = -124;
  static const int userNotConfirmed = -125;
  static const int expiredVerificationCode = -126;
  static const int invalidVerificationCode = -127;
  static const int invalidPassword = -128;
  static const int invalidParameter = -129;

  // Batch Errors
  static const int noActiveTestBatch = -201;

  // Success Code
  static const int apiSuccess = 0;

  /// Get human-readable error message for the given error code
  static String getErrorMessage(int errorCode) {
    switch (errorCode) {
      // Internal Server Errors
      case internalServerError:
        return 'Internal server error occurred';
      case dataIsNull:
        return 'Required data is missing';
      case dbApiError:
        return 'Database API error';
      case dataIsInvalid:
        return 'Data is invalid';
      case dataHaveNoRequiredAtt:
        return 'Data missing required attributes';
      case dataHaveExclusiveAtt:
        return 'Data has exclusive attributes conflict';
      case invalidDate:
        return 'Invalid date format';

      // Permission Errors
      case permissionInvalid:
        return 'You don\'t have permission';
      case permissionNotMaster:
        return 'You don\'t have master permission';
      case permissionCannotMatchPlace:
        return 'Place is not matched';

      // Token Errors
      case tokenExpired:
        return 'Authentication token expired';
      case tokenInvalid:
        return 'Authentication token invalid';

      // Link Errors
      case linkNotMatchedType:
        return 'Link type mismatch';

      // Device Communication Errors
      case deviceCannotCom:
        return 'Device communication error';
      case deviceNotConnected:
        return 'Device not connected';
      case deviceActionTimeout:
        return 'Device action timed out';
      case deviceControlError:
        return 'Device control error';
      case deviceInvalid:
        return 'Device does not exist';
      case firmwareInvalid:
        return 'Firmware does not exist';
      case deviceAlreadyPaired:
        return 'Device already paired';

      // User Errors
      case userInvalid:
        return 'General user error';
      case userNameExist:
        return 'Username does not exist';
      case userNameAlreadyExist:
        return 'Username already exists';
      case incorrectUsernameOrPassword:
        return 'Incorrect username or password';
      case userNotConfirmed:
        return 'Email has not been confirmed';
      case expiredVerificationCode:
        return 'Verification code expired';
      case invalidVerificationCode:
        return 'Invalid verification code';
      case invalidPassword:
        return 'Password policy violation';
      case invalidParameter:
        return 'Parameter does not meet requirements';

      // Batch Errors
      case noActiveTestBatch:
        return 'No active batch';

      // Success
      case apiSuccess:
        return 'Success';

      default:
        return 'Unknown error occurred';
    }
  }

  /// Check if the error code represents a user-related error
  static bool isUserError(int errorCode) {
    return errorCode >= -129 && errorCode <= -121;
  }

  /// Check if the error code represents a device-related error
  static bool isDeviceError(int errorCode) {
    return errorCode >= -106 && errorCode <= -100;
  }

  /// Check if the error code represents a permission-related error
  static bool isPermissionError(int errorCode) {
    return errorCode >= -23 && errorCode <= -21;
  }

  /// Check if the error code represents a token-related error
  static bool isTokenError(int errorCode) {
    return errorCode >= -32 && errorCode <= -31;
  }

  /// Check if the error code indicates success
  static bool isSuccess(int errorCode) {
    return errorCode == apiSuccess;
  }
}

/// Extension to add error handling methods to int
extension ApiErrorCodeExtension on int {
  String get errorMessage => ApiErrorCode.getErrorMessage(this);
  bool get isSuccess => ApiErrorCode.isSuccess(this);
  bool get isUserError => ApiErrorCode.isUserError(this);
  bool get isDeviceError => ApiErrorCode.isDeviceError(this);
  bool get isPermissionError => ApiErrorCode.isPermissionError(this);
  bool get isTokenError => ApiErrorCode.isTokenError(this);
}

/// Custom exception class for API errors with error codes
class ApiException implements Exception {
  final int code;
  final String message;
  final dynamic originalError;

  const ApiException({
    required this.code,
    required this.message,
    this.originalError,
  });

  bool get isSuccess => code.isSuccess;
  bool get isUserError => code.isUserError;
  bool get isDeviceError => code.isDeviceError;
  bool get isPermissionError => code.isPermissionError;
  bool get isTokenError => code.isTokenError;

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}
