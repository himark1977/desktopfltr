import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    _loadDesktopIcons();
  }

  void _loadDesktopIcons() {
    final desktopDir = Directory("${Platform.environment['HOME']}/Desktop");
    if (desktopDir.existsSync()) {
      setState(() {
        files = desktopDir.listSync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("images/wallpaper.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 0.8,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Column(
            children: [
              const Icon(Icons.insert_drive_file, size: 48, color: Colors.white),
              Text(
                p.basename(file.path),
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}
