import 'package:flutter/material.dart';
import 'package:with_force/dialogs/confirmation_dialog.dart';
import 'package:with_force/styles/text_styles.dart';
import 'package:with_force/widgets/reusable_app_bar.dart';
import 'package:with_force/widgets/reusable_button.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({Key? key}) : super(key: key);

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _agreeAll = false;
  bool _agreeService = false;
  bool _agreePrivacy = false;
  bool _agreeLocation = false;

  bool get _isButtonEnabled => _agreeService && _agreePrivacy && _agreeLocation;

  void _updateAgreeAll() {
    setState(() {
      _agreeAll = _agreeService && _agreePrivacy && _agreeLocation;
    });
  }

  void _handleAgreeAllChanged(bool? value) {
    setState(() {
      _agreeAll = value ?? false;
      _agreeService = _agreeAll;
      _agreePrivacy = _agreeAll;
      _agreeLocation = _agreeAll;
    });
  }

  void _handleServiceChanged(bool? value) {
    setState(() {
      _agreeService = value ?? false;
    });
    _updateAgreeAll();
  }

  void _handlePrivacyChanged(bool? value) {
    setState(() {
      _agreePrivacy = value ?? false;
    });
    _updateAgreeAll();
  }

  void _handleLocationChanged(bool? value) {
    setState(() {
      _agreeLocation = value ?? false;
    });
    _updateAgreeAll();
  }

  void _showTermsDetails(String title) {
    // Navigate to terms detail screen or show dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text('$title의 상세 내용이 여기에 표시됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _handleConfirm() {
    if (_isButtonEnabled) {
      // Navigate to next screen (home or success screen)
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  Widget _buildCheckboxRow({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool showArrow = false,
    VoidCallback? onArrowTap,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.black,
              checkColor: Colors.white,
              side: BorderSide(color: Colors.grey[400]!, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          if (showArrow)
            GestureDetector(
              onTap: onArrowTap,
              child: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Title text
            const Text(
              '안전한 이용을 위해',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '약관에 동의해주세요',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 24),

            // Subtitle text
            const Text(
              '동의하신 내용은 언제든지 앱에서',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '다시 확인하실 수 있어요.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 60),

            // Agree all checkbox
            _buildCheckboxRow(
              title: '전체동의',
              value: _agreeAll,
              onChanged: _handleAgreeAllChanged,
              isBold: true,
            ),

            // Divider line
            const Divider(height: 32, thickness: 1, color: Color(0xFFE0E0E0)),

            // Individual agreement checkboxes
            _buildCheckboxRow(
              title: '[필수] 서비스 이용 약관',
              value: _agreeService,
              onChanged: _handleServiceChanged,
              showArrow: true,
              onArrowTap: () => _showTermsDetails('서비스 이용 약관'),
            ),

            _buildCheckboxRow(
              title: '[필수] 개인정보 수집 및 이용 동의',
              value: _agreePrivacy,
              onChanged: _handlePrivacyChanged,
              showArrow: true,
              onArrowTap: () => _showTermsDetails('개인정보 수집 및 이용 동의'),
            ),

            _buildCheckboxRow(
              title: '[선택] 위치 정보 수집 동의',
              value: _agreeLocation,
              onChanged: _handleLocationChanged,
              showArrow: true,
              onArrowTap: () => _showTermsDetails('위치 정보 수집 동의'),
            ),

            const Spacer(),

            // Confirm button
            CustomButton(
              text: '확인',
              isEnabled: _isButtonEnabled,
              onPressed: _isButtonEnabled ? _handleConfirm : null,
              disabledBackgroundColor: Colors.grey,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
