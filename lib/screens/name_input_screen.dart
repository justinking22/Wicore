import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/utilities/sign_up_form_state.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/widgets/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NameInputScreen extends ConsumerStatefulWidget {
  const NameInputScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends ConsumerState<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isButtonEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);

    // Load existing name if user goes back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final signUpForm = ref.read(signUpFormProvider);
      if (signUpForm.name.isNotEmpty) {
        _nameController.text = signUpForm.name;
        _isButtonEnabled = true;
      }
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty;
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // Save name via API and continue to email input
  void _handleNext() async {
    if (!_isButtonEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름을 입력해주세요')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      print('👤 NameInput - Saving name: $name');

      // Store in form state first
      ref.read(signUpFormProvider.notifier).setName(name);

      // Save name via API patch request
      await ref
          .read(userProvider.notifier)
          .updateCurrentUserProfile(UserUpdateRequest(firstName: name));

      print('✅ NameInput - Name saved successfully via API');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이름이 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to email input
        context.push('/email-input');
      }
    } catch (e) {
      print('❌ NameInput - Error saving name: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이름 저장 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isApiLoading = userState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final availableHeight = screenHeight - keyboardHeight;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        // Prevent the body from resizing when keyboard appears
        resizeToAvoidBottomInset: false,
        appBar: CustomAppBar(
          title: '회원가입',
          onBackPressed: () => Navigator.pop(context),
          showTrailingButton: true,
          onTrailingPressed: () {
            ExitConfirmationDialogWithOptions.show(
              context,
              exitRoute: '/welcome',
            );
          },
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isKeyboardVisible ? 20 : 40),

                    // Title text
                    Text('먼저', style: TextStyles.kBody),
                    const SizedBox(height: 8),
                    Text('이름을 알려주세요', style: TextStyles.kBody),
                    SizedBox(height: isKeyboardVisible ? 30 : 60),

                    // Input field label
                    Text('이름', style: TextStyles.kHeader),
                    const SizedBox(height: 8),

                    // Name input field
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_isButtonEnabled) {
                          _handleNext();
                        } else {
                          _dismissKeyboard();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: '예) 홍길동',
                        hintStyle: TextStyles.kMedium,
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 0,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),

                    // Flexible spacing that adapts to keyboard
                    SizedBox(
                      height:
                          isKeyboardVisible
                              ? 40
                              : availableHeight -
                                  400, // Adjust based on content height
                    ),

                    // Loading indicator or Next button
                    if (_isSaving || isApiLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      CustomButton(
                        text: '다음',
                        isEnabled: _isButtonEnabled,
                        onPressed: _isButtonEnabled ? _handleNext : null,
                        disabledBackgroundColor: Colors.grey,
                      ),

                    // Bottom padding to ensure button is always visible
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
    );
  }
}
