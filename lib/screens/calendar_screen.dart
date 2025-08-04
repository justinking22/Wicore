import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:Wicore/providers/device_provider.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KoreanCalendar extends ConsumerStatefulWidget {
  @override
  _KoreanCalendarState createState() => _KoreanCalendarState();
}

class _KoreanCalendarState extends ConsumerState<KoreanCalendar> {
  DateTime today = DateTime.now();
  late int currentYear;
  late int currentMonth;

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

  @override
  void initState() {
    super.initState();
    currentYear = today.year;
    currentMonth = today.month;
  }

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

    // Watch device list from API
    final devicesAsync = ref.watch(userDeviceListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // Add this line
        surfaceTintColor: Colors.transparent, // Add this line too
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
        data: (devices) => _buildCalendarContent(devices),
        loading: () => Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
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
                      ref.invalidate(userDeviceListProvider);
                    },
                    child: Text('다시 시도'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildCalendarContent(List<DeviceListItem> devices) {
    final deviceUsageDates = _parseDeviceUsageDates(devices);

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
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(194, 194, 194, 1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '$currentYear년',
                style: TextStyles.kSemiBold.copyWith(fontSize: 20),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _changeYear(1),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(194, 194, 194, 1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userDeviceListProvider);
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Show all 12 months of the selected year
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
    // Calculate the actual date for this day
    DateTime actualDate = DateTime(year, month, day);

    // Check device usage status for this date
    String? deviceStatus;
    bool hasDeviceUsage = false;

    if (isCurrentMonth && deviceUsageDates.containsKey(month)) {
      deviceStatus = deviceUsageDates[month]![day];
      hasDeviceUsage = deviceStatus != null;
    }

    bool isActiveDevice = hasDeviceUsage && deviceStatus == 'active';
    bool isExpiredDevice = hasDeviceUsage && deviceStatus == 'expired';

    // Check if this date is in the future
    bool isFutureDate = actualDate.isAfter(today);

    // Determine text color - consistent across all months
    Color textColor = Colors.black;

    // Weekend colors always apply (regardless of past/future)
    int weekday = actualDate.weekday;
    if (weekday == DateTime.sunday || weekday == DateTime.saturday) {
      textColor = Colors.blue;
    }

    // Future dates should be faded out but keep weekend colors
    if (isFutureDate &&
        weekday != DateTime.sunday &&
        weekday != DateTime.saturday) {
      textColor = Colors.grey.shade400;
    }

    return Container(
      height: 44,
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActiveDevice ? limeColor : null,
            shape: BoxShape.circle,
            border:
                isExpiredDevice ? Border.all(color: limeColor, width: 2) : null,
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
    );
  }
}
