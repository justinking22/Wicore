// lib/screens/calendar_screen.dart - UPDATED
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:Wicore/providers/device_provider.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  @override
  _KoreanCalendarState createState() => _KoreanCalendarState();
}

class _KoreanCalendarState extends ConsumerState<CalendarScreen> {
  DateTime today = DateTime.now();
  late int currentYear;
  late int currentMonth;
  late ScrollController _scrollController;
  final double monthHeight = 350.0;

  final List<String> koreanDayNames = ['일', '월', '화', '수', '목', '금', '토'];
  final List<String> koreanMonthNames = [
    '',
    '1월',
    '2월',
    '3월',
    '4월',
    '5월',
    '6월',
    '7월',
    '8월',
    '9월',
    '10월',
    '11월',
    '12월',
  ];

  // Custom green color RGB(204, 255, 56)
  final Color customGreen = Color.fromRGBO(204, 255, 56, 1.0);
  // Lime color for device usage dates
  final Color limeColor = Color.fromRGBO(204, 255, 56, 1.0);

  void _changeYear(int delta) {
    setState(() {
      currentYear += delta;
    });
  }

  // Parse device list to create device usage dates map
  Map<int, Map<int, String>> _parseDeviceUsageDates(
    List<DeviceListItem> devices,
  ) {
    final Map<int, Map<int, String>> deviceUsageDates = {};

    for (final device in devices) {
      final createdDate = DateTime.parse(device.created);

      // Only include dates for the current selected year
      if (createdDate.year == currentYear) {
        final month = createdDate.month;
        final day = createdDate.day;

        deviceUsageDates.putIfAbsent(month, () => {});
        deviceUsageDates[month]![day] = device.status;
      }
    }

    return deviceUsageDates;
  }

  @override
  void initState() {
    super.initState();
    currentYear = today.year;
    currentMonth = today.month;
    _scrollController = ScrollController();

    // Scroll to current month after build with a longer delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure layout is complete
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollToCurrentMonth();
      });
    });
  }

  void _scrollToCurrentMonth() {
    try {
      final double position = (currentMonth - 1) * monthHeight;
      print('📅 Scrolling to month $currentMonth at position $position');

      _scrollController
          .animateTo(
            position,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            print('📅 Scroll animation completed');
          })
          .catchError((error) {
            print('📅 Error during scroll: $error');
          });
    } catch (e) {
      print('📅 Error in _scrollToCurrentMonth: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication state
    final authState = ref.watch(authNotifierProvider);

    if (!authState.isAuthenticated || authState.userData?.username == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          title: Text(
            '달력에서 보기',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                '로그인이 필요합니다',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ UPDATED: Use the new simplified provider
    final devicesAsync = ref.watch(allDevicesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        title: Text(
          '달력에서 보기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: devicesAsync.when(
        data: (devices) {
          print('📅 ✅ Calendar loaded ${devices.length} devices');
          return _buildCalendarContent(devices);
        },
        loading: () {
          print('📅 ⏳ Loading devices for calendar...');
          return Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          print('📅 ❌ Calendar error: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: 16),
                Text(
                  '기기 정보를 불러올 수 없습니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // ✅ UPDATED: Invalidate the new provider
                    ref.invalidate(allDevicesProvider);
                  },
                  child: Text('다시 시도'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarContent(List<DeviceListItem> devices) {
    final deviceUsageDates = _parseDeviceUsageDates(devices);

    // Scroll after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentMonth();
    });

    return Column(
      children: [
        // Year navigation
        Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _changeYear(-1),
                child: _buildYearButton(Icons.chevron_left),
              ),
              const SizedBox(width: 24),
              Text(
                '$currentYear년',
                style: TextStyles.kSemiBold.copyWith(fontSize: 20),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _changeYear(1),
                child: _buildYearButton(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // ✅ UPDATED: Invalidate the new provider
              ref.invalidate(allDevicesProvider);
              await ref.read(allDevicesProvider.future);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  for (int month = 1; month <= 12; month++) ...[
                    _buildMonthCalendar(month, deviceUsageDates),
                    if (month < 12) SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearButton(IconData icon) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromRGBO(194, 194, 194, 1),
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 12)),
    );
  }

  Widget _buildMonthCalendar(
    int month,
    Map<int, Map<int, String>> deviceUsageDates,
  ) {
    // Always use the current selected year
    int displayYear = currentYear;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month title
          Text(
            koreanMonthNames[month],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),

          // Day headers
          Row(
            children:
                koreanDayNames.asMap().entries.map((entry) {
                  int index = entry.key;
                  String day = entry.value;
                  Color dayColor = Colors.black;
                  if (index == 0) dayColor = Colors.blue; // Sunday
                  if (index == 6) dayColor = Colors.blue; // Saturday

                  return Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: dayColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),

          // Calendar grid
          _buildCalendarGrid(month, displayYear, deviceUsageDates),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    int month,
    int year,
    Map<int, Map<int, String>> deviceUsageDates,
  ) {
    DateTime firstDay = DateTime(year, month, 1);
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int firstWeekday = firstDay.weekday % 7; // Sunday = 0

    List<Widget> dayWidgets = [];

    // Only add current month's days
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(
        _buildDayWidget(
          day,
          month,
          year,
          deviceUsageDates,
          isCurrentMonth: true,
        ),
      );
    }

    // Calculate how many empty cells we need at the beginning
    List<Widget> emptyStartCells = [];
    for (int i = 0; i < firstWeekday; i++) {
      emptyStartCells.add(Container(height: 44));
    }

    // Calculate how many empty cells we need at the end to complete the last week
    int totalCells = emptyStartCells.length + dayWidgets.length;
    int remainingInLastWeek = (7 - (totalCells % 7)) % 7;

    List<Widget> emptyEndCells = [];
    for (int i = 0; i < remainingInLastWeek; i++) {
      emptyEndCells.add(Container(height: 44));
    }

    // Combine all cells
    List<Widget> allCells = [
      ...emptyStartCells,
      ...dayWidgets,
      ...emptyEndCells,
    ];

    // Create rows of 7 days each
    List<Widget> rows = [];
    for (int i = 0; i < allCells.length; i += 7) {
      List<Widget> weekDays =
          allCells
              .skip(i)
              .take(7)
              .map((widget) => Expanded(child: widget))
              .toList();

      rows.add(Row(children: weekDays));
    }

    return Column(children: rows);
  }

  Widget _buildDayWidget(
    int day,
    int month,
    int year,
    Map<int, Map<int, String>> deviceUsageDates, {
    bool isCurrentMonth = false,
    bool isPrevMonth = false,
    bool isNextMonth = false,
  }) {
    DateTime actualDate = DateTime(year, month, day);
    String? deviceStatus;
    bool hasDeviceUsage = false;

    if (isCurrentMonth && deviceUsageDates.containsKey(month)) {
      deviceStatus = deviceUsageDates[month]![day];
      hasDeviceUsage = deviceStatus != null;
    }

    bool isActiveDevice = hasDeviceUsage && deviceStatus == 'active';
    bool isExpiredDevice = hasDeviceUsage && deviceStatus == 'expired';
    bool isFutureDate = actualDate.isAfter(today);

    // Determine text color
    Color textColor = Colors.black;
    int weekday = actualDate.weekday;

    // Set weekend color to blue
    if (weekday == DateTime.sunday || weekday == DateTime.saturday) {
      textColor = Colors.blue;
    }

    // Future dates should be faded out
    if (isFutureDate) {
      textColor = textColor.withOpacity(0.3);
    }

    return Container(
      height: 44,
      child: Center(
        child: GestureDetector(
          onTap:
              hasDeviceUsage && !isFutureDate
                  ? () {
                    final selectedDate = DateTime(year, month, day);
                    print('📅 Calendar: Navigating to date: $selectedDate');

                    // Navigate to the separate DateStatsScreen
                    context.push('/date-stats-screen', extra: selectedDate);
                  }
                  : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActiveDevice ? limeColor : null,
              shape: BoxShape.circle,
              border:
                  isExpiredDevice
                      ? Border.all(color: limeColor, width: 2)
                      : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Pretendard',
                  color: isActiveDevice ? Colors.black : textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
