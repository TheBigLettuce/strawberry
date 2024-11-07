import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FilledButton(
          onPressed: () {
            context.pushNamed("Test");
          },
          child: Text("Launch"),
        ),
      ),
    );
  }
}
