import 'package:flutter/material.dart';

class Schedule extends StatelessWidget {
  const Schedule(
      {super.key,
      required this.isScheduleEnabled,
      this.onSetScheduleButtonTap,
      required this.onScheduleCheckboxChange});

  final bool isScheduleEnabled;
  final Function(BuildContext)? onSetScheduleButtonTap;
  final Function(bool?) onScheduleCheckboxChange;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => onSetScheduleButtonTap?.call(context),
          child: const Text('Установить расписание'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const Text(
            'Работать по расписанию',
          ),
          Checkbox(
              onChanged: onScheduleCheckboxChange, value: isScheduleEnabled),
        ]),
      )
    ]);
  }
}
