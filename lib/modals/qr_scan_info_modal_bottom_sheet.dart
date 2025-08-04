import 'package:Wicore/styles/text_styles.dart';
import 'package:flutter/material.dart';

class QRConnectionModal extends StatelessWidget {
  const QRConnectionModal({Key? key}) : super(key: key);

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
            '기기연결을\n다음의 순서로 해보세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),

          _buildStep(
            '1. 기기 본체에 있는 QR코드를 찾아주세요.\n    QR코드는 이런식으로 생겼어요',
            showQRIcon: true,
          ),
          const SizedBox(height: 24),

          _buildStep('2. 카메라 화면 사각 테두리 안에 QR코드를\n    천천히 가져다 대주세요.'),
          const SizedBox(height: 24),

          _buildStep('3. 자동으로 인식되면 기기가 등록됩니다.'),
          const SizedBox(height: 24),

          _buildStep('4. 물론 연결된 기기는 언제든 연결해제 할\n    수 있습니다.'),
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

  Widget _buildStep(String text, {bool showQRIcon = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: TextStyles.kMedium),
              if (showQRIcon) ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
