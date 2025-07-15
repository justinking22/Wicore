import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppBar(
                title: '나의 작업 기록',
                leadingAssetPath: 'assets/icons/calendar_icon.png',
                leadingIconSize: 24,
                onLeadingPressed: () {
                  context.push('/calendar-screen');
                },
                trailingButtonIcon: Icons.info_outline,
                showTrailingButton: true,
                onTrailingPressed: () {},
                trailingButtonIconSize: 30,
              ),

              const SizedBox(height: 32),

              // Date navigation section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
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

                  const SizedBox(width: 24),

                  Text(
                    '25.06.15 / 일요일',
                    style: TextStyles.kSemiBold.copyWith(fontSize: 20),
                  ),

                  const SizedBox(width: 24),

                  Container(
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
                ],
              ),

              const SizedBox(height: 40),

              // Empty state content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '아직은',
                      style: TextStyles.kSemiBold.copyWith(fontSize: 32),
                    ),
                    Text(
                      '기록된 내용이 없어요',
                      style: TextStyles.kSemiBold.copyWith(fontSize: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
