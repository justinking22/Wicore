import 'package:Wicore/styles/text_styles.dart';
import 'package:flutter/material.dart';

class KoreanCalendar extends StatefulWidget {
  @override
  _KoreanCalendarState createState() => _KoreanCalendarState();
}

class _KoreanCalendarState extends State<KoreanCalendar> {
  DateTime today = DateTime.now();
  late int currentYear;
  late int currentMonth;

  // Highlighted dates (green circles) - these would come from your data
  // For June: 3, 5, 9, 10, 11, 12, 13, 16, 17, 18, 19
  final Map<int, Set<int>> highlightedDates = {
    6: {3, 5, 9, 10, 11, 12, 13, 16, 17, 18, 19},
    7: {}, // No highlighted dates for July in the example
  };

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
  // Lime color for today's date
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

  @override
  Widget build(BuildContext context) {
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
      body: Column(
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
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 20,
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
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Show all 12 months of the selected year
                  for (int month = 1; month <= 12; month++) ...[
                    _buildMonthCalendar(month),
                    if (month < 12) SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(int month) {
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
          _buildCalendarGrid(month, displayYear),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(int month, int year) {
    DateTime firstDay = DateTime(year, month, 1);
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int firstWeekday =
        firstDay.weekday % 7; // Adjust for Korean week start (Sunday = 0)

    // Get previous month's last days
    int prevMonthDays = DateTime(year, month, 0).day;

    List<Widget> dayWidgets = [];

    // Add previous month's days (faded)
    for (int i = firstWeekday - 1; i >= 0; i--) {
      int day = prevMonthDays - i;
      int prevMonth = month - 1;
      int prevYear = year;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear = year - 1;
      }
      dayWidgets.add(
        _buildDayWidget(day, prevMonth, prevYear, isPrevMonth: true),
      );
    }

    // Add current month's days
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(_buildDayWidget(day, month, year, isCurrentMonth: true));
    }

    // Add next month's days (faded) to complete the grid
    int totalCells = dayWidgets.length;
    int remainingCells = (7 - (totalCells % 7)) % 7;
    if (remainingCells > 0 && totalCells < 42) {
      // Add more cells to make it look complete
      remainingCells = 42 - totalCells;
    }

    for (int day = 1; day <= remainingCells; day++) {
      int nextMonth = month + 1;
      int nextYear = year;
      if (nextMonth == 13) {
        nextMonth = 1;
        nextYear = year + 1;
      }
      dayWidgets.add(
        _buildDayWidget(day, nextMonth, nextYear, isNextMonth: true),
      );
    }

    // Create rows of 7 days each
    List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(
        Row(
          children:
              dayWidgets
                  .skip(i)
                  .take(7)
                  .map((widget) => Expanded(child: widget))
                  .toList(),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDayWidget(
    int day,
    int month,
    int year, {
    bool isCurrentMonth = false,
    bool isPrevMonth = false,
    bool isNextMonth = false,
  }) {
    // Calculate the actual date for this day
    DateTime actualDate = DateTime(year, month, day);

    bool isHighlighted =
        isCurrentMonth &&
        highlightedDates.containsKey(month) &&
        highlightedDates[month]!.contains(day);

    bool isToday =
        actualDate.year == today.year &&
        actualDate.month == today.month &&
        actualDate.day == today.day;

    // Check if this date is in the future
    bool isFutureDate = actualDate.isAfter(today);

    // Determine text color
    Color textColor = Colors.black;
    double opacity = 1.0;

    if (isPrevMonth || isNextMonth) {
      textColor = Colors.grey.shade400;
      opacity = 0.5;
    } else if (isFutureDate) {
      // Future dates should be faded out
      textColor = Colors.grey.shade400;
      opacity = 0.3;
    } else {
      // Weekend colors for current month (only for past/present dates)
      int weekday = actualDate.weekday;
      if (weekday == DateTime.sunday) {
        textColor = Colors.blue;
      } else if (weekday == DateTime.saturday) {
        textColor = Colors.blue;
      }
    }

    return Container(
      height: 44,
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isToday ? limeColor : null,
            shape: BoxShape.circle,
            border:
                isHighlighted ? Border.all(color: limeColor, width: 2) : null,
          ),
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isToday
                          ? Colors.black
                          : (isHighlighted ? textColor : textColor),
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
