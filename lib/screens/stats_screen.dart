import 'package:Wicore/modals/records_screen_modal_bottom_sheet.dart';
import 'package:Wicore/providers/stats_provider.dart';
import 'package:Wicore/models/stats_request_model.dart';
import 'package:Wicore/states/stats_state.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/utilities/diagonal_stripes_painter.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
    return hours > 0 ? '$hours시간 $remainingMinutes분' : '$remainingMinutes분';
  }

  String _formatTimeDifference(String? startTime, String? endTime) {
    if (startTime == null ||
        endTime == null ||
        startTime.isEmpty ||
        endTime.isEmpty) {
      return '0분';
    }
    try {
      final format = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
      final start = format.parse(startTime, true);
      final end = format.parse(endTime, true);
      final difference = end.difference(start);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return hours > 0 ? '$hours시간 $minutes분' : '$minutes분';
    } catch (e) {
      if (kDebugMode)
        print('🔧 ❌ Error parsing time: $e, start: $startTime, end: $endTime');
      return '0분';
    }
  }

  String _formatBreathRange(double? mean, double? std) {
    if (mean == null || std == null) return '0 ± 0';
    final min = (mean - std).clamp(0.0, 40.0).round();
    final max = (mean + std).clamp(0.0, 40.0).round();
    return '$min ~ $max';
  }

  String _getPostureGradeText(String? grade, int score) {
    if (grade == null || grade.isEmpty || grade == 'N/A') {
      if (score >= 90) return '매우 좋음';
      if (score >= 75) return '좋음';
      if (score >= 60) return '보통';
      return '나쁨';
    }
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

  Color _getPostureGradeColor(String? grade, int score) {
    if (grade == null || grade.isEmpty || grade == 'N/A') {
      if (score >= 90) return CustomColors.limeGreen;
      if (score >= 75) return Colors.green;
      if (score >= 60) return Colors.orange;
      return Colors.red;
    }
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

  bool _isFutureDate() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return selectedDateOnly.isAfter(todayDate);
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(statsNotifierProvider);
    final hasData = statsState.hasData;

    return Scaffold(
      backgroundColor: hasData ? CustomColors.opaqueLightGray : Colors.white,
      appBar: CustomAppBar(
        title: '나의 작업 기록',

        leadingAssetPath: 'assets/icons/calendar_icon.png',
        leadingIconSize: 24,
        onLeadingPressed: () => context.push('/calendar-screen'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _navigateToPreviousDay,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 14,
                          ),
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
                    onTap: _isFutureDate() ? null : _navigateToNextDay,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _isFutureDate()
                                    ? const Color.fromRGBO(194, 194, 194, 1)
                                    : Colors.black,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildContent(statsState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(StatsState statsState) {
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

  Widget _buildDataContent(StatsState statsState) {
    final stats = statsState.statsData;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoCard(
            title: '로봇 이용 시간',
            value: _formatTimeDifference(
              stats?.dataStartTime,
              stats?.dataEndTime,
            ),
            unit: '',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '총 활동량',
            value: (stats?.totalCalories ?? 0).toString(),
            unit: '칼로리',
            showProgressBar: true,
            progressValue: 0.8,
            progressColor: Colors.grey.shade800,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '총 활동량에서 로봇이 도와준 활동량',
            value: (stats?.lmaCalories ?? 0).toString(),
            unit: '칼로리',
            showProgressBar: true,
            progressValue: 0.8,
            progressColor: Colors.grey.shade800,
            hasStripes: true,
            stripeWidth: ((stats?.lmaCalories ?? 0) /
                    (stats?.totalCalories ?? 1))
                .clamp(0.0, 0.8),
            stripeColor: CustomColors.limeGreen,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '호흡(분당)',
            value: _formatBreathRange(stats?.breathMean, stats?.breathStd),
            unit: '회',
            showProgressBar: true,
            progressValue:
                (stats?.breathMean ?? 0.0 + (stats?.breathStd ?? 0.0)) / 40.0,
            progressMinValue:
                (stats?.breathMean ?? 0.0 - (stats?.breathStd ?? 0.0)) / 40.0,
            progressColor: Colors.grey.shade800,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '작업자세 점수',
            value: (stats?.postureScore ?? 0).toString(),
            unit: '점',
            showButton: true,
            buttonText: _getPostureGradeText(
              stats?.postureGrade,
              stats?.postureScore ?? 0,
            ),
            buttonColor: _getPostureGradeColor(
              stats?.postureGrade,
              stats?.postureScore ?? 0,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '효율(부담)',
            value:
                '${((stats?.totalLmaCount ?? 0) * 0.7).round()}~${stats?.totalLmaCount ?? 0}',
            unit: '회',
            showProgressBar: true,
            progressValue: ((stats?.totalLmaCount ?? 0) / 1000).clamp(0.0, 1.0),
            progressColor: Colors.grey.shade800,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '걸음',
            value: (stats?.totalSteps ?? 0).toStringAsFixed(0),
            unit: '걸음',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '이동거리',
            value: (stats?.totalDistance ?? 0.0).toStringAsFixed(1),
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
    double progressMinValue = 0.0,
    Color? progressColor,
    bool showButton = false,
    String? buttonText,
    Color? buttonColor,
    bool hasStripes = false,
    double stripeWidth = 0.0,
    Color? stripeColor,
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
                        // Main progress bar (80% fill for Total and Robot-Assisted)
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
                        // Striped section for Robot-Assisted Activity
                        if (hasStripes && stripeWidth > 0)
                          Positioned(
                            left: (progressValue - stripeWidth) * 120,
                            child: Container(
                              width: stripeWidth * 120,
                              height: 20,
                              decoration: BoxDecoration(
                                color: stripeColor ?? Colors.grey.shade800,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                                child: CustomPaint(
                                  painter: DiagonalStripesPainter(),
                                ),
                              ),
                            ),
                          ),
                        // Breath range fill
                        if (progressMinValue > 0.0)
                          Positioned(
                            left: progressMinValue * 120,
                            child: Container(
                              width: (progressValue - progressMinValue) * 120,
                              height: 20,
                              decoration: BoxDecoration(
                                color: progressColor ?? Colors.grey.shade800,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
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
