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
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  DateTime selectedDate = DateTime.now();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatsForSelectedDate();
    });
  }

  void _loadStatsForSelectedDate() {
    // Format date as YYYY-MM-DD with zero-padding
    final dateString =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    print('🔧 Loading stats for date: $dateString'); // Debug log
    ref.read(statsNotifierProvider.notifier).loadStatsForDate(dateString);
  }

  // Method for pull-to-refresh
  Future<void> _onRefresh() async {
    try {
      // Add a small delay to show the refresh indicator
      await Future.delayed(const Duration(milliseconds: 300));

      _loadStatsForSelectedDate();

      // Wait for the stats to load (you might need to adjust this based on your provider)
      // This assumes your provider has a way to check if loading is complete
      final statsNotifier = ref.read(statsNotifierProvider.notifier);

      // Wait a bit more to ensure data is loaded
      await Future.delayed(const Duration(milliseconds: 500));

      if (kDebugMode) {
        print(
          '🔧 Pull-to-refresh completed for date: ${selectedDate.toString()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔧 ❌ Error during pull-to-refresh: $e');
      }
    }
  }

  // Alternative using DateFormat (more robust)
  void _loadStatsForSelectedDateAlternative() {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    print('🔧 Loading stats for date: $dateString'); // Debug log
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360 || screenSize.height < 600;

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
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _onRefresh,
          // Use iOS-style indicator
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          strokeWidth: 2.0,
          displacement: 40.0,
          // Custom refresh indicator builder for iOS-style
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
              final verticalPadding = isSmallScreen ? 8.0 : 12.0;

              return CustomScrollView(
                // Always allow scrolling for pull-to-refresh to work
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        verticalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date navigation - made more responsive
                          _buildDateNavigation(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          _buildContent(statsState, isSmallScreen, constraints),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
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

  Widget _buildContent(
    StatsState statsState,
    bool isSmallScreen,
    BoxConstraints constraints,
  ) {
    if (statsState.isLoading) {
      return SizedBox(
        height: constraints.maxHeight * 0.6,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Handle errors
    if (statsState.hasError) {
      final errorMessage = statsState.error?.toLowerCase() ?? '';

      // Check if it's a "no data available" type error
      if (errorMessage.contains('no data') ||
          errorMessage.contains('not found') ||
          errorMessage.contains('no stats available') ||
          errorMessage.contains('404') ||
          errorMessage.contains('데이터가 없') ||
          errorMessage.contains('기록이 없') ||
          errorMessage.contains('no records') ||
          errorMessage.contains('empty') ||
          errorMessage.contains('null')) {
        // Show the "no data" widget for data-related errors
        return SizedBox(
          height: constraints.maxHeight * 0.6,
          child: Column(
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
          ),
        );
      }

      // Check for network/connection errors
      if (errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('네트워크') ||
          errorMessage.contains('연결') ||
          errorMessage.contains('인터넷')) {
        return SizedBox(
          height: constraints.maxHeight * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  '네트워크 오류',
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
                  '인터넷 연결을 확인해주세요',
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
          ),
        );
      }

      // Check for authentication errors
      if (errorMessage.contains('unauthorized') ||
          errorMessage.contains('auth') ||
          errorMessage.contains('login') ||
          errorMessage.contains('401') ||
          errorMessage.contains('403') ||
          errorMessage.contains('권한') ||
          errorMessage.contains('인증')) {
        return SizedBox(
          height: constraints.maxHeight * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  '인증 오류',
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
                  '다시 로그인해주세요',
                  style: TextStyles.kRegular,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login or refresh auth
                  context.go('/login');
                },
                child: const Text('로그인'),
              ),
            ],
          ),
        );
      }

      // Check for server errors
      if (errorMessage.contains('500') ||
          errorMessage.contains('server') ||
          errorMessage.contains('internal') ||
          errorMessage.contains('서버')) {
        return SizedBox(
          height: constraints.maxHeight * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  '서버 오류',
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
                  '잠시 후 다시 시도해주세요',
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
          ),
        );
      }

      // For any other error, show the "no data" widget as fallback
      return SizedBox(
        height: constraints.maxHeight * 0.6,
        child: Column(
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
        ),
      );
    }

    // Handle no data case (when API succeeds but returns empty/null data)
    if (!statsState.hasData) {
      return SizedBox(
        height: constraints.maxHeight * 0.6,
        child: Column(
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
        ),
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

    return Column(
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
          stripeWidth: ((stats?.lmaCalories ?? 0) / (stats?.totalCalories ?? 1))
              .clamp(0.0, 0.8),
          stripeColor: CustomColors.limeGreen,
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: cardSpacing),
        _buildInfoCard(
          isSmallScreen: isSmallScreen,
          title: '호흡(분당)',
          value: _formatBreathRange(stats?.breathMean, stats?.breathStd),
          unit: '회',
          showProgressBar: true,
          // Update these values to represent start and end points of range
          progressMinValue:
              ((stats?.breathMean ?? 0.0) - (stats?.breathStd ?? 0.0)).clamp(
                0.0,
                40.0,
              ) /
              40.0,
          progressValue:
              ((stats?.breathMean ?? 0.0) + (stats?.breathStd ?? 0.0)).clamp(
                0.0,
                40.0,
              ) /
              40.0,
          progressColor: Colors.grey.shade800,
        ),

        const SizedBox(height: 16),
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
        // Add bottom padding to ensure last item is not cut off
        SizedBox(height: isSmallScreen ? 16 : 24),
      ],
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: showProgressBar ? 3 : 4,
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
                    SizedBox(
                      width: isSmallScreen ? 16 : 24,
                    ), // Increased spacing to push progress bar more to the right
                    Expanded(
                      flex: 2,
                      child: _buildProgressBar(
                        progressValue,
                        progressMinValue,
                        progressColor,
                        hasStripes,
                        stripeWidth,
                        stripeColor,
                        title,
                        isSmallScreen,
                      ),
                    ),
                  ],
                  if (showButton && buttonText != null) ...[
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      flex: 1,
                      child: Center(
                        // Center the button within its available space
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth:
                                isSmallScreen
                                    ? 60
                                    : 70, // Minimum width for the button
                            maxWidth: double.infinity,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: isSmallScreen ? 6 : 7,
                          ),
                          decoration: BoxDecoration(
                            color: buttonColor ?? CustomColors.limeGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            buttonText,
                            style: TextStyles.kRegular.copyWith(
                              fontSize:
                                  isSmallScreen
                                      ? 11
                                      : 12, // Slightly smaller font to fit better
                            ),
                            textAlign:
                                TextAlign
                                    .center, // Center the text within the button
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (!showProgressBar && !showButton) const Spacer(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    double progressValue,
    double progressMinValue,
    Color? progressColor,
    bool hasStripes,
    double stripeWidth,
    Color? stripeColor,
    String title,
    bool isSmallScreen,
  ) {
    final barHeight = isSmallScreen ? 16.0 : 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        return Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Base background (gray)
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Only show range bar if this is the breath card
              if (title == '호흡(분당)')
                Positioned(
                  left: progressMinValue * containerWidth,
                  child: Container(
                    width: (progressValue - progressMinValue) * containerWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: progressColor ?? Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

              // Show normal progress bar for other cases
              if (title != '호흡(분당)')
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressValue,
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: progressColor ?? Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

              // Keep existing stripe logic for other progress bars
              if (hasStripes && stripeWidth > 0 && title != '호흡(분당)')
                Positioned(
                  left:
                      (progressValue - stripeWidth).clamp(0.0, 1.0) *
                      containerWidth,
                  child: Container(
                    width: stripeWidth * containerWidth,
                    height: barHeight,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          Container(color: CustomColors.limeGreen),
                          CustomPaint(
                            painter: DiagonalStripesPainter(
                              color: Colors.black,
                              strokeWidth: 1.0,
                              spacing: 6.0,
                              isReversed: true,
                            ),
                            size: Size.infinite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
