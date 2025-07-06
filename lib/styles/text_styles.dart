import 'package:flutter/material.dart';
import 'package:with_force/styles/colors.dart';

class TextStyles {
  static const String kFontFamily = 'Pretendard';
  static const String kSubtitleFontFamily = 'SF Pro Text';

  static const TextStyle kTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: Color(0xFF333333),
  );

  static const TextStyle kTrailingButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
  );
  static const TextStyle kButton = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: kFontFamily,
    color: Color(0xFFFFFFFF),
  );
  static const TextStyle kHint = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: Color(0xFF999999),
  );
  static const TextStyle kSecondTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: kFontFamily,
    color: CustomColors.darkGray,
  );
  static TextStyle kInput = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: kFontFamily,
    color: Colors.black,
  );
  static const TextStyle kSecondBody = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: Color(0xFF666666),
  );
  static const TextStyle kHeader = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: kFontFamily,
    color: Color(0xFF333333),
  );

  static TextStyle kBody = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    fontFamily: kFontFamily,
  );
  static const TextStyle kSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: kSubtitleFontFamily,
    color: Color(0xFF181818),
  );
  static const TextStyle kError = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: CustomColors.redOrange,
  );
  static const TextStyle kInputText = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );
  static const TextStyle kThirdBody = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: CustomColors.lighGray,
  );
  static const TextStyle kTrailingBottomButton = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: CustomColors.darkGray,
  );
  static const TextStyle kTrailingBottomButtonWithUnderline = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: CustomColors.darkGray,
    decoration: TextDecoration.underline,
  );
  static const TextStyle kLogo = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: CustomColors.pureBlack,
  );
}
