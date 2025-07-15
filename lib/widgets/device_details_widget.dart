import 'package:flutter/material.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:dotted_border/dotted_border.dart'; // Add this import

class DeviceDetailsWidget extends StatefulWidget {
  final String deviceId;
  final int batteryPercentage;
  final VoidCallback? onDisconnect;

  const DeviceDetailsWidget({
    Key? key,
    this.deviceId = "0000-0000-0000",
    this.batteryPercentage = 39, // Dummy data as requested
    this.onDisconnect,
  }) : super(key: key);

  @override
  State<DeviceDetailsWidget> createState() => _DeviceDetailsWidgetState();
}

class _DeviceDetailsWidgetState extends State<DeviceDetailsWidget> {
  String selectedStrength = "약"; // Default selection

  Color _getBatteryButtonColor() {
    if (widget.batteryPercentage <= 20) {
      return const Color(0xFFFF6B47); // Red color for low battery
    } else if (widget.batteryPercentage <= 50) {
      return CustomColors.beigeTone; // Beige/tan color for medium battery
    } else {
      return const Color(0xFFB8FF00); // Green color for high battery
    }
  }

  String _getBatteryButtonText() {
    if (widget.batteryPercentage <= 20) {
      return "매우 부족";
    } else if (widget.batteryPercentage <= 50) {
      return "부족함";
    } else {
      return "충분함";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave space for your custom app bar
          const SizedBox(height: 60),

          // Device ID Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('기기번호', style: TextStyles.kMedium.copyWith(fontSize: 18)),
              Text(
                widget.deviceId,
                style: TextStyles.kRegular.copyWith(color: Color(0xFF666666)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Device Image Area with Dashed Border
          DottedBorder(
            options: RoundedRectDottedBorderOptions(
              color: Colors.grey[400]!,
              strokeWidth: 2,
              dashPattern: [8, 4], // [dash length, gap length]
              radius: Radius.circular(8), // Optional: add rounded corners
              padding: EdgeInsets.zero,
            ),
            child: Container(
              width: double.infinity,
              height: 320,
              child: Center(
                child: Text(
                  '기기 이미지 영역',
                  style: TextStyles.kMedium.copyWith(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Battery Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '배터리',
                    style: TextStyles.kMedium.copyWith(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.batteryPercentage}',
                    style: TextStyles.kSemiBold.copyWith(
                      fontSize: 32,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    ' %',
                    style: TextStyles.kMedium.copyWith(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                height: 36,

                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getBatteryButtonColor(),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _getBatteryButtonText(),
                  style: TextStyles.kRegular.copyWith(color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Divider(),
          const SizedBox(height: 16),
          // Signal Strength Section
          Text(
            '출력값(강도)',
            style: TextStyles.kMedium.copyWith(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Signal Strength Buttons
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildStrengthButton("약", selectedStrength == "약"),
                _buildStrengthButton("중", selectedStrength == "중"),
                _buildStrengthButton("강", selectedStrength == "강"),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStrengthButton(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStrength = text;
          });
        },
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyles.kMedium.copyWith(
                fontSize: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
