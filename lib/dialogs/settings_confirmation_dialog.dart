import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IOSConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmTextColor;
  final Color? cancelTextColor;
  final FontWeight? confirmFontWeight;
  final FontWeight? cancelFontWeight;

  const IOSConfirmationDialog({
    Key? key,
    required this.title,
    required this.content,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.onConfirm,
    this.onCancel,
    this.confirmTextColor,
    this.cancelTextColor,
    this.confirmFontWeight,
    this.cancelFontWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.black,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: TextStyle(
              fontSize: 17,
              color: cancelTextColor ?? CupertinoColors.activeBlue,
              fontWeight: cancelFontWeight ?? FontWeight.w400,
            ),
          ),
        ),
        CupertinoDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: Text(
            confirmText,
            style: TextStyle(
              fontSize: 17,
              color: confirmTextColor ?? CupertinoColors.activeBlue,
              fontWeight: confirmFontWeight ?? FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Helper method to show the dialog and return a Future<bool?>
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '확인',
    String cancelText = '취소',
    Color? confirmTextColor,
    Color? cancelTextColor,
    FontWeight? confirmFontWeight,
    FontWeight? cancelFontWeight,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => IOSConfirmationDialog(
            title: title,
            content: content,
            confirmText: confirmText,
            cancelText: cancelText,
            confirmTextColor: confirmTextColor,
            cancelTextColor: cancelTextColor,
            confirmFontWeight: confirmFontWeight,
            cancelFontWeight: cancelFontWeight,
          ),
    );
  }
}

/// Specialized dialog for account deletion (UPDATED - Blue colors only)
class AccountDeletionDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const AccountDeletionDialog({Key? key, this.onConfirm, this.onCancel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IOSConfirmationDialog(
      title: '회원 탈퇴',
      content: '앱 이용이 중단되고, 모든 정보가 삭제됩니다. 삭제된 정보는 다시 복원할 수 없습니다.\n정말 탈퇴하시겠어요?',
      confirmText: '아니요',
      cancelText: '네',
      confirmTextColor: CupertinoColors.activeBlue, // Changed to blue
      cancelTextColor: CupertinoColors.activeBlue, // Changed to blue
      confirmFontWeight: FontWeight.w600,
      cancelFontWeight: FontWeight.w400,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show account deletion dialog specifically
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AccountDeletionDialog(
            onCancel:
                () => Navigator.of(context).pop(true), // "네" (Yes, delete)
            onConfirm:
                () => Navigator.of(context).pop(false), // "아니요" (No, cancel)
          ),
    );
  }
}

/// Specialized dialog for logout confirmation
class LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const LogoutConfirmationDialog({Key? key, this.onConfirm, this.onCancel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IOSConfirmationDialog(
      title: '로그아웃',
      content:
          '로그아웃하시면 앱 이용이 중단됩니다.\n다시 사용하시려면 이메일과 비밀번호로 로그인하셔야 해요.\n로그아웃할까요?',
      confirmText: '아니요',
      cancelText: '네',
      confirmTextColor: CupertinoColors.activeBlue,
      cancelTextColor: CupertinoColors.activeBlue,
      confirmFontWeight: FontWeight.w600,
      cancelFontWeight: FontWeight.w400,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show logout confirmation dialog specifically
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => LogoutConfirmationDialog(
            onCancel:
                () => Navigator.of(context).pop(true), // "네" (Yes, logout)
            onConfirm:
                () => Navigator.of(context).pop(false), // "아니요" (No, cancel)
          ),
    );
  }
}

/// Specialized dialog for forgot password confirmation
class ForgotPasswordDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ForgotPasswordDialog({Key? key, this.onConfirm, this.onCancel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IOSConfirmationDialog(
      title: '비밀번호 재입력',
      content: '이전에 입력했던 비밀번호가 기억나지 않으신가요? 비밀번호 입력 화면으로 다시 이동할게요.',
      confirmText: '네',
      cancelText: '아니요',
      confirmTextColor: CupertinoColors.activeBlue,
      cancelTextColor: CupertinoColors.activeBlue,
      confirmFontWeight: FontWeight.w600,
      cancelFontWeight: FontWeight.w400,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show forgot password dialog specifically
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ForgotPasswordDialog(
            onCancel:
                () => Navigator.of(context).pop(false), // "아니요" (No, stay)
            onConfirm:
                () => Navigator.of(context).pop(true), // "네" (Yes, go back)
          ),
    );
  }
}

/// Specialized dialog for email verification completion
class EmailVerificationCompletionDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const EmailVerificationCompletionDialog({
    Key? key,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IOSConfirmationDialog(
      title: '인증번호 전송 완료',
      content: '이메일의 인증 링크를 클릭하여 계정을 활성화한 후 로그인 화면에서 로그인해주세요.',
      confirmText: '확인',
      cancelText: '', // No cancel button needed
      confirmTextColor: CupertinoColors.activeBlue,
      confirmFontWeight: FontWeight.w600,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show email verification completion dialog specifically
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text(
              '인증링크 전송 완료',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '이메일의 인증 링크를 클릭하여 계정을 활성화한 후 로그인 화면에서 로그인해주세요.',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.black,
                  height: 1.4,
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

/// Specialized dialog for skipping personal info input
class SkipPersonalInfoDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const SkipPersonalInfoDialog({Key? key, this.onConfirm, this.onCancel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        '홈으로 이동',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
      content: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          '지금 진행을 건너뛰면 입력하신 정보는 저장되지 않습니다.\n홈 화면으로 이동하시겠어요?',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.black,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: const Text(
            '네',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        CupertinoDialogAction(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: const Text(
            '아니요',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show skip personal info dialog specifically
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => SkipPersonalInfoDialog(
            onConfirm: () => Navigator.of(context).pop(true), // "네" (Yes, skip)
            onCancel:
                () => Navigator.of(context).pop(false), // "아니요" (No, stay)
          ),
    );
  }
}

/// Dialog for OTP resend confirmation
class OTPResendConfirmationDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const OTPResendConfirmationDialog({Key? key, this.onConfirm, this.onCancel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        '인증번호 재전송',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
      content: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          '입력하신 이메일 주소로 인증번호를 다시 보내드릴까요?\n기존 번호는 사용할 수 없어요.',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.black,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: const Text(
            '아니요',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        CupertinoDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: const Text(
            '네',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show OTP resend confirmation dialog
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => OTPResendConfirmationDialog(
            onCancel:
                () => Navigator.of(
                  context,
                ).pop(false), // "아니요" (No, don't resend)
            onConfirm:
                () => Navigator.of(context).pop(true), // "네" (Yes, resend)
          ),
    );
  }
}

/// Dialog for OTP sent completion (single button)
class OTPSentCompletionDialog extends StatelessWidget {
  final VoidCallback? onConfirm;

  const OTPSentCompletionDialog({Key? key, this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        '인증번호 전송 완료',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
      content: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          '이메일을 확인하시고, 인증번호 6자리를 입력해주세요.',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.black,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: const Text(
            '확인',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show OTP sent completion dialog
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => OTPSentCompletionDialog(
            onConfirm: () => Navigator.of(context).pop(true), // "확인" (OK)
          ),
    );
  }
}

/// NEW: Dialog for account withdrawal completion (single button)
class AccountWithdrawalCompletionDialog extends StatelessWidget {
  final VoidCallback? onConfirm;

  const AccountWithdrawalCompletionDialog({Key? key, this.onConfirm})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        '회원 탈퇴 완료',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
      content: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          '회원님의 정보가 모두 삭제되었습니다.\n다시 이용하시려면 새로 가입해주세요.',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.black,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: const Text(
            '확인',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show account withdrawal completion dialog
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AccountWithdrawalCompletionDialog(
            onConfirm: () => Navigator.of(context).pop(true), // "확인" (OK)
          ),
    );
  }
}

/// NEW: Dialog for data deletion completion (single button)
class DataDeletionCompletionDialog extends StatelessWidget {
  final VoidCallback? onConfirm;

  const DataDeletionCompletionDialog({Key? key, this.onConfirm})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        '데이터 삭제 완료',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
      content: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          '활동 데이터가 모두 삭제되었습니다.\n기기를 다시 사용하시면 새로운 데이터가 저장돼요.',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.black,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: const Text(
            '확인',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show data deletion completion dialog
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => DataDeletionCompletionDialog(
            onConfirm: () => Navigator.of(context).pop(true), // "확인" (OK)
          ),
    );
  }
}

/// NEW: Dialog for data deletion confirmation
class DataDeletionConfirmationDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const DataDeletionConfirmationDialog({
    Key? key,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        '데이터 삭제',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
      content: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          '저장된 활동 데이터가 모두 삭제됩니다.\n삭제된 정보는 다시 복구할 수 없습니다.\n삭제를 계속할까요?',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.black,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: const Text(
            '네',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        CupertinoDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: const Text(
            '아니요',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show data deletion confirmation dialog
  static Future<bool?> show(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => DataDeletionConfirmationDialog(
            onCancel:
                () => Navigator.of(context).pop(true), // "네" (Yes, delete)
            onConfirm:
                () => Navigator.of(context).pop(false), // "아니요" (No, cancel)
          ),
    );
  }
}

/// Specialized dialog for device unpair confirmation
class DeviceUnpairConfirmationDialog extends StatelessWidget {
  final String deviceId;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const DeviceUnpairConfirmationDialog({
    Key? key,
    required this.deviceId,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        '기기 연결 해제',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          '기기와의 연결을 해제하면 데이터를 더 이상 받을 수 없습니다.\n정말 연결을 해제할까요?',
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.black,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: const Text(
            '아니요',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        CupertinoDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: const Text(
            '네',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show device unpair confirmation dialog
  static Future<bool?> show(BuildContext context, String deviceId) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => DeviceUnpairConfirmationDialog(
            deviceId: deviceId,
            onCancel:
                () => Navigator.of(context).pop(false), // "아니요" (No, cancel)
            onConfirm:
                () => Navigator.of(context).pop(true), // "네" (Yes, unpair)
          ),
    );
  }
}
