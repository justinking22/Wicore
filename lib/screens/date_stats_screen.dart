import 'package:Wicore/modals/records_screen_modal_bottom_sheet.dart';
import 'package:Wicore/providers/stats_provider.dart';
import 'package:Wicore/models/stats_request_model.dart';
import 'package:Wicore/states/stats_state.dart';
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/utilities/diagonal_stripes_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DateStatsScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const DateStatsScreen({super.key, required this.selectedDate});

  @override
  ConsumerState<DateStatsScreen> createState() => _DateStatsScreenState();
}

class _DateStatsScreenState extends ConsumerState<DateStatsScreen> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;

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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360 || screenSize.height < 600;

    return Scaffold(
      backgroundColor: hasData ? CustomColors.opaqueLightGray : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '작업 기록',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const RobotWorkMemoryModal(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
            final verticalPadding = isSmallScreen ? 8.0 : 12.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date navigation
                  _buildDateNavigation(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  Expanded(
                    child: _buildContent(
                      statsState,
                      isSmallScreen,
                      constraints,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateNavigation(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _navigateToPreviousDay,
          child: Container(
            width: isSmallScreen ? 36 : 44,
            height: isSmallScreen ? 36 : 44,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: Container(
                width: isSmallScreen ? 16 : 18,
                height: isSmallScreen ? 16 : 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _getCurrentDateString(),
              style: TextStyles.kSemiBold.copyWith(
                fontSize: isSmallScreen ? 16 : 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _isFutureDate() ? null : _navigateToNextDay,
          child: Container(
            width: isSmallScreen ? 36 : 44,
            height: isSmallScreen ? 36 : 44,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: Container(
                width: isSmallScreen ? 16 : 18,
                height: isSmallScreen ? 16 : 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isFutureDate()
                          ? const Color.fromRGBO(194, 194, 194, 1)
                          : Colors.black,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Copy all the other helper methods from your StatsScreen
  // _buildContent, _buildDataContent, _buildInfoCard, _buildProgressBar, etc.
  // (Same implementation as in your original StatsScreen)

  Widget _buildContent(
    StatsState statsState,
    bool isSmallScreen,
    BoxConstraints constraints,
  ) {
    if (statsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (statsState.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              '오류가 발생했습니다',
              style: TextStyles.kSemiBold.copyWith(
                fontSize: isSmallScreen ? 24 : 32,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Flexible(
            child: Text(
              statsState.error ?? '알 수 없는 오류',
              style: TextStyles.kRegular,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
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
          Flexible(
            child: Text(
              '아직은',
              style: TextStyles.kSemiBold.copyWith(
                fontSize: isSmallScreen ? 24 : 32,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              '기록된 내용이 없어요',
              style: TextStyles.kSemiBold.copyWith(
                fontSize: isSmallScreen ? 24 : 32,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return _buildDataContent(statsState, isSmallScreen, constraints);
  }

  Widget _buildDataContent(
    StatsState statsState,
    bool isSmallScreen,
    BoxConstraints constraints,
  ) {
    final stats = statsState.statsData;
    final cardSpacing = isSmallScreen ? 12.0 : 16.0;

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
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: cardSpacing),
          _buildInfoCard(
            title: '총 활동량',
            value: (stats?.totalCalories ?? 0).toString(),
            unit: '칼로리',
            showProgressBar: true,
            progressValue: 0.8,
            progressColor: Colors.grey.shade800,
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: cardSpacing),
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
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: cardSpacing),
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
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: cardSpacing),
          _buildInfoCard(
            title: '걸음',
            value: (stats?.totalSteps ?? 0).toStringAsFixed(0),
            unit: '걸음',
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: cardSpacing),
          _buildInfoCard(
            title: '이동거리',
            value: (stats?.totalDistance ?? 0.0).toStringAsFixed(1),
            unit: '키로미터',
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String unit,
    required bool isSmallScreen,
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
    final cardHeight = isSmallScreen ? 110.0 : 125.0;
    final cardPadding = isSmallScreen ? 16.0 : 20.0;
    final titleStyle = TextStyles.kMedium.copyWith(
      fontSize: isSmallScreen ? 13 : null,
    );
    final valueStyle = TextStyles.kBold.copyWith(
      fontSize: isSmallScreen ? 18 : null,
    );
    final unitStyle = TextStyles.kRegular.copyWith(
      fontSize: isSmallScreen ? 14 : null,
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: cardHeight),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: titleStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: showProgressBar ? 2 : 3,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: value, style: valueStyle),
                          TextSpan(text: ' $unit', style: unitStyle),
                          if (subtitle != null && subtitleUnit != null) ...[
                            TextSpan(text: ' $subtitle', style: valueStyle),
                            TextSpan(text: ' $subtitleUnit', style: unitStyle),
                          ],
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  if (showProgressBar) ...[
                    SizedBox(width: isSmallScreen ? 8 : 16),
                    Flexible(
                      flex: 2,
                      child: Container(
                        height: 20,
                      ), // Placeholder for progress bar
                    ),
                  ],
                  if (!showProgressBar) const Spacer(),
                  if (showButton && buttonText != null)
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 6 : 7,
                        ),
                        decoration: BoxDecoration(
                          color: buttonColor ?? CustomColors.limeGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          buttonText,
                          style: TextStyles.kRegular.copyWith(
                            fontSize: isSmallScreen ? 12 : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
