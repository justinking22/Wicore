import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/repository/user_repository.dart';
import 'package:Wicore/utilities/sign_up_form_state.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

// JWT Token Helper for decoding ID tokens
class JWTTokenHelper {
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JWT token: $e');
      return null;
    }
  }

  static String? extractEmail(String idToken) {
    final payload = decodePayload(idToken);
    return payload?['email'] as String?;
  }

  static String? extractName(String idToken) {
    final payload = decodePayload(idToken);
    return payload?['name'] as String? ?? payload?['given_name'] as String?;
  }

  static DateTime? extractExpiry(String token) {
    final payload = decodePayload(token);
    final exp = payload?['exp'] as int?;
    if (exp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  bool _isAutoLogin = true;
  bool _isObscureText = true;
  bool _hasEmailError = false;
  String _emailErrorMessage = '';
  bool _isLoading = false;
  bool _isSocialLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() {
        _hasEmailError = true;
        _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
      });
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      setState(() {
        _hasEmailError = true;
        _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
      });
    } else {
      setState(() {
        _hasEmailError = false;
        _emailErrorMessage = '';
      });
    }
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
      ),
    );
  }

  Future<void> _updateUserProfileAfterLogin() async {
    try {
      final signUpForm = ref.read(signUpFormProvider);

      if (signUpForm.name.isNotEmpty) {
        print(
          'Login successful, updating profile with stored name: ${signUpForm.name}',
        );

        await Future.delayed(const Duration(milliseconds: 300));

        await ref
            .read(userProvider.notifier)
            .updateCurrentUserProfile(
              UserUpdateRequest(firstName: signUpForm.name),
            );

        print('User profile updated with name after login');

        ref.read(signUpFormProvider.notifier).reset();

        if (mounted) {
          _showMessage('프로필이 업데이트되었습니다!', backgroundColor: Colors.green);
        }
      }
    } catch (e) {
      print('Failed to update profile after login: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);

      final result = await authNotifier.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result.isSuccess) {
          if (_isAutoLogin) {
            print('Auto-login enabled for user');
          }

          await _updateUserProfileAfterLogin();

          _showMessage('로그인 성공!', backgroundColor: Colors.green);
          context.go('/navigation');
        } else if (result.data?.accessToken == null) {
          setState(() {
            _hasEmailError = true;
            _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
          });
        } else {
          if (result.message.contains('invalid') == true ||
              result.message.contains('incorrect') == true ||
              result.message.contains('wrong') == true) {
            setState(() {
              _hasEmailError = true;
              _emailErrorMessage = '잘못된 이메일 또는 비밀번호입니다.';
            });
          } else {
            _showMessage(result.message ?? '로그인에 실패했습니다.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSocialLoginBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('로그인할 계정을\n선택해주세요', style: TextStyles.kBody),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          _isSocialLoading
                              ? null
                              : () {
                                Navigator.pop(context);
                                _handleGoogleLogin();
                              },
                      child: Container(
                        height: 147,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(12),
                          color:
                              _isSocialLoading
                                  ? Colors.grey[100]
                                  : Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://developers.google.com/identity/images/g-logo.png',
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isSocialLoading ? '로그인 중...' : '구글',
                              style: TextStyles.kLogo.copyWith(
                                color:
                                    _isSocialLoading
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          _isSocialLoading
                              ? null
                              : () {
                                Navigator.pop(context);
                                _handleAppleLogin();
                              },
                      child: Container(
                        height: 147,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(12),
                          color:
                              _isSocialLoading
                                  ? Colors.grey[100]
                                  : Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apple,
                              size: 48,
                              color:
                                  _isSocialLoading ? Colors.grey : Colors.black,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isSocialLoading ? '로그인 중...' : '애플',
                              style: TextStyles.kLogo.copyWith(
                                color:
                                    _isSocialLoading
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap:
                    _isSocialLoading
                        ? null
                        : () {
                          Navigator.pop(context);
                        },
                child: Center(
                  child: Text(
                    '로그인 없이 계속하기',
                    style: TextStyles.kTrailingBottomButtonWithUnderline
                        .copyWith(color: _isSocialLoading ? Colors.grey : null),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Enhanced social login success handler with correct JWT username extraction
  Future<void> _handleSocialLoginSuccess(
    CognitoAuthSession cognitoSession,
    String provider,
  ) async {
    try {
      final accessToken =
          cognitoSession.userPoolTokensResult.value?.accessToken;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;
      final refreshToken =
          cognitoSession.userPoolTokensResult.value?.refreshToken;

      if (accessToken == null || idToken == null || refreshToken == null) {
        throw Exception('Missing required tokens from $provider login');
      }

      // Extract user information from tokens - GET USERNAME VIA AMPLIFY
      final userSub =
          accessToken.userId; // This gives UUID (don't use for API calls)

      // Get username from Amplify current user
      String? jwtUsername;
      try {
        final user = await Amplify.Auth.getCurrentUser();
        jwtUsername = user.username;
        print('Amplify username: $jwtUsername');
      } catch (e) {
        print('Error getting username from Amplify: $e');

        // Fallback: manually decode JWT to extract username claim
        try {
          final parts = accessToken.raw.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalizedPayload = payload.padRight(
              (payload.length + 3) ~/ 4 * 4,
              '=',
            );
            final decoded = utf8.decode(base64Url.decode(normalizedPayload));
            final jsonPayload = json.decode(decoded) as Map<String, dynamic>;
            jwtUsername = jsonPayload['username'] as String?;
            print('JWT decoded username: $jwtUsername');
          }
        } catch (decodeError) {
          print('Error decoding JWT for username: $decodeError');
        }
      }

      if (jwtUsername == null) {
        throw Exception('Could not extract username from Amplify or JWT token');
      }

      print('JWT Token Analysis:');
      print('   JWT Username (use this): $jwtUsername');
      print('   JWT Sub (ignore this): $userSub');

      // Extract email and name from ID token
      String? email;
      String? name;

      try {
        email = JWTTokenHelper.extractEmail(idToken.raw);
        name = JWTTokenHelper.extractName(idToken.raw);
      } catch (e) {
        print('Could not extract user info from ID token: $e');
      }

      print('$provider login successful:');
      print('   User ID for API calls: $jwtUsername');
      print('   Email: $email');
      print('   Name: $name');

      // Step 1: Authenticate with your token management system using JWT username
      final authNotifier = ref.read(authNotifierProvider.notifier);

      final socialLoginResult = await authNotifier.signInWithSocial(
        provider: provider.toLowerCase(),
        accessToken: accessToken.raw,
        refreshToken: refreshToken,
        idToken: idToken.raw,
        userId: jwtUsername, // Use JWT username for API calls
        email: email,
      );

      if (!socialLoginResult.isSuccess) {
        throw Exception(
          socialLoginResult.message ?? 'Social login integration failed',
        );
      }

      print('$provider login integrated with token management system');

      // Step 2: Set up incognito user for social login
      if (email != null && name != null) {
        try {
          final userRepository = ref.read(userRepositoryProvider);
          final result = await userRepository.setupIncognitoUserForSocialLogin(
            email: email,
            firstName: name,
            provider: provider.toLowerCase(),
          );

          if (result.success) {
            print('Incognito user setup completed for social login');
            print('Incognito User ID: ${result.incognitoUserId}');
          } else {
            print('Warning: Failed to setup incognito user: ${result.message}');
          }
        } catch (e) {
          print('Warning: Failed to setup incognito user: $e');
          // Continue with login even if incognito setup fails
        }
      }

      if (mounted) {
        _showMessage('$provider 로그인 성공!', backgroundColor: Colors.green);
        context.go('/navigation');
      }
    } catch (e) {
      print('Error handling $provider login: $e');
      if (mounted) {
        _showMessage('$provider 로그인 처리 중 오류가 발생했습니다.');
      }
    }
  }

  /// Enhanced Google login with better error handling
  Future<void> _handleGoogleLogin() async {
    setState(() => _isSocialLoading = true);

    try {
      print('Starting Google login process...');

      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.google,
      );

      print('Google sign in result: ${result.isSignedIn}');

      if (result.isSignedIn) {
        // Wait a moment for session to be established
        await Future.delayed(const Duration(milliseconds: 500));

        final session = await Amplify.Auth.fetchAuthSession();
        print('Session fetched, isSignedIn: ${session.isSignedIn}');

        if (session is CognitoAuthSession && session.isSignedIn) {
          // Validate that we have the required tokens
          final tokens = session.userPoolTokensResult.value;
          if (tokens?.accessToken != null &&
              tokens?.idToken != null &&
              tokens?.refreshToken != null) {
            await _handleSocialLoginSuccess(session, 'Google');
          } else {
            throw Exception('Incomplete token set received from Google login');
          }
        } else {
          throw Exception('Invalid or incomplete session after Google login');
        }
      } else {
        throw Exception('Google login did not complete successfully');
      }
    } on AuthException catch (e) {
      print('Google login AuthException: ${e.message}');

      if (mounted) {
        String errorMessage = 'Google 로그인 오류가 발생했습니다.';

        if (e.message.toLowerCase().contains('cancelled') ||
            e.message.toLowerCase().contains('cancel')) {
          errorMessage = 'Google 로그인이 취소되었습니다.';
        } else if (e.message.toLowerCase().contains('network')) {
          errorMessage = '네트워크 오류로 Google 로그인에 실패했습니다.';
        }

        _showMessage(errorMessage);
      }
    } catch (e) {
      print('Unexpected Google login error: $e');
      if (mounted) {
        _showMessage('Google 로그인 중 예기치 못한 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSocialLoading = false);
      }
    }
  }

  /// Enhanced Apple login with better error handling
  Future<void> _handleAppleLogin() async {
    setState(() => _isSocialLoading = true);

    try {
      print('Starting Apple login process...');

      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.apple,
      );

      print('Apple sign in result: ${result.isSignedIn}');

      if (result.isSignedIn) {
        // Wait a moment for session to be established
        await Future.delayed(const Duration(milliseconds: 500));

        final session = await Amplify.Auth.fetchAuthSession();
        print('Session fetched, isSignedIn: ${session.isSignedIn}');

        if (session is CognitoAuthSession && session.isSignedIn) {
          // Validate that we have the required tokens
          final tokens = session.userPoolTokensResult.value;
          if (tokens?.accessToken != null &&
              tokens?.idToken != null &&
              tokens?.refreshToken != null) {
            await _handleSocialLoginSuccess(session, 'Apple');
          } else {
            throw Exception('Incomplete token set received from Apple login');
          }
        } else {
          throw Exception('Invalid or incomplete session after Apple login');
        }
      } else {
        throw Exception('Apple login did not complete successfully');
      }
    } on AuthException catch (e) {
      print('Apple login AuthException: ${e.message}');

      if (mounted) {
        String errorMessage = 'Apple 로그인 오류가 발생했습니다.';

        if (e.message.toLowerCase().contains('cancelled') ||
            e.message.toLowerCase().contains('cancel')) {
          errorMessage = 'Apple 로그인이 취소되었습니다.';
        } else if (e.message.toLowerCase().contains('network')) {
          errorMessage = '네트워크 오류로 Apple 로그인에 실패했습니다.';
        }

        _showMessage(errorMessage);
      }
    } catch (e) {
      print('Unexpected Apple login error: $e');
      if (mounted) {
        _showMessage('Apple 로그인 중 예기치 못한 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSocialLoading = false);
      }
    }
  }

  Future<void> readAuthSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();

      // Основная информация о сессии
      print('Is signed in: ${session.isSignedIn}');

      // Приведение к CognitoAuthSession для доступа к токенам
      if (session is CognitoAuthSession) {
        final cognitoSession = session;

        // Проверяем токены
        final accessToken =
            cognitoSession.userPoolTokensResult.value?.accessToken;
        final idToken = cognitoSession.userPoolTokensResult.value?.idToken;
        final refreshToken =
            cognitoSession.userPoolTokensResult.value?.refreshToken;

        print('Access Token: ${accessToken?.raw}');
        print('ID Token: ${idToken?.raw}');
        // print('Refresh Token: ${refreshToken?.raw}');

        // Информация из токенов
        print('User Sub: ${accessToken?.userId}');
        // print('Username: ${accessToken?.username}');
        print('Token Use: ${accessToken?.tokenUse}');

        // AWS Credentials (если нужны)
        final awsCredentials = cognitoSession.credentialsResult.value;
        print('AWS Access Key: ${awsCredentials?.accessKeyId}');
        print('AWS Secret Key: ${awsCredentials?.secretAccessKey}');
        print('Session Token: ${awsCredentials?.sessionToken}');
      }
    } on AuthException catch (e) {
      print('Error reading auth session: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        context.go('/navigation');
      }
    });

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final availableHeight = screenHeight - keyboardHeight;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0, // Add this line
          surfaceTintColor: Colors.transparent, // Add this line too
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed:
                    (_isLoading || _isSocialLoading)
                        ? null
                        : () {
                          context.push('/welcome');
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.limeGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('회원가입', style: TextStyles.kRegular),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    availableHeight -
                    (MediaQuery.of(context).padding.top + kToolbarHeight),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isKeyboardVisible ? 20 : 40),

                      Text('반갑습니다\n로그인을 해주세요', style: TextStyles.kBody),

                      SizedBox(height: isKeyboardVisible ? 16 : 32),

                      if (_hasEmailError)
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _emailErrorMessage,
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 14,
                            ),
                          ),
                        ),

                      SizedBox(
                        height:
                            _hasEmailError
                                ? (isKeyboardVisible ? 16 : 24)
                                : (isKeyboardVisible ? 32 : 80),
                      ),

                      // Email Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('이메일', style: TextStyles.kSemiBold),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading && !_isSocialLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: '이메일주소를 입력해주세요',
                              hintStyle: TextStyles.kMedium,
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: CustomColors.darkCharcoal,
                                  width: 2,
                                ),
                              ),
                              errorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              disabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFBDBDBD),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '이메일을 입력해주세요';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return '유효한 이메일 주소를 입력해주세요';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (!_isLoading && !_isSocialLoading) {
                                _validateEmail(value);
                              }
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: isKeyboardVisible ? 24 : 32),

                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('비밀번호', style: TextStyles.kSemiBold),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading && !_isSocialLoading,
                            obscureText: _isObscureText,
                            decoration: InputDecoration(
                              hintText: '비밀번호를 입력해주세요',
                              hintStyle: TextStyles.kMedium,
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: CustomColors.darkCharcoal,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              disabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFBDBDBD),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              suffixIcon: TextButton(
                                onPressed:
                                    (_isLoading || _isSocialLoading)
                                        ? null
                                        : () {
                                          setState(() {
                                            _isObscureText = !_isObscureText;
                                          });
                                        },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isObscureText ? '보기' : '숨기기',
                                  style: TextStyles.kMedium.copyWith(
                                    color:
                                        (_isLoading || _isSocialLoading)
                                            ? Colors.grey
                                            : CustomColors.darkCharcoal,
                                  ),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '비밀번호를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: isKeyboardVisible ? 16 : 24),

                      // Auto Login and Password Reset
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 32,
                                width: 32,
                                child: Checkbox(
                                  value: _isAutoLogin,
                                  onChanged:
                                      (_isLoading || _isSocialLoading)
                                          ? null
                                          : (value) {
                                            setState(() {
                                              _isAutoLogin = value ?? false;
                                            });
                                          },
                                  activeColor: CustomColors.darkCharcoal,
                                  checkColor: CustomColors.limeGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                              ),
                              Text(
                                '자동로그인',
                                style: TextStyles.kRegular.copyWith(
                                  color:
                                      (_isLoading || _isSocialLoading)
                                          ? Colors.grey
                                          : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed:
                                (_isLoading || _isSocialLoading)
                                    ? null
                                    : () {
                                      context.push('/password-reset');
                                    },
                            child: Text(
                              '비밀번호 재설정',
                              style: TextStyles
                                  .kTrailingBottomButtonWithUnderline
                                  .copyWith(
                                    color:
                                        (_isLoading || _isSocialLoading)
                                            ? Colors.grey
                                            : null,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: isKeyboardVisible ? 20 : availableHeight - 600,
                      ),

                      // Social Login Link
                      Center(
                        child: TextButton(
                          onPressed:
                              (_isLoading || _isSocialLoading)
                                  ? null
                                  : _showSocialLoginBottomSheet,
                          child: Text(
                            _isSocialLoading
                                ? '소셜 로그인 처리 중...'
                                : '구글 또는 애플아이디로 로그인하기',
                            style: TextStyles.kTrailingBottomButtonWithUnderline
                                .copyWith(
                                  color:
                                      (_isLoading || _isSocialLoading)
                                          ? Colors.grey
                                          : null,
                                ),
                          ),
                        ),
                      ),

                      SizedBox(height: isKeyboardVisible ? 8 : 16),

                      // Login Button
                      CustomButton(
                        text:
                            _isLoading
                                ? '로그인 중...'
                                : _isSocialLoading
                                ? '소셜 로그인 처리 중...'
                                : '로그인',
                        onPressed:
                            (_isLoading || _isSocialLoading)
                                ? null
                                : _handleLogin,
                        isEnabled:
                            _emailController.text.isNotEmpty &&
                            _passwordController.text.isNotEmpty &&
                            !_isLoading &&
                            !_isSocialLoading,
                        backgroundColor: Colors.black,
                        disabledBackgroundColor: const Color(0xFFBDBDBD),
                        disabledTextColor: Colors.white,
                      ),

                      SizedBox(
                        height: isKeyboardVisible ? keyboardHeight + 20 : 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
