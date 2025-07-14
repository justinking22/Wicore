// Enhanced Reusable Picker Component
import 'package:flutter/material.dart';
import 'package:with_force/styles/colors.dart' show CustomColors;
import 'package:with_force/styles/text_styles.dart';

class ReusablePicker extends StatefulWidget {
  final String title;
  final List<String> items;
  final String selectedItem;
  final Function(String) onItemSelected;
  final bool showDot;
  final bool showIndex;

  const ReusablePicker({
    Key? key,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
    this.showDot = true,
    this.showIndex = true,
  }) : super(key: key);

  @override
  _ReusablePickerState createState() => _ReusablePickerState();
}

class _ReusablePickerState extends State<ReusablePicker> {
  late FixedExtentScrollController _scrollController;
  late String _tempSelectedItem;

  @override
  void initState() {
    super.initState();
    _tempSelectedItem = widget.selectedItem;
    int initialIndex = widget.items.indexOf(widget.selectedItem);
    if (initialIndex == -1) initialIndex = 0;
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                    widget.onItemSelected(_tempSelectedItem);
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

          // Picker
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

                // Picker wheel
                ListWheelScrollView.useDelegate(
                  controller: _scrollController,
                  itemExtent: 50,
                  physics: FixedExtentScrollPhysics(),
                  diameterRatio: 1.5,
                  perspective: 0.003,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _tempSelectedItem = widget.items[index];
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.items.length,
                    builder: (context, index) {
                      bool isSelected =
                          widget.items[index] == _tempSelectedItem;

                      // For gender picker (no dot, no index) - center the text
                      if (!widget.showDot && !widget.showIndex) {
                        return Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: Text(
                            widget.items[index],
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  isSelected ? Colors.black : Colors.grey[400],
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                            ),
                          ),
                        );
                      }

                      // For other pickers with dot and/or index
                      return Container(
                        height: 50,
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Main value
                            Text(
                              widget.items[index],
                              style: TextStyle(
                                fontSize: 18,
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
                            // Center section (dot or spacer)
                            if (widget.showDot)
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                SizedBox(width: 6),
                            // Index number
                            if (widget.showIndex)
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isSelected
                                          ? Colors.black
                                          : Colors.grey[400],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Dual Picker for Height with decimals
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
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: _mainScrollController,
                        itemExtent: 50,
                        physics: FixedExtentScrollPhysics(),
                        diameterRatio: 1.5,
                        perspective: 0.003,
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
                              alignment: Alignment.center,
                              child: Text(
                                widget.mainItems[index],
                                style: TextStyle(
                                  fontSize: 18,
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
                      width: 20,
                      child: Center(
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
                        physics: FixedExtentScrollPhysics(),
                        diameterRatio: 1.5,
                        perspective: 0.003,
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
                              alignment: Alignment.center,
                              child: Text(
                                widget.decimalItems[index],
                                style: TextStyle(
                                  fontSize: 18,
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
