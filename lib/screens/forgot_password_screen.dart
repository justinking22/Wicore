import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:with_force/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _confirmationCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  // Screen states
  ForgotPasswordStep _currentStep = ForgotPasswordStep.requestReset;

  @override
  void dispose() {
    _emailController.dispose();
    _confirmationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Check if we already have an email for reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.confirmationEmail != null) {
        setState(() {
          _emailController.text = authService.confirmationEmail!;
          _currentStep = ForgotPasswordStep.enterCode;
        });
      }
    });
  }

  // Step 1: Request password reset
  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final result = await authService.resetPassword(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _currentStep = ForgotPasswordStep.enterCode;
          });
          _showMessage('Reset code sent to your email', isSuccess: true);
        } else {
          _showMessage(result['message'] ?? 'Failed to send reset code');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Network error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Step 2: Verify code and reset password
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final result = await authService.confirmResetPassword(
        email: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmationCode: _confirmationCodeController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _currentStep = ForgotPasswordStep.success;
          });
          
          // Auto-navigate to login after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        } else {
          _showMessage(result['message'] ?? 'Failed to reset password');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Network error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Resend reset code
  Future<void> _resendResetCode() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final result = await authService.resendConfirmationCode(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        _showMessage(
          result['success'] 
              ? 'Reset code sent again' 
              : result['message'] ?? 'Failed to resend code',
          isSuccess: result['success'],
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Network error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildContent(),
                  const SizedBox(height: 32),
                  _buildActionButton(),
                  const SizedBox(height: 16),
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case ForgotPasswordStep.requestReset:
        return 'Forgot Password';
      case ForgotPasswordStep.enterCode:
        return 'Reset Password';
      case ForgotPasswordStep.success:
        return 'Success';
    }
  }

  Widget _buildHeader() {
    IconData icon;
    String title;
    String subtitle;
    Color iconColor;

    switch (_currentStep) {
      case ForgotPasswordStep.requestReset:
        icon = Icons.lock_open;
        title = 'Forgot Your Password?';
        subtitle = 'Enter your email address and we\'ll send you a reset code';
        iconColor = Theme.of(context).primaryColor;
        break;
      case ForgotPasswordStep.enterCode:
        icon = Icons.security;
        title = 'Reset Your Password';
        subtitle = 'Enter the code from your email and choose a new password';
        iconColor = Colors.orange;
        break;
      case ForgotPasswordStep.success:
        icon = Icons.check_circle;
        title = 'Password Reset Complete!';
        subtitle = 'Your password has been successfully reset. You can now sign in with your new password.';
        iconColor = Colors.green;
        break;
    }

    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            icon,
            size: 40,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case ForgotPasswordStep.requestReset:
        return _buildEmailInput();
      case ForgotPasswordStep.enterCode:
        return _buildResetForm();
      case ForgotPasswordStep.success:
        return _buildSuccessContent();
    }
  }

  Widget _buildEmailInput() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _requestPasswordReset(),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildResetForm() {
    return Column(
      children: [
        // Email field (disabled)
        TextFormField(
          controller: _emailController,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        const SizedBox(height: 20),
        
        // Confirmation code field
        TextFormField(
          controller: _confirmationCodeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Reset Code',
            hintText: 'Enter the 6-digit code',
            prefixIcon: const Icon(Icons.confirmation_number_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the reset code';
            }
            if (value.length != 6) {
              return 'Reset code must be 6 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        // New password field
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'Create a new password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword 
                    ? Icons.visibility_outlined 
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a new password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        // Confirm new password field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _resetPassword(),
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            hintText: 'Confirm your new password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword 
                    ? Icons.visibility_outlined 
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your new password';
            }
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Password successfully reset!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Redirecting to login page...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_currentStep == ForgotPasswordStep.success) {
      return SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Go to Login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _getActionButtonCallback(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _getActionButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  VoidCallback? _getActionButtonCallback() {
    switch (_currentStep) {
      case ForgotPasswordStep.requestReset:
        return _requestPasswordReset;
      case ForgotPasswordStep.enterCode:
        return _resetPassword;
      case ForgotPasswordStep.success:
        return null;
    }
  }

  String _getActionButtonText() {
    switch (_currentStep) {
      case ForgotPasswordStep.requestReset:
        return 'Send Reset Code';
      case ForgotPasswordStep.enterCode:
        return 'Reset Password';
      case ForgotPasswordStep.success:
        return 'Go to Login';
    }
  }

  Widget _buildBottomActions() {
    if (_currentStep == ForgotPasswordStep.success) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_currentStep == ForgotPasswordStep.enterCode) ...[
          TextButton(
            onPressed: _isLoading ? null : _resendResetCode,
            child: Text(
              'Resend Reset Code',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text(
            'Back to Login',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

enum ForgotPasswordStep {
  requestReset,
  enterCode,
  success,
}