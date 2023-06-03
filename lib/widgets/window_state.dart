import 'package:flutter/material.dart';

class WindowState extends StatelessWidget {
  const WindowState(
      {super.key, required this.windowState, this.onUpdateButtonTap});

  final String windowState;
  final VoidCallback? onUpdateButtonTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text("Состояние: $windowState",
              style: const TextStyle(color: Colors.black, fontSize: 16)),
          Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ElevatedButton(
                  onPressed: onUpdateButtonTap, child: const Text("Обновить")))
        ]));
  }
}
