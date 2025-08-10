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

/// Specialized dialog for account deletion
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
      confirmTextColor: CupertinoColors.activeBlue,
      cancelTextColor: CupertinoColors.destructiveRed,
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
