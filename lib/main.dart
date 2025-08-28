import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'desktop.dart';
// import 'bottom_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1920, 1080),
    center: true,
    backgroundColor: Colors.black,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setFullScreen(true);
    await windowManager.setAsFrameless();
    await windowManager.show();
  });

  runApp(const MyDesktopEnv());
}

class MyDesktopEnv extends StatelessWidget {
  const MyDesktopEnv({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            DesktopScreen(),
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: BottomBar(),
            // ),
          ],
        ),
      ),
    );
  }
}
