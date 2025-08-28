import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:desktop_drop/desktop_drop.dart';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  // Change this to the folder you want to watch (e.g. project folder).
  // Default: user's OS Desktop
  late final String watchedPath = Platform.environment['HOME'] != null
      ? '${Platform.environment['HOME']}/Desktop'
      : Directory.current.path;

  late Directory _dir;
  List<FileSystemEntity> _entries = [];
  StreamSubscription<FileSystemEvent>? _watcher;

  // Drag state
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _dir = Directory(watchedPath);
    _ensureDirThenLoad();
    _startWatcher();
  }

  Future<void> _ensureDirThenLoad() async {
    try {
      if (!await _dir.exists()) {
        await _dir.create(recursive: true);
      }
    } catch (_) {}
    _loadEntries();
  }

  void _startWatcher() {
    try {
      _watcher = _dir.watch().listen((event) {
        // minor debounce to coalesce bursts
        Future.delayed(const Duration(milliseconds: 80), _loadEntries);
      }, onError: (_) {
        // ignore watcher errors for now
      });
    } catch (_) {
      // platform might not support watch; fall back to periodic refresh
      Timer.periodic(const Duration(seconds: 2), (_) => _loadEntries());
    }
  }

  void _loadEntries() {
    try {
      final raw = _dir.listSync(recursive: false);
      // filter hidden files, sort by name
      final filtered = raw.where((e) => !p.basename(e.path).startsWith('.')).toList()
        ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
      setState(() => _entries = filtered);
    } catch (e) {
      // ignore read errors
    }
  }

  @override
  void dispose() {
    _watcher?.cancel();
    super.dispose();
  }

  bool _isImage(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'].contains(ext);
  }

  Future<void> _openWithFileManager(String path) async {
    try {
      if (Platform.isMacOS) {
        // macOS: open with application named "filemanagerfltr"
        await Process.run('open', ['-a', 'filemanagerfltr', path]);
      } else if (Platform.isLinux) {
        // assume filemanagerfltr is on PATH on Linux
        await Process.run('filemanagerfltr', [path]);
      } else if (Platform.isWindows) {
        // Windows: try to start the app with the path
        // using cmd /c start "" "filemanagerfltr" "path"
        await Process.run('cmd', ['/c', 'start', '', 'filemanagerfltr', path]);
      }
    } catch (e) {
      // ignore failures for now; you may want to show an error
    }
  }

  Future<void> _handleDrop(DropDoneDetails detail) async {
    if (detail.files.isEmpty) return;

    for (final f in detail.files) {
      // on desktop, XFile.path should be available
      final src = f.path;
      if (src == null || src.isEmpty) continue;

      final base = p.basename(src);
      var destPath = p.join(_dir.path, base);
      var counter = 1;
      while (await File(destPath).exists()) {
        final name = p.basenameWithoutExtension(base);
        final ext = p.extension(base);
        destPath = p.join(_dir.path, '$name (${counter++})$ext');
      }

      try {
        await File(src).copy(destPath);
      } catch (e) {
        // fallback: try to read bytes and write
        try {
          final bytes = await f.readAsBytes();
          await File(destPath).writeAsBytes(bytes);
        } catch (_) {}
      }
    }

    // refresh listing after drop
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    // Heuristic for icon size: relative to window shortest side, scaled by DPR.
    double iconSize = (shortest / 18) * (devicePixelRatio.clamp(1.0, 2.0));
    iconSize = iconSize.clamp(48.0, 140.0); // sensible min/max

    // wallpaper path (project-root/images/wallpaper.jpg)
    final wallpaperPath = p.join(Directory.current.path, 'images', 'wallpaper.jpg');
    final wallpaperFile = File(wallpaperPath);
    final hasWallpaper = wallpaperFile.existsSync();

    final grid = GridView.builder(
      itemCount: _entries.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: (size.width / (iconSize * 1.6)).clamp(3, 12).toInt(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final e = _entries[index];
        final name = p.basename(e.path);
        Widget icon;

        if (e is Directory) {
          icon = Icon(Icons.folder, size: iconSize, color: Colors.amberAccent);
        } else if (e is File && _isImage(e.path)) {
          icon = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(e.path),
              width: iconSize,
              height: iconSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.image, size: iconSize),
            ),
          );
        } else {
          icon = Icon(Icons.insert_drive_file, size: iconSize, color: Colors.grey[300]);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _openWithFileManager(e.path);
                  },
                  child: Center(child: icon),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
            ),
          ],
        );
      },
    );

    return Stack(
      children: [
        // background: wallpaper if present, otherwise black
        Positioned.fill(
          child: hasWallpaper
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(wallpaperFile),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(color: Colors.black),
        ),

        // subtle dark overlay so icons/text remain readable over wallpaper
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.38)),
        ),

        // DropTarget wraps the grid to accept file drops from OS
        DropTarget(
          onDragEntered: (detail) {
            setState(() => _dragging = true);
          },
          onDragExited: (detail) {
            setState(() => _dragging = false);
          },
          onDragDone: (detail) async {
            setState(() => _dragging = false);
            await _handleDrop(detail);
          },
          child: Container(
            // keep transparent so wallpaper shows through
            color: Colors.transparent,
            padding: const EdgeInsets.all(16),
            child: _entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.desktop_windows, size: 64, color: Colors.white54),
                        const SizedBox(height: 12),
                        Text(
                          'No items in $watchedPath',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadEntries,
                          child: const Text('Refresh', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  )
                : grid,
          ),
        ),
        // visual overlay when dragging
        if (_dragging)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.white.withOpacity(0.06),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(color: Colors.white70, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Drop files to copy to Desktop',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
