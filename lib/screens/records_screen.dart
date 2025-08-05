import 'package:Wicore/modals/records_screen_modal_bottom_sheet.dart';
import 'package:Wicore/providers/stats_provider.dart';
import 'package:Wicore/models/stats_request_model.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/utilities/diagonal_stripes_painter.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load today's stats when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatsForSelectedDate();
    });
  }

  void _loadStatsForSelectedDate() {
    final dateString =
        '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
    ref.read(statsNotifierProvider.notifier).loadStatsForDate(dateString);
  }

  void _navigateToNextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
    _loadStatsForSelectedDate();
  }

  void _navigateToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
    _loadStatsForSelectedDate();
  }

  String _getCurrentDateString() {
    const weekdays = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    final weekday = weekdays[selectedDate.weekday % 7];
    return '${selectedDate.year.toString().substring(2)}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')} / $weekday';
  }

  String _formatDuration(double minutes) {
    final hours = (minutes / 60).floor();
    final remainingMinutes = (minutes % 60).round();

    if (hours > 0) {
      return '$hours시간 ${remainingMinutes}분';
    } else {
      return '${remainingMinutes}분';
    }
  }

  String _getPostureGradeText(String grade, int score) {
    switch (grade.toLowerCase()) {
      case 'excellent':
        return '매우 좋음';
      case 'good':
        return '좋음';
      case 'fair':
        return '보통';
      case 'poor':
        return '나쁨';
      default:
        if (score >= 90) return '매우 좋음';
        if (score >= 75) return '좋음';
        if (score >= 60) return '보통';
        return '나쁨';
    }
  }

  Color _getPostureGradeColor(String grade, int score) {
    switch (grade.toLowerCase()) {
      case 'excellent':
        return CustomColors.limeGreen;
      case 'good':
        return Colors.green;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        if (score >= 90) return CustomColors.limeGreen;
        if (score >= 75) return Colors.green;
        if (score >= 60) return Colors.orange;
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(statsNotifierProvider);
    final hasData = statsState.hasData && !statsState.isLoading;

    return Scaffold(
      backgroundColor: hasData ? CustomColors.opaqueLightGray : Colors.white,
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
        backgroundColor: Colors.white,
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
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 14,
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
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Content based on state
              Expanded(child: _buildContent(statsState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(statsState) {
    if (statsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (statsState.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오류가 발생했습니다',
            style: TextStyles.kSemiBold.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 16),
          Text(statsState.error ?? '알 수 없는 오류', style: TextStyles.kRegular),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStatsForSelectedDate,
            child: const Text('다시 시도'),
          ),
        ],
      );
    }

    if (!statsState.hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('아직은', style: TextStyles.kSemiBold.copyWith(fontSize: 32)),
          Text(
            '기록된 내용이 없어요',
            style: TextStyles.kSemiBold.copyWith(fontSize: 32),
          ),
        ],
      );
    }

    return _buildDataContent(statsState);
  }

  Widget _buildDataContent(statsState) {
    final stats = statsState.statsData;
    if (stats == null) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Work time card - using bentMeanDuration
          _buildInfoCard(
            title: '로봇 이동시간',
            value: _formatDuration(stats.bentMeanDuration),
            unit: '',
          ),
          const SizedBox(height: 16),

          // Total activity card - using totalCalories
          _buildInfoCard(
            title: '총 활동량',
            value: stats.totalCalories.toString(),
            unit: '칼로리',
            showProgressBar: true,
            progressValue: (stats.totalCalories / 1200).clamp(
              0.0,
              1.0,
            ), // Assuming 1200 as max
          ),
          const SizedBox(height: 16),

          // Activity from robot card - using lmaCalories
          _buildInfoCard(
            title: '총 활동량에서 로봇이 도와준 활동량',
            value: stats.lmaCalories.toString(),
            unit: '칼로리',
            showProgressBar: true,
            progressValue:
                stats.totalCalories > 0
                    ? (stats.lmaCalories / stats.totalCalories).clamp(0.0, 1.0)
                    : 0.0,
            progressColor: Colors.grey.shade800,
            hasStripes: true,
          ),
          const SizedBox(height: 16),

          // Work score card - using postureScore
          _buildInfoCard(
            title: '작업자세 점수',
            value: stats.postureScore.toString(),
            unit: '점',
            showButton: true,
            buttonText: _getPostureGradeText(
              stats.postureGrade,
              stats.postureScore,
            ),
            buttonColor: _getPostureGradeColor(
              stats.postureGrade,
              stats.postureScore,
            ),
          ),
          const SizedBox(height: 16),

          // Effects card - using totalLmaCount
          _buildInfoCard(
            title: '효율(부담)',
            value:
                '${(stats.totalLmaCount * 0.7).round()}~${stats.totalLmaCount}',
            unit: '회',
            showProgressBar: true,
            progressValue: (stats.totalLmaCount / 1000).clamp(
              0.0,
              1.0,
            ), // Assuming 1000 as max
            progressColor: Colors.grey.shade800,
          ),
          const SizedBox(height: 16),

          // Steps card - using totalSteps
          _buildInfoCard(
            title: '걸음',
            value: stats.totalSteps.toStringAsFixed(0),
            unit: '걸음',
          ),
          const SizedBox(height: 16),

          // Distance card - using totalDistance
          _buildInfoCard(
            title: '이동거리',
            value: stats.totalDistance.toStringAsFixed(1),
            unit: '키로미터',
          ),
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
                    if (unit.isNotEmpty)
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
                              borderRadius: const BorderRadius.only(
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
                                0.4,
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
