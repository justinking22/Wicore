import 'package:Wicore/styles/text_styles.dart';
import 'package:flutter/material.dart';

class RobotWorkMemoryModal extends StatelessWidget {
  const RobotWorkMemoryModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '로봇과 함께한\n작업 내용을 기록해드려요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            '하루 활동으로 정리해드려요.\n[나의 작업 기록]은 하루를 돌아보는 작은 일지입니다.',
            style: TextStyles.kMedium.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 24),

          _buildBulletPoint('얼마나 칼로리를 소모했는지'),
          const SizedBox(height: 8),
          _buildBulletPoint('로봇이 얼마나 도움을 드렸는지'),
          const SizedBox(height: 8),
          _buildBulletPoint('작업 자세는 어땠는지'),
          const SizedBox(height: 8),
          _buildBulletPoint('등등...'),
          const SizedBox(height: 24),

          Text(
            '기록은 로봇 사용 중로시 자동 저장되며 외부에는 공유되지 않습니다.',
            style: TextStyles.kMedium.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Colors.black, width: 1.0),
              ),
              child: const Text(
                '닫기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, right: 12),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyles.kMedium.copyWith(color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

// Usage example - how to show the modal
void showRobotWorkMemoryModal(BuildContext context) {}
