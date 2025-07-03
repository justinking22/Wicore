import 'package:flutter/material.dart';
import 'package:with_force/styles/colors.dart';

class TextStyles {
  static String kFontFamily = 'Pretendard';
  static String kSubtitleFontFamily = 'SF Pro Text';

  static TextStyle? kTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: const Color(0xFF333333),
  );

  static TextStyle? kTrailingButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
  );
  static TextStyle? kButton = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: kFontFamily,
    color: Color(0xFFFFFFFF),
  );
  static TextStyle? kHint = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: Color(0xFF999999),
  );
  static TextStyle? kInput = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: kFontFamily,
    color: Colors.black,
  );
  static TextStyle? kSecondBody = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: Color(0xFF666666),
  );
  static TextStyle? kHeader = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: kFontFamily,
    color: const Color(0xFF333333),
  );

  static TextStyle? kBody = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    fontFamily: kFontFamily,
  );
  static TextStyle? kSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: kSubtitleFontFamily,
    color: const Color(0xFF181818),
  );
  static TextStyle? kError = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: CustomColors.redOrange,
  );
  static TextStyle? kInputText = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );
  static TextStyle? kThirdBody = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: CustomColors.lighGray,
  );
  static TextStyle? kTrailingBottomButton = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: CustomColors.darkGray,
  );
}
