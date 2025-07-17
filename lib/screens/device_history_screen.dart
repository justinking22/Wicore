import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeviceHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lighterGray,
      appBar: CustomAppBar(
        backgroundColor: CustomColors.lighterGray,
        title: '기기 사용 기록',
        showBackButton: true,
        onBackPressed: context.pop,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            // 2025.03 Section
            _buildMonthHeader('2025.03'),
            SizedBox(height: 8),
            _buildDateItem('2025.03.05', '0000-0000-0000'),

            SizedBox(height: 24),

            // 2025.02 Section
            _buildMonthHeader('2025.02'),
            SizedBox(height: 8),
            _buildDateItem('2025.02.25', '0000-0000-0000'),
            SizedBox(height: 8),
            _buildDateItem('2025.02.18', '0000-0000-0000'),
            SizedBox(height: 8),
            _buildDateItem('2025.02.17', '0000-0000-0000'),
            SizedBox(height: 8),
            _buildDateItem('2025.02.15', '0000-0000-0000'),

            SizedBox(height: 24),

            // 2025.01 Section
            _buildMonthHeader('2025.01'),
            SizedBox(height: 8),
            _buildDateItem('2025.01.30', '0000-0000-0000'),
            SizedBox(height: 8),
            _buildDateItem('2025.01.26', '0000-0000-0000'),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String month) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        month,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateItem(String date, String number) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            number,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Example usage in main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronological List',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DeviceHistoryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(MyApp());
}
