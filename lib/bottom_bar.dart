import 'package:flutter/material.dart';
import 'dart:async';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  String _time = "";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.black.withOpacity(0.7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Buton App Launcher
          IconButton(
            icon: const Icon(Icons.apps, color: Colors.white),
            onPressed: () {
              debugPrint("App Launcher pressed");
            },
          ),

          // Zona centrală (simbolic aplicații deschise)
          const Text(
            "Running apps...",
            style: TextStyle(color: Colors.white),
          ),

          // Ceasul
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              _time,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
