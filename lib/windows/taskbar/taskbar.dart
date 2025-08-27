import 'package:multi_window_linux/multi_window_linux.dart';
import 'package:flutter/material.dart';

class Taskbar extends StatefulWidget {
  final int monitorIndex;
  final String monitorName;
  const Taskbar({super.key, required this.monitorIndex, required this.monitorName});

  @override
  State<Taskbar> createState() => _TaskbarState();
}

class _TaskbarState extends State<Taskbar> {
  int workspace = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            const Text("Hello Sem"),
            Text(DateTime.now().toString()),
            Text(
              "Taskbar ${widget.monitorIndex} (${widget.monitorName})\n"
              "Workspace: $workspace",
            ),
          ],
        ),
      ),
    );
  }
}
