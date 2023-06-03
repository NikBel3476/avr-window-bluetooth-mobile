import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:avr_bluetooth/widgets/schedule.dart';
import 'package:avr_bluetooth/widgets/time_mode.dart';
import 'package:avr_bluetooth/widgets/window_controls.dart';
import 'package:avr_bluetooth/widgets/window_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'mcu_time.dart';

class ConnectedDeviceView extends StatefulWidget {
  ConnectedDeviceView({super.key, required this.services});

  final List<BluetoothService> services;
  final List<Widget> containers = <Widget>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};
  final _writeController = TextEditingController();

  @override
  ConnectedDeviceViewState createState() => ConnectedDeviceViewState();
}

class ConnectedDeviceViewState extends State<ConnectedDeviceView> {
  late final Timer? _timer;
  late final BluetoothCharacteristic? writeHandler;
  late final BluetoothCharacteristic? readHandler;
  late final StreamSubscription<List<int>>? notificationsStream;
  String _windowState = "Нет данных";
  DateTime _timeState = DateTime.now();
  bool _isTimeModeEnabled = false;
  bool _isScheduleEnabled = false;

  void initWriteHandler(BluetoothCharacteristic characteristic) {
    writeHandler = characteristic;
  }

  void readCharacteristic(BluetoothCharacteristic characteristic) async {
    var value = await characteristic.read();
    setState(() {
      widget.readValues[characteristic.uuid] = value;
    });
  }

  void notificationsSubscribe(BluetoothCharacteristic characteristic) async {
    notificationsStream = characteristic.value.listen((value) {
      if (value.isNotEmpty) {
        setState(() {
          widget.readValues[characteristic.uuid] = value;
        });
        var responseMessage = String.fromCharCodes(value);
        if (responseMessage == 'o') {
          setState(() {
            _windowState = 'Окно открыто';
          });
        } else if (responseMessage == "c") {
          setState(() {
            _windowState = 'Окно закрыто';
          });
        } else if (responseMessage[0] == 't') {
          final timeBytes = value.sublist(1, 5);
          final seconds =
              ByteData.sublistView(Uint8List.fromList(timeBytes)).getInt32(0);
          final minutes = seconds ~/ 60;
          final hours = minutes ~/ 60;
          setState(() {
            _timeState = _timeState.copyWith(
                hour: hours, minute: minutes % 60, second: seconds % 60);
          });
        } else if (responseMessage == "enable_ok") {
          setState(() {
            _isTimeModeEnabled = true;
          });
        } else if (responseMessage == "disable_ok") {
          setState(() {
            _isTimeModeEnabled = false;
          });
        } else if (responseMessage == "schedule_enabled") {
          setState(() {
            _isScheduleEnabled = true;
          });
        } else if (responseMessage == "schedule_disabled") {
          setState(() {
            _isScheduleEnabled = false;
          });
        }
      }
    });
    await characteristic.setNotifyValue(true);
  }

  void setupListeners() {
    for (var service in widget.services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.read) {
          readCharacteristic(characteristic);
        }
        if (characteristic.properties.write) {
          initWriteHandler(characteristic);
        }
        if (characteristic.properties.notify) {
          notificationsSubscribe(characteristic);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    setupListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      writeHandler?.write(utf8.encode("t;"));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    notificationsStream?.cancel();
  }

  void openWindowButtonHandler() {
    writeHandler?.write(utf8.encode("o;"));
  }

  void closeWindowButtonHandler() {
    writeHandler?.write(utf8.encode("c;"));
  }

  void updateWindowStateButtonHandler() async {
    await writeHandler?.write(utf8.encode("s;"));
  }

  void updateMcuTimeButtonHandler() async {
    await writeHandler?.write(utf8.encode("t;"));
  }

  void onSetTimeButtonTap(BuildContext context) async {
    var timeOfDay = TimeOfDay.fromDateTime(_timeState);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: timeOfDay,
    );
    if (selectedTime != null &&
        selectedTime != TimeOfDay.fromDateTime(_timeState)) {
      var totalSeconds = selectedTime.hour * 3600 + selectedTime.minute * 60;
      var timeByteList = Uint8List(4)
        ..buffer.asByteData().setInt32(0, totalSeconds, Endian.big);
      var prefix = Uint8List.fromList(utf8.encode('u'));
      var postfix = Uint8List.fromList(utf8.encode(';'));
      await writeHandler?.write([...prefix, ...timeByteList, ...postfix]);
    }
  }

  void onSetTimeModeButtonTap(BuildContext context) async {
    final selectedActiveTime = await showTimePicker(
        context: context,
        helpText: "Время в открытом положении",
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
        builder: (BuildContext context, Widget? child) {
          return Theme(
              data: Theme.of(context),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!),
              ));
        });

    final selectedDelayTime = await showTimePicker(
        context: context,
        helpText: "Время в закрытом положении",
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
        builder: (BuildContext context, Widget? child) {
          return Theme(
              data: Theme.of(context),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!),
              ));
        });

    if (selectedActiveTime != null && selectedDelayTime != null) {
      var activeTimeSeconds =
          selectedActiveTime.hour * 3600 + selectedActiveTime.minute * 60;
      var delayTimeSeconds =
          selectedDelayTime.hour * 3600 + selectedDelayTime.minute * 60;
      var activeTimeBytes = Uint8List(4)
        ..buffer.asByteData().setInt32(0, activeTimeSeconds, Endian.big);
      var delayTimeBytes = Uint8List(4)
        ..buffer.asByteData().setInt32(0, delayTimeSeconds, Endian.big);
      var prefix = Uint8List.fromList(utf8.encode('r'));
      var postfix = Uint8List.fromList(utf8.encode(';'));
      await writeHandler?.write(
          [...prefix, ...activeTimeBytes, ...delayTimeBytes, ...postfix]);
    }
  }

  void onTimeModeCheckboxChange(bool? _) async {
    if (_isTimeModeEnabled) {
      await writeHandler?.write(utf8.encode('d'));
    } else {
      await writeHandler?.write(utf8.encode('e'));
    }
  }

  void onSetScheduleButtonTap(BuildContext context) async {
    final selectedOpenTime = await showTimePicker(
        context: context,
        helpText: "Время открытия",
        initialTime: TimeOfDay.fromDateTime(DateTime.now()));

    if (selectedOpenTime != null) {
      final selectedCloseTime = await showTimePicker(
          context: context,
          helpText: "Время закрытия",
          initialTime: TimeOfDay.fromDateTime(DateTime.now()));

      if (selectedCloseTime != null) {
        var openTimeSeconds =
            selectedOpenTime.hour * 3600 + selectedOpenTime.minute * 60;
        var closeTimeSeconds =
            selectedCloseTime.hour * 3600 + selectedCloseTime.minute * 60;
        var activeTimeBytes = Uint8List(4)
          ..buffer.asByteData().setInt32(0, openTimeSeconds, Endian.big);
        var delayTimeBytes = Uint8List(4)
          ..buffer.asByteData().setInt32(0, closeTimeSeconds, Endian.big);
        var prefix = Uint8List.fromList(utf8.encode('h'));
        var postfix = Uint8List.fromList(utf8.encode(';'));
        await writeHandler?.write(
            [...prefix, ...activeTimeBytes, ...delayTimeBytes, ...postfix]);
      }
    }
  }

  void onScheduleCheckboxChange(bool? _) async {
    if (_isScheduleEnabled) {
      await writeHandler?.write(utf8.encode('disable_schedule'));
    } else {
      await writeHandler?.write(utf8.encode('enable_schedule'));
    }
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              child:
                  const Text('Обновить', style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                widget.readValues[characteristic.uuid] =
                    await characteristic.read();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('Отправить',
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Отправить"),
                        content: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: widget._writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Отправить"),
                            onPressed: () {
                              characteristic.write(utf8
                                  .encode(widget._writeController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          TextButton(
                            child: const Text("Закрыть"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('Получение данных',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {},
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  List<Widget> _buildServiceCharacteristics(List<BluetoothService> services) {
    return services
        .map((service) => ExpansionTile(
            title: Text(service.uuid.toString()),
            children: service.characteristics
                .where((characteristic) =>
                    characteristic.properties.write ||
                    characteristic.properties.read ||
                    characteristic.properties.notify)
                .map(
                  (characteristic) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(characteristic.uuid.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: _buildReadWriteNotifyButton(characteristic),
                      ),
                      Row(
                        children: [
                          Text(String.fromCharCodes(
                              widget.readValues[characteristic.uuid] ?? [])),
                          Text(
                              '${widget.readValues[characteristic.uuid] ?? []}')
                        ],
                      ),
                      const Divider(),
                    ],
                  ),
                )
                .toList()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        // ...containers,
        WindowControls(
            onOpenButtonTap: openWindowButtonHandler,
            onCloseButtonTap: closeWindowButtonHandler),
        WindowState(
            windowState: _windowState,
            onUpdateButtonTap: updateWindowStateButtonHandler),
        McuTime(
            time: _timeState,
            onUpdateButtonTap: updateMcuTimeButtonHandler,
            onSetTimeButtonTap: onSetTimeButtonTap),
        TimeMode(
            isTimeModeEnabled: _isTimeModeEnabled,
            onSetTimeModeButtonTap: onSetTimeModeButtonTap,
            onTimeModeCheckboxChange: onTimeModeCheckboxChange),
        Schedule(
            isScheduleEnabled: _isScheduleEnabled,
            onSetScheduleButtonTap: onSetScheduleButtonTap,
            onScheduleCheckboxChange: onScheduleCheckboxChange),
        ExpansionTile(
            title: const Text('Другие характеристики'),
            children: _buildServiceCharacteristics(widget.services))
      ],
    );
  }
}
