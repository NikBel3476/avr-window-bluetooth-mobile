import 'package:flutter/material.dart';

class WindowControls extends StatelessWidget {
  const WindowControls(
      {super.key, this.onOpenButtonTap, this.onCloseButtonTap});

  final VoidCallback? onOpenButtonTap;
  final VoidCallback? onCloseButtonTap;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      ElevatedButton(
          onPressed: onOpenButtonTap, child: const Text("Открыть окно")),
      ElevatedButton(
          onPressed: onCloseButtonTap, child: const Text("Закрыть окно"))
    ]);
  }
}
