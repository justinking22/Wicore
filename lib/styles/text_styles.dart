import 'package:Wicore/styles/colors.dart';
import 'package:flutter/material.dart';

class TextStyles {
  static const String kFontFamily = 'Pretendard';
  static const String kSubtitleFontFamily = 'SF Pro Text';
  static const String kTitleFontfamily = 'Futura';

  static const TextStyle kTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: CustomColors.pureBlack,
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
  static const TextStyle kMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: kFontFamily,
    color: CustomColors.lightGray,
  );
  static const TextStyle kSemiBold = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: kFontFamily,
    color: CustomColors.darkCharcoal,
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
    color: CustomColors.lightGray,
  );
  static const TextStyle kRegular = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: CustomColors.darkCharcoal,
  );
  static const TextStyle kTrailingBottomButtonWithUnderline = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: CustomColors.darkCharcoal,
    decoration: TextDecoration.underline,
  );
  static const TextStyle kLogo = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: CustomColors.pureBlack,
  );
  static const TextStyle kBold = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: CustomColors.darkCharcoal,
  );
}
