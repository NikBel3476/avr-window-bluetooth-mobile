import 'package:avr_bluetooth/widgets/available_device_list.dart';
import 'package:avr_bluetooth/widgets/connected_device_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AVR window',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'AVR window'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  // final _writeController = TextEditingController();
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  // BluetoothCharacteristic? writeHandler;
  // BluetoothCharacteristic? readHandler;
  // Timer? _timer;
  // String _windowState = "Нет данных";
  // DateTime _timeState = DateTime.now();
  // bool _isTimeModeEnabled = false;
  // bool _isScheduleEnabled = false;

  _addDeviceToList(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceToList(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceToList(result.device);
      }
    });
    widget.flutterBlue.startScan();
    // _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   writeHandler?.write(utf8.encode("t;"));
    // });
  }

  @override
  void dispose() {
    super.dispose();
    // _timer?.cancel();
  }

  void onDeviceConnectButtonTap(BluetoothDevice device) async {
    await widget.flutterBlue.stopScan();
    try {
      await device.connect();
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
      }
    } finally {
      _services = await device.discoverServices();
    }
    setState(() {
      _connectedDevice = device;
    });
  }

  // ListView _buildListViewOfDevices() {
  //   List<Widget> containers = <Widget>[];
  //   for (BluetoothDevice device in widget.devicesList) {
  //     containers.add(
  //       SizedBox(
  //         height: 50,
  //         child: Row(
  //           children: <Widget>[
  //             Expanded(
  //               child: Column(
  //                 children: <Widget>[
  //                   Text(device.name == ''
  //                       ? '(неизвестное устройство)'
  //                       : device.name),
  //                   Text(device.id.toString()),
  //                 ],
  //               ),
  //             ),
  //             TextButton(
  //                 child: const Text(
  //                   'Подключиться',
  //                   style: TextStyle(color: Colors.blue),
  //                 ),
  //                 onPressed: () => onDeviceConnectButtonTap(device)),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  //
  //   return ListView(
  //     padding: const EdgeInsets.all(8),
  //     children: <Widget>[
  //       ...containers,
  //     ],
  //   );
  // }
  //
  // List<ButtonTheme> _buildReadWriteNotifyButton(
  //     BluetoothCharacteristic characteristic) {
  //   List<ButtonTheme> buttons = <ButtonTheme>[];
  //
  //   void readCharacteristic(BluetoothCharacteristic characteristic) async {
  //     var value = await characteristic.read();
  //     setState(() {
  //       widget.readValues[characteristic.uuid] = value;
  //     });
  //   }
  //
  //   void initWriteHandler(BluetoothCharacteristic characteristic) {
  //     writeHandler = characteristic;
  //   }
  //
  //   void notificationsSubscribe(BluetoothCharacteristic characteristic) async {
  //     characteristic.value.listen((value) {
  //       if (value.isNotEmpty) {
  //         setState(() {
  //           widget.readValues[characteristic.uuid] = value;
  //         });
  //         var responseMessage = String.fromCharCodes(value);
  //         if (responseMessage == 'o') {
  //           setState(() {
  //             _windowState = 'Окно открыто';
  //           });
  //         } else if (responseMessage == "c") {
  //           setState(() {
  //             _windowState = 'Окно закрыто';
  //           });
  //         } else if (responseMessage[0] == 't') {
  //           final timeBytes = utf8.encode(responseMessage.substring(1));
  //           final byteData =
  //               ByteData.sublistView(Uint8List.fromList(timeBytes));
  //           final seconds = byteData.getInt32(0);
  //           final minutes = seconds ~/ 60;
  //           final hours = minutes ~/ 60;
  //           setState(() {
  //             _timeState = _timeState.copyWith(
  //                 hour: hours, minute: minutes % 60, second: seconds % 60);
  //           });
  //         } else if (responseMessage == "enable_ok") {
  //           setState(() {
  //             _isTimeModeEnabled = true;
  //           });
  //         } else if (responseMessage == "disable_ok") {
  //           setState(() {
  //             _isTimeModeEnabled = false;
  //           });
  //         } else if (responseMessage == "schedule_enabled") {
  //           setState(() {
  //             _isScheduleEnabled = true;
  //           });
  //         } else if (responseMessage == "schedule_disabled") {
  //           setState(() {
  //             _isScheduleEnabled = false;
  //           });
  //         }
  //       }
  //     });
  //     await characteristic.setNotifyValue(true);
  //   }
  //
  //   if (characteristic.properties.read) {
  //     readCharacteristic(characteristic);
  //
  //     buttons.add(
  //       ButtonTheme(
  //         minWidth: 10,
  //         height: 20,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 4),
  //           child: TextButton(
  //             child:
  //                 const Text('Обновить', style: TextStyle(color: Colors.blue)),
  //             onPressed: () async {
  //               widget.readValues[characteristic.uuid] =
  //                   await characteristic.read();
  //             },
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //   if (characteristic.properties.write) {
  //     initWriteHandler(characteristic);
  //
  //     buttons.add(
  //       ButtonTheme(
  //         minWidth: 10,
  //         height: 20,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 4),
  //           child: ElevatedButton(
  //             child: const Text('Отправить',
  //                 style: TextStyle(color: Colors.white)),
  //             onPressed: () async {
  //               await showDialog(
  //                   context: context,
  //                   builder: (BuildContext context) {
  //                     return AlertDialog(
  //                       title: const Text("Отправить"),
  //                       content: Row(
  //                         children: <Widget>[
  //                           Expanded(
  //                             child: TextField(
  //                               controller: _writeController,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       actions: <Widget>[
  //                         TextButton(
  //                           child: const Text("Отправить"),
  //                           onPressed: () {
  //                             characteristic.write(
  //                                 utf8.encode(_writeController.value.text));
  //                             Navigator.pop(context);
  //                           },
  //                         ),
  //                         TextButton(
  //                           child: const Text("Закрыть"),
  //                           onPressed: () {
  //                             Navigator.pop(context);
  //                           },
  //                         ),
  //                       ],
  //                     );
  //                   });
  //             },
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //   if (characteristic.properties.notify) {
  //     notificationsSubscribe(characteristic);
  //     print('notify subscriber');
  //     buttons.add(
  //       ButtonTheme(
  //         minWidth: 10,
  //         height: 20,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 4),
  //           child: ElevatedButton(
  //             child: const Text('Получение данных',
  //                 style: TextStyle(color: Colors.white)),
  //             onPressed: () async {
  //               // characteristic.value.listen((value) {
  //               //   setState(() {
  //               //     widget.readValues[characteristic.uuid] = value;
  //               //   });
  //               // });
  //             },
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //
  //   return buttons;
  // }
  //
  // ListView _buildConnectDeviceView() {
  //   List<Widget> containers = <Widget>[];
  //
  //   void openWindowButtonHandler() {
  //     writeHandler?.write(utf8.encode("o;"));
  //   }
  //
  //   void closeWindowButtonHandler() {
  //     writeHandler?.write(utf8.encode("c;"));
  //   }
  //
  //   void updateWindowStateButtonHandler() async {
  //     await writeHandler?.write(utf8.encode("s;"));
  //   }
  //
  //   void updateMcuTimeButtonHandler() async {
  //     await writeHandler?.write(utf8.encode("t;"));
  //   }
  //
  //   void onSetTimeButtonTap(BuildContext context) async {
  //     var timeOfDay = TimeOfDay.fromDateTime(_timeState);
  //     final selectedTime = await showTimePicker(
  //       context: context,
  //       initialTime: timeOfDay,
  //     );
  //     if (selectedTime != null &&
  //         selectedTime != TimeOfDay.fromDateTime(_timeState)) {
  //       var totalSeconds = selectedTime.hour * 3600 + selectedTime.minute * 60;
  //       var timeByteList = Uint8List(4)
  //         ..buffer.asByteData().setInt32(0, totalSeconds, Endian.big);
  //       var prefix = Uint8List.fromList(utf8.encode('u'));
  //       var postfix = Uint8List.fromList(utf8.encode(';'));
  //       await writeHandler?.write([...prefix, ...timeByteList, ...postfix]);
  //     }
  //   }
  //
  //   void onSetTimeModeButtonTap(BuildContext context) async {
  //     final selectedActiveTime = await showTimePicker(
  //         context: context,
  //         helpText: "Время в открытом положении",
  //         initialTime: TimeOfDay.fromDateTime(DateTime.now()));
  //
  //     final selectedDelayTime = await showTimePicker(
  //         context: context,
  //         helpText: "Время в закрытом положении",
  //         initialTime: TimeOfDay.fromDateTime(DateTime.now()));
  //
  //     if (selectedActiveTime != null && selectedDelayTime != null) {
  //       var activeTimeSeconds =
  //           selectedActiveTime.hour * 3600 + selectedActiveTime.minute * 60;
  //       var delayTimeSeconds =
  //           selectedDelayTime.hour * 3600 + selectedDelayTime.minute * 60;
  //       var activeTimeBytes = Uint8List(4)
  //         ..buffer.asByteData().setInt32(0, activeTimeSeconds, Endian.big);
  //       var delayTimeBytes = Uint8List(4)
  //         ..buffer.asByteData().setInt32(0, delayTimeSeconds, Endian.big);
  //       var prefix = Uint8List.fromList(utf8.encode('r'));
  //       var postfix = Uint8List.fromList(utf8.encode(';'));
  //       await writeHandler?.write(
  //           [...prefix, ...activeTimeBytes, ...delayTimeBytes, ...postfix]);
  //     }
  //   }
  //
  //   void onTimeModeCheckboxChange(bool? _) async {
  //     if (_isTimeModeEnabled) {
  //       await writeHandler?.write(utf8.encode('d'));
  //     } else {
  //       await writeHandler?.write(utf8.encode('e'));
  //     }
  //   }
  //
  //   void onScheduleCheckboxChange(bool? _) async {
  //     if (_isScheduleEnabled) {
  //       await writeHandler?.write(utf8.encode('disable_schedule'));
  //     } else {
  //       await writeHandler?.write(utf8.encode('enable_schedule'));
  //     }
  //   }
  //
  //   void onSetScheduleButtonTap(BuildContext context) async {
  //     final selectedOpenTime = await showTimePicker(
  //         context: context,
  //         helpText: "Время открытия",
  //         initialTime: TimeOfDay.fromDateTime(DateTime.now()));
  //
  //     if (selectedOpenTime != null) {
  //       final selectedCloseTime = await showTimePicker(
  //           context: context,
  //           helpText: "Время закрытия",
  //           initialTime: TimeOfDay.fromDateTime(DateTime.now()));
  //
  //       if (selectedCloseTime != null) {
  //         var openTimeSeconds =
  //             selectedOpenTime.hour * 3600 + selectedOpenTime.minute * 60;
  //         var closeTimeSeconds =
  //             selectedCloseTime.hour * 3600 + selectedCloseTime.minute * 60;
  //         var activeTimeBytes = Uint8List(4)
  //           ..buffer.asByteData().setInt32(0, openTimeSeconds, Endian.big);
  //         var delayTimeBytes = Uint8List(4)
  //           ..buffer.asByteData().setInt32(0, closeTimeSeconds, Endian.big);
  //         var prefix = Uint8List.fromList(utf8.encode('h'));
  //         var postfix = Uint8List.fromList(utf8.encode(';'));
  //         await writeHandler?.write(
  //             [...prefix, ...activeTimeBytes, ...delayTimeBytes, ...postfix]);
  //       }
  //     }
  //   }
  //
  //   for (BluetoothService service in _services) {
  //     List<Widget> characteristicsWidget = <Widget>[];
  //
  //     for (BluetoothCharacteristic characteristic in service.characteristics) {
  //       if (characteristic.properties.write ||
  //           characteristic.properties.read ||
  //           characteristic.properties.notify) {
  //         characteristicsWidget.add(
  //           Align(
  //             alignment: Alignment.centerLeft,
  //             child: Column(
  //               children: <Widget>[
  //                 Row(
  //                   children: <Widget>[
  //                     Text(characteristic.uuid.toString(),
  //                         style: const TextStyle(fontWeight: FontWeight.bold)),
  //                   ],
  //                 ),
  //                 Row(
  //                   children: <Widget>[
  //                     ..._buildReadWriteNotifyButton(characteristic),
  //                   ],
  //                 ),
  //                 Row(
  //                   children: <Widget>[
  //                     Text(
  //                         '${String.fromCharCodes(widget.readValues[characteristic.uuid] ?? [])}${widget.readValues[characteristic.uuid] ?? []}')
  //                   ],
  //                 ),
  //                 const Divider(),
  //               ],
  //             ),
  //           ),
  //         );
  //       }
  //     }
  //     if (characteristicsWidget.isNotEmpty) {
  //       containers.add(
  //         ExpansionTile(
  //             title: Text(service.uuid.toString()),
  //             children: characteristicsWidget),
  //       );
  //     }
  //   }
  //
  //   return ListView(
  //     padding: const EdgeInsets.all(8),
  //     children: <Widget>[
  //       ...containers,
  //       WindowControls(
  //           onOpenButtonTap: openWindowButtonHandler,
  //           onCloseButtonTap: closeWindowButtonHandler),
  //       WindowState(
  //           windowState: _windowState,
  //           onUpdateButtonTap: updateWindowStateButtonHandler),
  //       McuTime(
  //           time: _timeState,
  //           onUpdateButtonTap: updateMcuTimeButtonHandler,
  //           onSetTimeButtonTap: onSetTimeButtonTap),
  //       TimeMode(
  //           isTimeModeEnabled: _isTimeModeEnabled,
  //           onSetTimeModeButtonTap: onSetTimeModeButtonTap,
  //           onTimeModeCheckboxChange: onTimeModeCheckboxChange),
  //       Schedule(
  //           isScheduleEnabled: _isScheduleEnabled,
  //           onSetScheduleButtonTap: onSetScheduleButtonTap,
  //           onScheduleCheckboxChange: onScheduleCheckboxChange)
  //     ],
  //   );
  // }

  Widget _buildView() {
    if (_connectedDevice != null) {
      return ConnectedDeviceView(services: _services);
    }
    return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AvailableDeviceList(
            deviceList: widget.devicesList,
            onDeviceConnectButtonTap: onDeviceConnectButtonTap));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
}
