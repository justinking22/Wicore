import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:Wicore/models/device_list_response_model.dart';
import 'package:Wicore/providers/device_provider.dart';
import 'package:Wicore/providers/authentication_provider.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeviceHistoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Debug authentication state
    final authState = ref.watch(authNotifierProvider);

    print('📱 DeviceHistoryScreen - Auth state: ${authState.isAuthenticated}');
    print('📱 DeviceHistoryScreen - Username: ${authState.userData?.username}');
    print('📱 DeviceHistoryScreen - User data: ${authState.userData}');

    // Show authentication error if not logged in
    if (!authState.isAuthenticated || authState.userData?.username == null) {
      print('📱 ❌ DeviceHistoryScreen - Authentication check failed');

      return Scaffold(
        backgroundColor: CustomColors.lighterGray,
        appBar: CustomAppBar(
          backgroundColor: CustomColors.lighterGray,
          title: '기기 사용 기록',
          showBackButton: true,
          onBackPressed: context.pop,
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: 16),
                Text(
                  '로그인이 필요합니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Auth: ${authState.isAuthenticated}, Username: ${authState.userData?.username}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to login or refresh auth state
                    context.go('/login'); // Adjust route as needed
                  },
                  child: Text('로그인'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    print(
      '📱 ✅ DeviceHistoryScreen - Authentication passed, loading devices...',
    );

    // Only watch device list if authenticated
    final devicesAsync = ref.watch(userDeviceListProvider);

    return Scaffold(
      backgroundColor: CustomColors.lighterGray,
      appBar: CustomAppBar(
        backgroundColor: CustomColors.lighterGray,
        title: '기기 사용 기록',
        showBackButton: true,
        onBackPressed: context.pop,
      ),
      body: SafeArea(
        child: devicesAsync.when(
          data: (devices) {
            print('📱 ✅ Devices loaded: ${devices.length} devices');

            if (devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      '기기 사용 기록이 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final groupedDevices = _groupDevicesByMonth(devices);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userDeviceListProvider);
              },
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: _buildGroupedDeviceList(groupedDevices),
              ),
            );
          },
          loading: () {
            print('📱 ⏳ Loading devices...');
            return Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            print('📱 ❌ Device list error: $error');
            print('📱 ❌ Stack trace: $stackTrace');

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
                  SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
            );
          },
        ),
      ),
    );
  }

  // Group devices by year-month
  Map<String, List<DeviceListItem>> _groupDevicesByMonth(
    List<DeviceListItem> devices,
  ) {
    final grouped = <String, List<DeviceListItem>>{};

    for (final device in devices) {
      final createdDate = DateTime.parse(device.created);
      final yearMonth =
          '${createdDate.year}.${createdDate.month.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(yearMonth, () => []).add(device);
    }

    // Sort months in descending order (newest first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final result = <String, List<DeviceListItem>>{};
    for (final key in sortedKeys) {
      // Sort devices within each month by created date (newest first)
      final sortedDevices =
          grouped[key]!..sort((a, b) {
            final dateA = DateTime.parse(a.created);
            final dateB = DateTime.parse(b.created);
            return dateB.compareTo(dateA);
          });
      result[key] = sortedDevices;
    }

    return result;
  }

  // Build the grouped device list
  List<Widget> _buildGroupedDeviceList(
    Map<String, List<DeviceListItem>> groupedDevices,
  ) {
    final widgets = <Widget>[];
    final months = groupedDevices.keys.toList();

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final devices = groupedDevices[month]!;

      // Add month header
      widgets.add(_buildMonthHeader(month));
      widgets.add(SizedBox(height: 8));

      // Add devices for this month
      for (int j = 0; j < devices.length; j++) {
        final device = devices[j];
        widgets.add(_buildDateItem(device));

        // Add spacing between items, but not after the last item in the month
        if (j < devices.length - 1) {
          widgets.add(SizedBox(height: 8));
        }
      }

      // Add spacing between months, but not after the last month
      if (i < months.length - 1) {
        widgets.add(SizedBox(height: 24));
      }
    }

    return widgets;
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

  Widget _buildDateItem(DeviceListItem device) {
    // Parse the created date
    final createdDate = DateTime.parse(device.created);
    final formattedDate =
        '${createdDate.year}.${createdDate.month.toString().padLeft(2, '0')}.${createdDate.day.toString().padLeft(2, '0')}';

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                device.deviceId,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return '활성';
      case 'expired':
        return '만료됨';
      default:
        return '알 수 없음';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
