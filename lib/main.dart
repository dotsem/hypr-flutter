import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wayland_layer_shell/types.dart';
import 'package:wayland_layer_shell/wayland_layer_shell.dart';
import 'package:multi_window_linux/multi_window_linux.dart';

final multiWindow = MultiWindowLinux();

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.isNotEmpty && args[0].startsWith('taskbar_')) {
    // This is a spawned taskbar window
    await initializeTaskbarWindow(args);
  } else {
    // This is the main controller window
    runApp(const MainApp());
  }
}

Future<List<dynamic>> getHyprMonitors() async {
  final result = await Process.run('hyprctl', ['monitors', '-j']);
  if (result.exitCode != 0) {
    throw Exception('Failed to get monitor info: ${result.stderr}');
  }
  return jsonDecode(result.stdout) as List;
}

// Find the best matching monitor by name
Monitor? findMatchingMonitor(List<Monitor> gdkMonitors, dynamic hyprMonitor) {
  final hyprName = hyprMonitor['name'] as String;
  final hyprDescription = hyprMonitor['description'] as String? ?? '';

  print('Looking for GDK monitor matching Hyprland monitor: $hyprName');

  // First try exact name match
  for (final gdkMonitor in gdkMonitors) {
    print('  Checking GDK monitor: ${gdkMonitor.name}');
    if (gdkMonitor.name == hyprName) {
      print('  ✓ Exact match found: ${gdkMonitor.name}');
      return gdkMonitor;
    }
  }

  // Try partial name match
  for (final gdkMonitor in gdkMonitors) {
    if (gdkMonitor.name.contains(hyprName) || hyprName.contains(gdkMonitor.name)) {
      print('  ✓ Partial match found: ${gdkMonitor.name} for $hyprName');
      return gdkMonitor;
    }
  }

  // Try description match
  if (hyprDescription.isNotEmpty) {
    for (final gdkMonitor in gdkMonitors) {
      if (hyprDescription.contains(gdkMonitor.name) || gdkMonitor.name.contains(hyprDescription)) {
        print('  ✓ Description match found: ${gdkMonitor.name} for $hyprDescription');
        return gdkMonitor;
      }
    }
  }

  print('  ✗ No match found for $hyprName');
  return null;
}

Future<void> initializeTaskbarWindow(List<String> args) async {
  final key = args[0];
  final parts = key.split('_');
  final hyprMonitorIndex = int.parse(parts[1]);
  final hyprMonitorName = parts.length > 2 ? parts[2] : '';

  print('Initializing taskbar for Hyprland monitor $hyprMonitorIndex: $hyprMonitorName');

  // Get monitor information FIRST
  final waylandLayerShell = WaylandLayerShell();
  Monitor? targetMonitor;

  try {
    final gdkMonitors = (await waylandLayerShell.getMonitorList()).cast<Monitor>();
    print('Available GDK monitors:');
    for (int i = 0; i < gdkMonitors.length; i++) {
      print('  [$i] ${gdkMonitors[i]}');
    }

    // If we have the monitor name, try to find it by name
    if (hyprMonitorName.isNotEmpty) {
      for (final gdkMonitor in gdkMonitors) {
        if (gdkMonitor.name.contains(hyprMonitorName) || hyprMonitorName.contains(gdkMonitor.name)) {
          targetMonitor = gdkMonitor;
          print('Found matching monitor by name: ${targetMonitor}');
          break;
        }
      }
    }

    // Fallback to index if name matching failed
    if (targetMonitor == null) {
      if (hyprMonitorIndex < gdkMonitors.length) {
        targetMonitor = gdkMonitors[hyprMonitorIndex];
        print('Using monitor by index: ${targetMonitor}');
      } else if (gdkMonitors.isNotEmpty) {
        targetMonitor = gdkMonitors[0];
        print('Using fallback monitor: ${targetMonitor}');
      }
    }
  } catch (e) {
    print('Failed to get monitor info: $e');
  }

  // FIXED: Initialize with specific size constraints
  const taskbarWidth = 650;
  const taskbarHeight = 40;

  final initSuccess = await waylandLayerShell.initialize(taskbarWidth, taskbarHeight, monitor: targetMonitor?.toString());

  if (!initSuccess) {
    print('Failed to initialize layer shell for $key');
    return;
  }

  print('Layer shell initialized successfully for $key');

  // CRITICAL: Configure anchoring BEFORE showing the window
  // Only anchor to bottom edge, not left and right (this was causing full width)
  await waylandLayerShell.setAnchor(ShellEdge.edgeBottom, false);
  await waylandLayerShell.setAnchor(ShellEdge.edgeTop, true);
  await waylandLayerShell.setAnchor(ShellEdge.edgeLeft, true); // Changed to true
  await waylandLayerShell.setAnchor(ShellEdge.edgeRight, true); // Changed to false

  print('Set anchoring: bottom=true, others=false');

  // Set margins to position the taskbar properly
  await waylandLayerShell.setMargin(ShellEdge.edgeBottom, 10); // 10px from bottom
  await waylandLayerShell.setMargin(ShellEdge.edgeLeft, 50); // 50px from left
  await waylandLayerShell.setMargin(ShellEdge.edgeRight, 50); // 50px from right

  print('Set margins: bottom=10, left=50, right=50');

  // FIXED: Don't use auto exclusive zone for taskbars that shouldn't take full width
  await waylandLayerShell.setExclusiveZone(1); // No exclusive zone
  print('Set exclusive zone to 0');

  await waylandLayerShell.setKeyboardMode(ShellKeyboardMode.keyboardModeOnDemand);

  // Double-check monitor setting using the found monitor
  if (targetMonitor != null) {
    try {
      await waylandLayerShell.setMonitor(targetMonitor);
      print('Confirmed monitor set to: $targetMonitor');
    } catch (e) {
      print('Failed to confirm monitor: $e');
    }
  }

  print('Layer shell configuration complete for $key');

  // IMPORTANT: Show the window AFTER all configuration is done
  try {
    await waylandLayerShell.showWindow();
    print('Window shown for $key');
  } catch (e) {
    print('showWindow method not available, continuing: $e');
  }

  // Now create and run the app
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Taskbar(monitorIndex: hyprMonitorIndex, monitorName: hyprMonitorName),
    ),
  );

  print('Taskbar app started for $key');
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Delay spawning to ensure main window is ready
    Future.delayed(const Duration(milliseconds: 1000), () {
      spawnTaskbars();
    });

    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            "Widget System Controller\nSpawning taskbars...",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

Future<void> spawnTaskbars() async {
  try {
    print('=== Starting taskbar spawning process ===');

    final hyprMonitors = await getHyprMonitors();
    final waylandLayerShell = WaylandLayerShell();
    final gdkMonitors = (await waylandLayerShell.getMonitorList()).cast<Monitor>();

    print('Found ${hyprMonitors.length} monitors from Hyprland:');
    for (int i = 0; i < hyprMonitors.length; i++) {
      final mon = hyprMonitors[i];
      print('  [$i] ${mon['name']} - ${mon['description']}');
    }

    print('Found ${gdkMonitors.length} monitors from GDK:');
    for (int i = 0; i < gdkMonitors.length; i++) {
      print('  [$i] ${gdkMonitors[i]}');
    }

    // Create monitor mapping
    final Map<int, Monitor?> monitorMapping = {};
    for (int i = 0; i < hyprMonitors.length; i++) {
      final hyprMon = hyprMonitors[i];
      final matchedGdkMonitor = findMatchingMonitor(gdkMonitors, hyprMon);
      monitorMapping[i] = matchedGdkMonitor;
      print('Mapping: Hypr[$i] ${hyprMon['name']} -> GDK ${matchedGdkMonitor?.toString() ?? 'null'}');
    }

    for (int i = 0; i < hyprMonitors.length; i++) {
      try {
        final mon = hyprMonitors[i];
        final monitorName = mon['name'] as String;
        final key = 'taskbar_${i}_$monitorName';

        print('=== Creating taskbar for monitor $i: $monitorName ===');

        final targetGdkMonitor = monitorMapping[i];

        if (targetGdkMonitor != null) {
          print('Will use GDK monitor: ${targetGdkMonitor}');
        } else {
          print('WARNING: No matching GDK monitor found for $monitorName');
        }

        // Create the window with fixed size
        await multiWindow.create(key, size: const Size(650, 40), title: 'Taskbar - $monitorName');

        print('✓ Created window: $key');

        // Wait for proper initialization
        await Future.delayed(const Duration(milliseconds: 3000));
      } catch (e, stackTrace) {
        print('ERROR creating taskbar $i: $e');
        print('Stack trace: $stackTrace');
        continue;
      }
    }

    print('=== All taskbars spawned successfully ===');
  } catch (e, stackTrace) {
    print('FATAL ERROR in spawnTaskbars: $e');
    print('Stack trace: $stackTrace');
  }
}

class Taskbar extends StatefulWidget {
  final int monitorIndex;
  final String monitorName;

  const Taskbar({super.key, required this.monitorIndex, this.monitorName = ''});

  @override
  State<Taskbar> createState() => _TaskbarState();
}

class _TaskbarState extends State<Taskbar> {
  int workspace = 1;

  @override
  void initState() {
    super.initState();
    print('Taskbar ${widget.monitorIndex} (${widget.monitorName}) initialized');

    // Listen for events from the main controller
    try {
      final eventKey = widget.monitorName.isNotEmpty ? 'taskbar_${widget.monitorIndex}_${widget.monitorName}' : 'taskbar_${widget.monitorIndex}';

      multiWindow.events(eventKey, 'main').listen((event) {
        if (mounted) {
          setState(() {
            workspace = event.data['workspace'] ?? workspace;
          });
        }
      });
    } catch (e) {
      print('Error setting up event listener: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8), // Semi-transparent background
      body: Container(
        width: 650, // Fixed width
        height: 40, // Fixed height
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            'Taskbar ${widget.monitorIndex} - ${widget.monitorName} - WS: $workspace',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
