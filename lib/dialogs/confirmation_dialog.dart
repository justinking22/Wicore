import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExitConfirmationDialog {
  static Future<void> show(BuildContext context) async {
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text(
            '회원가입 그만두기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '회원가입을 중단하면 처음부터 다시 시작해야 합니다. 회원가입을 그만두시겠습니까?',
              style: TextStyles.kSubtitle,
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.go('/welcome'); // Exit to welcome screen
              },
              child: const Text(
                '네',
                style: TextStyle(
                  color: CupertinoColors.systemBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog only
                // Stay on current screen - no additional action needed
              },
              child: const Text(
                '아니요',
                style: TextStyle(
                  color: CupertinoColors.systemBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Alternative with different navigation options (FIXED)
class ExitConfirmationDialogWithOptions {
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onConfirmExit,
    String? exitRoute,
  }) async {
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            '회원가입 그만두기',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CustomColors.almostBlack,
              fontFamily: 'SF Pro Text',
            ),
          ),
          content: Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              '회원가입을 중단하면 처음부터 다시 시작해야 합니다. 회원가입을 그만두시겠습니까?',
              style: TextStyles.kSubtitle,
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                // "네" (Yes) - Exit to welcome screen
                if (onConfirmExit != null) {
                  onConfirmExit();
                } else if (exitRoute != null) {
                  context.go(exitRoute);
                } else {
                  // Default: go to welcome screen
                  context.go('/welcome');
                }
              },
              child: const Text(
                '네',
                style: TextStyle(
                  color: CupertinoColors.systemBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog only
                // "아니요" (No) - Stay on current screen (do nothing)
              },
              child: const Text(
                '아니요',
                style: TextStyle(
                  color: CupertinoColors.systemBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
