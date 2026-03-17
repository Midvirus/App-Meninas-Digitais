import 'package:flutter/material.dart';
import 'NavBar.dart';

class PinboardPage extends StatefulWidget {
  const PinboardPage({super.key, required this.title});
  final String title;

  @override
  State<PinboardPage> createState() => _PinboardPageState();
}

class _PinboardPageState extends State<PinboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: NavBar.buildDrawer(context),
      body: const Center(
        child: Text('Pinboard Page'),
      ),
    );
  }
}