import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;

import 'package:flutter_gpu/gpu.dart' as gpu;

class JuliaSetPainter extends CustomPainter {
  JuliaSetPainter(this.time, this.seedX, this.seedY);

  double time;
  double seedX;
  double seedY;
  final maxIterations = 100;
  final escapeDistance = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final gpu.Texture? texture =
        gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 3, 3);
    if (texture == null) {
      return;
    }

    texture!.overwrite(Uint32List.fromList(<int>[
      0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, //
      0xFF000000, 0xFFFFFFFF, 0xFF000000, //
      0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, //
    ]).buffer.asByteData());

    //var buffer = Int32List(texture.width * texture.height);
    //for (int i = 0; i < buffer.length; i++) {
    //  int xi = i % texture.width;
    //  int yi = i ~/ texture.width;
    //  double x = (xi.toDouble() - texture.width / 2) / (texture.width * 0.75);
    //  double y = (yi.toDouble() - texture.height / 2) / (texture.height * 0.75);
    //  int iterations = 0;
    //  for (int it = 0; it < maxIterations; it++) {
    //    // Square the complex number and add the seed offset.
    //    double newX = x * x - y * y + seedX;
    //    y = 2 * x * y + seedY;
    //    x = newX;
    //    if (x * x + y * y > escapeDistance * escapeDistance) {
    //      iterations = it;
    //      break;
    //    }
    //  }
    //  int shade = (iterations / maxIterations * 0xFF).toInt();
    //  buffer[i] = Color.fromARGB(0xFF, shade, shade, shade).value;
    //}

    //texture.overwrite(buffer.buffer.asByteData());

    final ui.Image image = texture.asImage();

    canvas.scale(50);
    canvas.drawImage(image, Offset(-texture.width / 2, 0), Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class JuliaSetPage extends StatefulWidget {
  const JuliaSetPage({super.key});

  @override
  State<JuliaSetPage> createState() => _JuliaSetPageState();
}

class _JuliaSetPageState extends State<JuliaSetPage> {
  Ticker? tick;
  double time = 0;
  double deltaSeconds = 0;
  double seedX = -0.512511498387847167;
  double seedY = 0.521295573094847167;

  @override
  void initState() {
    tick = Ticker(
      (elapsed) {
        setState(() {
          double previousTime = time;
          time = elapsed.inMilliseconds / 1000.0;
          deltaSeconds = previousTime > 0 ? time - previousTime : 0;
        });
      },
    );
    tick!.start();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Slider(
            value: seedX,
            max: 1,
            min: -1,
            onChanged: (value) => {setState(() => seedX = value)}),
        Slider(
            value: seedY,
            max: 1,
            min: -1,
            onChanged: (value) => {setState(() => seedY = value)}),
        CustomPaint(
          painter: JuliaSetPainter(time, seedX, seedY),
        ),
      ],
    );
  }
}
