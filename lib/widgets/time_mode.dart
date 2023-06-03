import 'package:flutter/material.dart';

class TimeMode extends StatelessWidget {
  const TimeMode(
      {super.key,
      required this.isTimeModeEnabled,
      this.onSetTimeModeButtonTap,
      required this.onTimeModeCheckboxChange});

  final bool isTimeModeEnabled;
  final Function(BuildContext)? onSetTimeModeButtonTap;
  final Function(bool?) onTimeModeCheckboxChange;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => onSetTimeModeButtonTap?.call(context),
          child: const Text('Установить режим работы'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const Text(
            'Работать по режиму',
          ),
          Checkbox(
              onChanged: onTimeModeCheckboxChange, value: isTimeModeEnabled),
        ]),
      ),
    ]);
  }
}
