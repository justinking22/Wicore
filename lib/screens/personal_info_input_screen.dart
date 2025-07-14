import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:with_force/styles/colors.dart';
import 'package:with_force/styles/text_styles.dart';
import 'package:with_force/widgets/reusable_app_bar.dart';
import 'package:with_force/widgets/reusable_button.dart';
import 'package:with_force/widgets/reusable_info_field.dart';
import 'package:with_force/widgets/reusable_picker.dart';

// Main Screen
class PersonalInfoInputScreen extends StatefulWidget {
  @override
  _PersonalInfoInputScreenState createState() =>
      _PersonalInfoInputScreenState();
}

class _PersonalInfoInputScreenState extends State<PersonalInfoInputScreen> {
  String? selectedGender; // Changed: nullable, starts null
  String? selectedMainHeight; // Changed: nullable, starts null
  String? selectedDecimalHeight; // Changed: nullable, starts null
  String? selectedMainWeight; // Changed: nullable, starts null
  String? selectedDecimalWeight; // Changed: nullable, starts null

  final List<String> genders = ['남성', '여성'];
  final List<String> mainHeights = [
    '150',
    '151',
    '152',
    '153',
    '154',
    '155',
    '156',
    '157',
    '158',
    '159',
    '160',
    '161',
    '162',
    '163',
    '164',
    '165',
    '166',
    '167',
    '168',
    '169',
    '170',
    '171',
    '172',
    '173',
    '174',
    '175',
    '176',
    '177',
    '178',
    '179',
    '180',
  ];
  final List<String> decimalHeights = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];
  final List<String> mainWeights = [
    '30',
    '31',
    '32',
    '33',
    '34',
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
    '46',
    '47',
    '48',
    '49',
    '50',
    '51',
    '52',
    '53',
    '54',
    '55',
    '56',
    '57',
    '58',
    '59',
    '60',
    '61',
    '62',
    '63',
    '64',
    '65',
    '66',
    '67',
    '68',
    '69',
    '70',
    '71',
    '72',
    '73',
    '74',
    '75',
    '76',
    '77',
    '78',
    '79',
    '80',
    '81',
    '82',
    '83',
    '84',
    '85',
    '86',
    '87',
    '88',
    '89',
    '90',
    '91',
    '92',
    '93',
    '94',
    '95',
    '96',
    '97',
    '98',
    '99',
    '100',
    '101',
    '102',
    '103',
    '104',
    '105',
    '106',
    '107',
    '108',
    '109',
    '110',
    '111',
    '112',
    '113',
    '114',
    '115',
    '116',
    '117',
    '118',
    '119',
    '120',
    '121',
    '122',
    '123',
    '124',
    '125',
    '126',
    '127',
    '128',
    '129',
    '130',
    '131',
    '132',
    '133',
    '134',
    '135',
    '136',
    '137',
    '138',
    '139',
    '140',
    '141',
    '142',
    '143',
    '144',
    '145',
    '146',
    '147',
    '148',
    '149',
    '150',
    '151',
    '152',
    '153',
    '154',
    '155',
    '156',
    '157',
    '158',
    '159',
    '160',
    '161',
    '162',
    '163',
    '164',
    '165',
    '166',
    '167',
    '168',
    '169',
    '170',
    '171',
    '172',
    '173',
    '174',
    '175',
    '176',
    '177',
    '178',
    '179',
    '180',
    '181',
    '182',
    '183',
    '184',
    '185',
    '186',
    '187',
    '188',
    '189',
    '190',
    '191',
    '192',
    '193',
    '194',
    '195',
    '196',
    '197',
    '198',
    '199',
    '200',
  ];
  final List<String> decimalWeights = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(
              title: '신체정보',
              showTrailingButton: true,
              trailingButtonText: '건너뛰기',
              showBackButton: false,
              onTrailingPressed: () {
                context.push('/phone-input');
              },
            ),
            SizedBox(height: 20),

            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: Text(
                        '정보를 입력주시면\n더 잘 도울 수 있어요',
                        style: TextStyles.kBody,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: Text(
                        '성별, 키, 몸무게 등을 입력주시면\n로봇이 더 잘 도울 수 있어요.',
                        style: TextStyles.kHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // Form Container with Grey Background
            Expanded(
              child: Container(
                color: CustomColors.lighterGray,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Gender Field
                            InfoField(
                              hasUnit: false,
                              label: '성별',
                              value: selectedGender ?? '입력하기',
                              isPlaceholder: selectedGender == null,
                              onTap: () => _showGenderPicker(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Divider(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),

                            // Height Field - Fixed display
                            InfoField(
                              hasUnit: true,
                              label: '키',
                              value:
                                  (selectedMainHeight != null &&
                                          selectedDecimalHeight != null)
                                      ? '${selectedMainHeight}.${selectedDecimalHeight}cm'
                                      : '입력하기',
                              isPlaceholder:
                                  selectedMainHeight == null ||
                                  selectedDecimalHeight == null,
                              onTap: () => _showHeightPicker(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Divider(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),

                            // Weight Field - Fixed display
                            InfoField(
                              hasUnit: true,
                              label: '체중',
                              value:
                                  (selectedMainWeight != null &&
                                          selectedDecimalWeight != null)
                                      ? '${selectedMainWeight}.${selectedDecimalWeight}kg'
                                      : '입력하기',
                              isPlaceholder:
                                  selectedMainWeight == null ||
                                  selectedDecimalWeight == null,
                              onTap: () => _showWeightPicker(),
                            ),
                          ],
                        ),
                      ),

                      Spacer(),

                      CustomButton(
                        text: '다음',
                        isEnabled: true,
                        onPressed: () {},
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ReusablePicker(
          title: '성별',
          items: genders,
          selectedItem:
              selectedGender ?? genders[0], // Default to first item if null
          showDot: false,
          showIndex: false,
          onItemSelected: (String selected) {
            setState(() {
              selectedGender = selected;
            });
          },
        );
      },
    );
  }

  void _showHeightPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DualPicker(
          title: '키 (cm)',
          mainItems: mainHeights,
          decimalItems: decimalHeights,
          selectedMainItem:
              selectedMainHeight ?? mainHeights[20], // Default to 170
          selectedDecimalItem:
              selectedDecimalHeight ?? decimalHeights[0], // Default to 0
          onItemSelected: (String main, String decimal) {
            setState(() {
              selectedMainHeight = main;
              selectedDecimalHeight = decimal;
            });
          },
        );
      },
    );
  }

  void _showWeightPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DualPicker(
          title: '체중 (kg)',
          mainItems: mainWeights,
          decimalItems: decimalWeights,
          selectedMainItem:
              selectedMainWeight ?? mainWeights[39], // Default to 69
          selectedDecimalItem:
              selectedDecimalWeight ?? decimalWeights[0], // Default to 0
          onItemSelected: (String main, String decimal) {
            setState(() {
              selectedMainWeight = main;
              selectedDecimalWeight = decimal;
            });
          },
        );
      },
    );
  }
}
