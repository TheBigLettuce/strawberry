import "dart:async";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:strawberry/src/platform/platform.dart";

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.storageDriver,
    required this.player,
  });

  final StorageDriver storageDriver;
  final Player player;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final StreamSubscription<void> _watcher;

  @override
  void initState() {
    super.initState();

    _watcher = widget.storageDriver.tracks.events.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: widget.storageDriver.tracks.length,
        itemBuilder: (context, index) {
          final track = widget.storageDriver.tracks[index];

          return ListTile(
            title: Text(track.name),
            onTap: () {
              widget.player.queue.clearAndPlay(track);
            },
          );
        },
      ),
    );
  }
}
