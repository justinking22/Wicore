// Dual Picker for Height with decimals
import 'package:Wicore/styles/colors.dart';
import 'package:Wicore/styles/text_styles.dart';
import 'package:flutter/material.dart';

class DualPicker extends StatefulWidget {
  final String title;
  final List<String> mainItems;
  final List<String> decimalItems;
  final String selectedMainItem;
  final String selectedDecimalItem;
  final Function(String, String) onItemSelected;

  const DualPicker({
    Key? key,
    required this.title,
    required this.mainItems,
    required this.decimalItems,
    required this.selectedMainItem,
    required this.selectedDecimalItem,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  _DualPickerState createState() => _DualPickerState();
}

class _DualPickerState extends State<DualPicker> {
  late FixedExtentScrollController _mainScrollController;
  late FixedExtentScrollController _decimalScrollController;
  late String _tempSelectedMainItem;
  late String _tempSelectedDecimalItem;

  @override
  void initState() {
    super.initState();
    _tempSelectedMainItem = widget.selectedMainItem;
    _tempSelectedDecimalItem = widget.selectedDecimalItem;

    int mainIndex = widget.mainItems.indexOf(widget.selectedMainItem);
    int decimalIndex = widget.decimalItems.indexOf(widget.selectedDecimalItem);

    if (mainIndex == -1) mainIndex = 0;
    if (decimalIndex == -1) decimalIndex = 0;

    _mainScrollController = FixedExtentScrollController(initialItem: mainIndex);
    _decimalScrollController = FixedExtentScrollController(
      initialItem: decimalIndex,
    );
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _decimalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CustomColors.darkOverlay,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onItemSelected(
                      _tempSelectedMainItem,
                      _tempSelectedDecimalItem,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      fontFamily: TextStyles.kFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dual Picker
          Expanded(
            child: Stack(
              children: [
                // Selection highlight
                Center(
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                Row(
                  children: [
                    // Main numbers picker
                    // Main numbers picker
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: _mainScrollController,
                        itemExtent: 50,
                        physics: const FixedExtentScrollPhysics(),
                        diameterRatio: 2.0, // Reduced for slight curve
                        perspective: 0.002, // Adjusted for inward curve
                        offAxisFraction: -0.5, // Added to curve inward
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _tempSelectedMainItem = widget.mainItems[index];
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: widget.mainItems.length,
                          builder: (context, index) {
                            bool isSelected =
                                widget.mainItems[index] ==
                                _tempSelectedMainItem;
                            return Container(
                              height: 50,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(
                                right: 24,
                              ), // Increased padding
                              child: Text(
                                widget.mainItems[index],
                                style: TextStyle(
                                  fontSize: 30,
                                  color:
                                      isSelected
                                          ? Colors.black
                                          : Colors.grey[400],
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Decimal point
                    Container(
                      width: 30, // Increased width for more spacing
                      child: const Center(
                        child: Text(
                          '.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Decimal numbers picker
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: _decimalScrollController,
                        itemExtent: 50,
                        physics: const FixedExtentScrollPhysics(),
                        diameterRatio: 2.0, // Reduced for slight curve
                        perspective: 0.002, // Adjusted for inward curve
                        offAxisFraction:
                            0.5, // Added to curve inward (opposite direction)
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _tempSelectedDecimalItem =
                                widget.decimalItems[index];
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: widget.decimalItems.length,
                          builder: (context, index) {
                            bool isSelected =
                                widget.decimalItems[index] ==
                                _tempSelectedDecimalItem;
                            return Container(
                              height: 50,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(
                                left: 24,
                              ), // Increased padding
                              child: Text(
                                widget.decimalItems[index],
                                style: TextStyle(
                                  fontSize: 30,
                                  color:
                                      isSelected
                                          ? Colors.black
                                          : Colors.grey[400],
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
