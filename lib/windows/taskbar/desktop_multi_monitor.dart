// import 'dart:convert';
// import 'dart:io';
// import 'dart:ui';
// import 'package:desktop_multi_window/desktop_multi_window.dart';

// Future<void> spawnTaskbars(Map<int, int> monitorTaskbars) async {
//   final result = await Process.run('hyprctl', ['monitors', '-j']);
//   final monitors = jsonDecode(result.stdout) as List;

//   for (int i = 0; i < monitors.length; i++) {
//     final mon = monitors[i];
//     final args = jsonEncode({'monitor': mon['name'], 'index': i});
//     await DesktopMultiWindow.createWindow(args);
//     final win = await DesktopMultiWindow.createWindow(args);

//     await win
//       ..setFrame(Rect.fromLTWH(mon['x'].toDouble(), (mon['y'] + mon['height'] - 40).toDouble(), mon['width'].toDouble(), 40))
//       ..setTitle("Taskbar - ${mon['name']}")
//       ..show();

//     monitorTaskbars[i] = win.windowId;
//   }
// }
