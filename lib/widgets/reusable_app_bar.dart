import 'package:Wicore/dialogs/confirmation_dialog.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool showBackButton;

  // Leading button customization properties
  final Widget? customLeadingWidget;
  final IconData? leadingIcon;
  final String? leadingAssetPath;
  final String? leadingText;
  final VoidCallback? onLeadingPressed;
  final Color? leadingColor;
  final double? leadingIconSize;

  // Trailing button properties
  final bool showTrailingButton;
  final String? trailingButtonText;
  final IconData? trailingButtonIcon;
  final VoidCallback? onTrailingPressed;
  final double? trailingButtonIconSize;
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

    // Leading button customization
    this.customLeadingWidget,
    this.leadingIcon,
    this.leadingAssetPath,
    this.leadingText,
    this.onLeadingPressed,
    this.leadingColor,
    this.leadingIconSize,

    // Trailing button properties
    this.showTrailingButton = false,
    this.trailingButtonIconSize,
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
      leading: _buildLeadingWidget(context),
      title: Text(title, style: TextStyles.kTitle),
      centerTitle: true,
      actions: showTrailingButton ? [_buildTrailingButton(context)] : null,
    );
  }

  Widget? _buildLeadingWidget(BuildContext context) {
    // If custom widget is provided, use it
    if (customLeadingWidget != null) {
      return customLeadingWidget;
    }

    // If no leading widget should be shown
    if (!showBackButton) {
      return null;
    }

    // If custom asset path is provided
    if (leadingAssetPath != null) {
      return IconButton(
        icon: Image.asset(
          leadingAssetPath!,
          width: leadingIconSize ?? 24,
          height: leadingIconSize ?? 24,
          color: leadingColor ?? iconColor,
        ),
        onPressed:
            onLeadingPressed ??
            onBackPressed ??
            () => Navigator.of(context).pop(),
      );
    }

    // If custom leading icon is provided
    if (leadingIcon != null) {
      return IconButton(
        icon: Icon(
          leadingIcon!,
          color: leadingColor ?? iconColor ?? Colors.black,
          size: leadingIconSize ?? 24,
        ),
        onPressed:
            onLeadingPressed ??
            onBackPressed ??
            () => Navigator.of(context).pop(),
      );
    }

    // If custom leading text is provided
    if (leadingText != null) {
      return TextButton(
        onPressed:
            onLeadingPressed ??
            onBackPressed ??
            () => Navigator.of(context).pop(),
        child: Text(
          leadingText!,
          style: TextStyle(
            color: leadingColor ?? iconColor ?? Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Default back button
    return IconButton(
      icon: Icon(
        Icons.chevron_left,
        color: iconColor ?? Colors.black,
        size: 35,
      ),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
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
          size: trailingButtonIconSize ?? 24,
        ),
      );
    }

    // Default trailing button
    return TextButton(
      onPressed: buttonAction,
      child: Text(
        trailingButtonText ?? '건너뛰기',
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
