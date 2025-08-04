import 'package:Wicore/modals/records_screen_modal_bottom_sheet.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/utilities/diagonal_stripes_painter.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  int currentDay = 15; // Starting with day 15
  bool hasData = false; // Track if current day has data

  void _navigateToNextDay() {
    setState(() {
      currentDay = 16; // Next day
      hasData = true; // Day 16 has data
    });
  }

  void _navigateToPreviousDay() {
    setState(() {
      currentDay = 15; // Previous day
      hasData = false; // Day 15 has no data
    });
  }

  String _getCurrentDateString() {
    if (currentDay == 15) {
      return '25.06.15 / 일요일';
    } else {
      return '25.06.16 / 월요일';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          hasData == true ? CustomColors.opaqueLightGray : Colors.white,
      appBar: CustomAppBar(
        title: '나의 작업 기록',
        leadingAssetPath: 'assets/icons/calendar_icon.png',
        leadingIconSize: 24,
        onLeadingPressed: () {
          context.push('/calendar-screen');
        },
        trailingButtonIcon: Icons.info_outline,
        showTrailingButton: true,
        onTrailingPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const RobotWorkMemoryModal(),
          );
        },
        trailingButtonIconSize: 30,
        backgroundColor: hasData == true ? Colors.white : Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date navigation section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _navigateToPreviousDay,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(194, 194, 194, 1),
                      ),
                      child: const Center(
                        // Add Center widget
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 14, // Reduce size to fit container better
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    _getCurrentDateString(),
                    style: TextStyles.kSemiBold.copyWith(fontSize: 20),
                  ),
                  const SizedBox(width: 24),
                  // For the right arrow
                  GestureDetector(
                    onTap: _navigateToNextDay,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(194, 194, 194, 1),
                      ),
                      child: const Center(
                        // Add Center widget
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 14, // Reduce size to fit container better
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Content based on whether there's data
              Expanded(
                child: hasData ? _buildDataContent() : _buildEmptyContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('아직은', style: TextStyles.kSemiBold.copyWith(fontSize: 32)),
        Text('기록된 내용이 없어요', style: TextStyles.kSemiBold.copyWith(fontSize: 32)),
      ],
    );
  }

  Widget _buildDataContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Work time card
          _buildInfoCard(
            title: '로봇 이동시간',
            value: '2',
            unit: '시간',
            subtitle: '52',
            subtitleUnit: '분',
          ),
          const SizedBox(height: 16),

          // Total activity card
          _buildInfoCard(
            title: '총 활동량',
            value: '957',
            unit: '칼로리',
            showProgressBar: true,
            progressValue: 0.8,
          ),
          const SizedBox(height: 16),

          // Activity from robot card
          _buildInfoCard(
            title: '총 활동량에서 로봇이 도와준 활동량',
            value: '431',
            unit: '칼로리',
            showProgressBar: true,
            progressValue: 0.45,
            progressColor: Colors.grey.shade800,
            hasStripes: true,
          ),
          const SizedBox(height: 16),

          // Work score card
          _buildInfoCard(
            title: '작업자세 점수',
            value: '96',
            unit: '점',
            showButton: true,
            buttonText: '매우 좋음',
            buttonColor: CustomColors.limeGreen,
          ),
          const SizedBox(height: 16),

          // Effects card
          _buildInfoCard(
            title: '효율(부담)',
            value: '7~11',
            unit: '회',
            showProgressBar: true,
            progressValue: 0.3,
            progressColor: Colors.grey.shade800,
          ),
          const SizedBox(height: 16),

          // Steps card
          _buildInfoCard(title: '걸음', value: '12,800', unit: '걸음'),
          const SizedBox(height: 16),

          // Distance card
          _buildInfoCard(title: '이동거리', value: '4.3', unit: '키로미터'),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String unit,
    String? subtitle,
    String? subtitleUnit,
    bool showProgressBar = false,
    double progressValue = 0.0,
    Color? progressColor,
    bool showButton = false,
    String? buttonText,
    Color? buttonColor,
    bool hasStripes = false,
  }) {
    return Container(
      width: double.infinity,
      height: 125,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyles.kMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: value, style: TextStyles.kBold),
                    TextSpan(text: ' $unit', style: TextStyles.kRegular),
                    if (subtitle != null && subtitleUnit != null) ...[
                      TextSpan(text: ' $subtitle', style: TextStyles.kBold),
                      TextSpan(
                        text: ' $subtitleUnit',
                        style: TextStyles.kRegular,
                      ),
                    ],
                  ],
                ),
              ),
              if (showProgressBar) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 20,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        // Main progress bar
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressValue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: progressColor ?? Colors.grey.shade800,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        // Striped section (only if hasStripes is true)
                        if (hasStripes)
                          Positioned(
                            left:
                                progressValue *
                                MediaQuery.of(context).size.width *
                                0.4, // Adjust based on available width
                            child: Container(
                              width: 120,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                              ),
                              child: ClipRRect(
                                child: CustomPaint(
                                  painter: DiagonalStripesPainter(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (!showProgressBar) const Spacer(),
              if (showButton && buttonText != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
                  decoration: BoxDecoration(
                    color: buttonColor ?? CustomColors.limeGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(buttonText, style: TextStyles.kRegular),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
