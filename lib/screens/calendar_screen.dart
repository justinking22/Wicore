import 'package:flutter/material.dart';

class KoreanCalendar extends StatefulWidget {
  @override
  _KoreanCalendarState createState() => _KoreanCalendarState();
}

class _KoreanCalendarState extends State<KoreanCalendar> {
  DateTime today = DateTime.now();
  int currentYear = 2025;
  int currentMonth = 6; // June

  // Highlighted dates (green circles) - these would come from your data
  final Set<int> highlightedDates = {3, 5, 9, 10, 11, 12, 13, 16, 17, 18, 19};

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      currentYear--;
                    });
                  },
                ),
                Text(
                  '${currentYear}년',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      currentYear++;
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // June calendar
                  _buildMonthCalendar(6),
                  SizedBox(height: 40),
                  // July calendar
                  _buildMonthCalendar(7),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(int month) {
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
          _buildCalendarGrid(month),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(int month) {
    DateTime firstDay = DateTime(currentYear, month, 1);
    int daysInMonth = DateTime(currentYear, month + 1, 0).day;
    int firstWeekday =
        firstDay.weekday % 7; // Adjust for Korean week start (Sunday = 0)

    // Get previous month's last days
    DateTime prevMonth = DateTime(currentYear, month - 1, 1);
    int prevMonthDays = DateTime(currentYear, month, 0).day;

    // Get next month's first days
    DateTime nextMonth = DateTime(currentYear, month + 1, 1);

    List<Widget> dayWidgets = [];

    // Add previous month's days (faded)
    for (int i = firstWeekday - 1; i >= 0; i--) {
      int day = prevMonthDays - i;
      dayWidgets.add(_buildDayWidget(day, month - 1, isPrevMonth: true));
    }

    // Add current month's days
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(_buildDayWidget(day, month, isCurrentMonth: true));
    }

    // Add next month's days (faded) to complete the grid
    int totalCells = dayWidgets.length;
    int remainingCells = (7 - (totalCells % 7)) % 7;
    if (remainingCells > 0 && totalCells < 42) {
      // Add more cells to make it look complete
      remainingCells = 42 - totalCells;
    }

    for (int day = 1; day <= remainingCells; day++) {
      dayWidgets.add(_buildDayWidget(day, month + 1, isNextMonth: true));
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
    int month, {
    bool isCurrentMonth = false,
    bool isPrevMonth = false,
    bool isNextMonth = false,
  }) {
    // Calculate the actual date for this day
    DateTime actualDate;
    if (isPrevMonth) {
      actualDate = DateTime(currentYear, month, day);
    } else if (isNextMonth) {
      actualDate = DateTime(currentYear, month, day);
    } else {
      actualDate = DateTime(currentYear, month, day);
    }

    bool isHighlighted =
        isCurrentMonth && month == 6 && highlightedDates.contains(day);
    bool isToday =
        isCurrentMonth &&
        actualDate.year == today.year &&
        actualDate.month == today.month &&
        actualDate.day == today.day;

    // Determine text color
    Color textColor = Colors.black;
    double opacity = 1.0;

    if (isPrevMonth || isNextMonth) {
      textColor = Colors.grey.shade400;
      opacity = 0.5;
    } else {
      // Weekend colors for current month
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
            color: isHighlighted ? customGreen : null,
            shape: BoxShape.circle,
            border:
                isToday && !isHighlighted
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
          ),
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: isHighlighted ? Colors.black : textColor,
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
