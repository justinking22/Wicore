import 'package:flutter/material.dart';
import 'package:with_force/dialogs/confirmation_dialog.dart';
import 'package:with_force/styles/text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool showBackButton;

  // Trailing button properties
  final bool showTrailingButton;
  final String? trailingButtonText;
  final IconData? trailingButtonIcon;
  final VoidCallback? onTrailingPressed;
  final Color? trailingButtonColor;
  final bool showExitDialog;
  final String? exitRoute;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onBackPressed,
    this.backgroundColor,
    this.iconColor,
    this.showBackButton = true,
    this.showTrailingButton = false,
    this.trailingButtonText,
    this.trailingButtonIcon,
    this.onTrailingPressed,
    this.trailingButtonColor,
    this.showExitDialog = false,
    this.exitRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: iconColor ?? Colors.black,
                  size: 35,
                ),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
              : null,
      title: Text(title, style: TextStyles.kTitle),
      centerTitle: true,
      actions: showTrailingButton ? [_buildTrailingButton(context)] : null,
    );
  }

  Widget _buildTrailingButton(BuildContext context) {
    // Handle exit dialog logic
    VoidCallback? buttonAction = onTrailingPressed;

    if (showExitDialog && onTrailingPressed == null) {
      buttonAction = () {
        ExitConfirmationDialogWithOptions.show(context, exitRoute: exitRoute);
      };
    }

    // If only icon is provided, show icon button
    if (trailingButtonIcon != null) {
      return IconButton(
        onPressed: buttonAction,
        icon: Icon(
          trailingButtonIcon!,
          color: trailingButtonColor ?? Colors.black,
          size: 24,
        ),
      );
    }

    // Default trailing button (you can customize this)
    return TextButton(
      onPressed: onTrailingPressed,
      child: Text(
        '그만두기',
        style: TextStyle(
          color: trailingButtonColor ?? Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
