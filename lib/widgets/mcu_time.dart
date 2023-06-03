import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class McuTime extends StatelessWidget {
  const McuTime(
      {super.key,
      required this.time,
      this.onUpdateButtonTap,
      this.onSetTimeButtonTap});

  final DateTime time;
  final VoidCallback? onUpdateButtonTap;
  final Function(BuildContext)? onSetTimeButtonTap;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text("Время: ${DateFormat("HH:mm:ss").format(time)}",
                style: const TextStyle(color: Colors.black, fontSize: 16)),
            Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ElevatedButton(
                    onPressed: onUpdateButtonTap,
                    child: const Text("Обновить")))
          ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => onSetTimeButtonTap?.call(context),
          child: const Text('Изменить время'),
        ),
      ),
    ]);
  }
}
