import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:keyboard_event/keyboard_event.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  List<String> _err = [];
  List<String> _event = [];
  late KeyboardEvent keyboardEvent;
  int eventNum = 0;
  bool listenIsOn = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    keyboardEvent = KeyboardEvent();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String? platformVersion;
    List<String> err = [];
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await KeyboardEvent.platformVersion;
    } on PlatformException {
      err.add('Failed to get platform version.');
    }
    try {
      await KeyboardEvent.init();
    } on PlatformException {
      err.add('Failed to get virtual-key map.');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      if (platformVersion != null) _platformVersion = platformVersion;
      if (err.isNotEmpty) _err.addAll(err);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('运行于: $_platformVersion'),
                      Row(
                        children: [
                          Text('点击按钮切换键盘监听: '),
                          Switch(
                            value: listenIsOn,
                            onChanged: (bool newValue) {
                              setState(() {
                                listenIsOn = newValue;
                                if (listenIsOn == true) {
                                  keyboardEvent.startListening((keyEvent) {
                                    setState(() {
                                      eventNum++;
                                      if (keyEvent.vkName == 'ENTER')
                                        _event.last += '\n';
                                      else if (keyEvent.vkName == 'BACK')
                                        _event.removeLast();
                                      if (keyEvent.vkName == 'F5')
                                        _event.clear();
                                      else
                                        _event.add(keyEvent.toString());
                                      if (_event.length > 20)
                                        _event.removeAt(0);
                                      debugPrint(keyEvent.toString());
                                    });
                                  });
                                } else {
                                  keyboardEvent.cancelListening();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints.tightFor(width: 200),
                            child: Text(
                              "监听到的键盘事件：$eventNum ${keyboardEvent.state.toString()}\n${_event.join('\n')}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 20,
                            ),
                          ),
                          if (KeyboardEvent.virtualKeyString2CodeMap != null)
                            Table(
                              border: TableBorder.all(
                                color: Colors.black38,
                              ),
                              columnWidths: {
                                0: FixedColumnWidth(150),
                                1: FixedColumnWidth(40),
                              },
                              children: [
                                for (var item in KeyboardEvent
                                    .virtualKeyString2CodeMap!.entries)
                                  TableRow(
                                    key: ValueKey(item.key),
                                    children: [
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 5),
                                        child: Text(item.key),
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 5),
                                        child: Text(item.value.toString()),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                          if (KeyboardEvent.virtualKeyCode2StringMap != null)
                            SizedBox(
                              width: 20,
                            ),
                          if (KeyboardEvent.virtualKeyCode2StringMap != null)
                            Table(
                              border: TableBorder.all(
                                color: Colors.black38,
                              ),
                              columnWidths: {
                                0: FixedColumnWidth(40),
                                1: FixedColumnWidth(150),
                              },
                              children: [
                                for (var item in KeyboardEvent
                                    .virtualKeyCode2StringMap!.keys
                                    .toList()
                                      ..sort())
                                  TableRow(
                                    key: ValueKey(item),
                                    children: [
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 5),
                                        child: Text(item.toString()),
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 5),
                                        child: Text(KeyboardEvent
                                            .virtualKeyCode2StringMap![item]!
                                            .join(', \n')
                                            .toString()),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            initPlatformState();
          },
        ),
      ),
    );
  }
}
