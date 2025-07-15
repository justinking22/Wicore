import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart' show TextStyles;
import 'package:Wicore/widgets/reusable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '이용약관',
        showBackButton: true,
        onBackPressed: context.pop,
        backgroundColor: CustomColors.lighterGray,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text('1. 이용약관', style: TextStyles.kSemiBold.copyWith(fontSize: 32)),
            const SizedBox(height: 24),

            // Article 1
            const Text('제 1 조 (목적)', style: TextStyles.kSemiBold),
            const SizedBox(height: 12),
            Text(
              '이 약관은 ○○○ ("회사" 또는 "○○○")가 제공하는 ○○○ 및 ○○○ 관련 제반 서비스의 이용과 관련하여 회사와 회원과의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.',
              style: TextStyles.kMedium,
            ),
            const SizedBox(height: 24),

            // Article 2
            const Text('제 2 조 (정의)', style: TextStyles.kSemiBold),

            const SizedBox(height: 12),
            const Text(
              '이 약관에서 사용하는 용어의 정의는 다음과 같습니다.',
              style: TextStyles.kMedium,
            ),
            const SizedBox(height: 8),

            // Definition list
            _buildDefinitionItem(
              '1.',
              '①"서비스"란 함은 구현되는 단말기(PC, TV, 휴대형단말기 등)의 각종 유무선 장치를 포함)와 상관없이 "회원"이 이용할 수 있는 ○○○ 및 ○○○ 관련 제반 서비스를 의미합니다.',
            ),
            _buildDefinitionItem(
              '2.',
              '②"회원"이란 함은 회사의 "서비스"에 접속하여 이 약관에 따라 "회사"와 이용계약을 체결하고 "회사"가 제공하는 "서비스"를 이용하는 고객을 말합니다.',
            ),
            _buildDefinitionItem(
              '3.',
              '③"아이디(ID)"라 함은 "회원"의 식별과 "서비스" 이용을 위하여 "회원"이 정하고 "회사"가 승인하는 문자와 숫자의 조합을 의미합니다.',
            ),
            _buildDefinitionItem(
              '4.',
              '④"비밀번호"라 함은 "회원"이 부여 받은 "아이디"와 일치되는 "회원"임을 확인하고 비밀보호를 위해 "회원" 자신이 정한 문자 또는 숫자의 조합을 의미합니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              number,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(child: Text(text, style: TextStyles.kMedium)),
        ],
      ),
    );
  }
}
