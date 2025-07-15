import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final Color? textColor;
  final Color? disabledTextColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.textColor,
    this.disabledTextColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool buttonEnabled = isEnabled && onPressed != null && !isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 64,
      child: ElevatedButton(
        onPressed: buttonEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              buttonEnabled
                  ? (backgroundColor ?? CustomColors.darkCharcoal)
                  : (disabledBackgroundColor ?? Colors.grey[900]),
          foregroundColor:
              buttonEnabled
                  ? (textColor ?? Colors.white)
                  : (disabledTextColor ?? Colors.grey[600]),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          elevation: buttonEnabled ? 2 : 0,
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 29,
                  width: 39,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ?? Colors.white,
                    ),
                  ),
                )
                : Text(text, style: TextStyles.kButton),
      ),
    );
  }
}
