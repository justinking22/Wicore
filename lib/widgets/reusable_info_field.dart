import 'package:flutter/material.dart';
import 'package:with_force/styles/text_styles.dart';

class InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final bool hasUnit; // New parameter to indicate if value has unit

  const InfoField({
    Key? key,
    required this.label,
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
    this.hasUnit = false, // Default to false
  }) : super(key: key);

  // Method to split value and unit
  Map<String, String> _splitValueAndUnit() {
    if (!hasUnit || isPlaceholder) {
      return {'value': value, 'unit': ''};
    }

    // For height (cm)
    if (value.contains('cm')) {
      String numericValue = value.replaceAll('cm', '');
      return {'value': numericValue, 'unit': 'cm'};
    }

    // For weight (kg)
    if (value.contains('kg')) {
      String numericValue = value.replaceAll('kg', '');
      return {'value': numericValue, 'unit': 'kg'};
    }

    // Default case
    return {'value': value, 'unit': ''};
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> splitValue = _splitValueAndUnit();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 35, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Group label and input hint together
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyles.kTrailingBottomButton),
                if (isPlaceholder) ...[
                  SizedBox(width: 8),
                  Text(
                    '입력하기',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w700,
                      fontFamily: TextStyles.kFontFamily,
                    ),
                  ),
                ],
                if (!isPlaceholder) ...[
                  SizedBox(width: 8),
                  // Value with separate unit styling
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        splitValue['value']!,
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontFamily: TextStyles.kFontFamily,
                        ),
                      ),
                      if (splitValue['unit']!.isNotEmpty) ...[
                        SizedBox(
                          width: 2,
                        ), // Small space between number and unit
                        Text(
                          splitValue['unit']!,
                          style: TextStyles.kTrailingBottomButton,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
            // Edit hint on the right
            Row(
              children: [
                if (!isPlaceholder) ...[
                  SizedBox(width: 20),
                  Text(
                    '수정하기',
                    style: TextStyles.kTrailingBottomButtonWithUnderline,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
