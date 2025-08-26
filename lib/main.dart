import 'package:flutter/material.dart';
import 'package:wayland_layer_shell/types.dart';
import 'dart:async';

import 'package:wayland_layer_shell/wayland_layer_shell.dart';
import 'package:hypr_widget/set_exclusive_zone.dart';
import 'package:hypr_widget/set_keyboard.dart';
import 'package:hypr_widget/set_monitor.dart';
import 'package:hypr_widget/set_anchors.dart';
import 'package:hypr_widget/set_layer.dart';
import 'package:hypr_widget/set_margins.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final waylandLayerShellPlugin = WaylandLayerShell();
  bool isSupported = await waylandLayerShellPlugin.initialize(650, 50);
  if (!isSupported) {
    runApp(const MaterialApp(home: Center(child: Text('Not supported'))));
    return;
  }
  await waylandLayerShellPlugin.enableAutoExclusiveZone();
  await waylandLayerShellPlugin.setAnchor(ShellEdge.edgeLeft, true);
  await waylandLayerShellPlugin.setAnchor(ShellEdge.edgeRight, true);
  await waylandLayerShellPlugin.setAnchor(ShellEdge.edgeTop, true);
  await waylandLayerShellPlugin.setKeyboardMode(ShellKeyboardMode.keyboardModeEntryNumber);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Row(children: [const Text("Hello Sem"), Text(DateTime.now().toString())])),
    );
  }
}
