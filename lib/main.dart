import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gputest/colors.dart';
import 'package:gputest/julia.dart';
import 'package:gputest/texture_cube.dart';
import 'package:gputest/triangle.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //home: const JuliaSetPage(title: 'Julia'),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  int widgetIndex = 0;

  @override
  Widget build(BuildContext context) {
    final widgets = [
      const ColorsPage(),
      const TextureCubePage(),
      const TrianglePage(),
      const JuliaSetPage()
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedOpacity(
              opacity: widgetIndex > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                onPressed: () => setState(() {
                  widgetIndex = max(0, widgetIndex - 1);
                }),
                icon: const Icon(Icons.arrow_back_ios),
              ),
            ),
            const Expanded(
                child: Text(
              'GPU demo',
              textAlign: TextAlign.center,
            )),
            AnimatedOpacity(
              opacity: widgetIndex < widgets.length - 1 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                onPressed: () => setState(() {
                  widgetIndex = min(widgets.length - 1, widgetIndex + 1);
                }),
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: widgets[widgetIndex]
              //child: IndexedStack(
              //  index: widgetIndex,
              //  children: widgets,
              //),
              ),
        ],
      ),
    );
  }
}
