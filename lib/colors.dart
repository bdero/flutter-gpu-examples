import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:ui' as ui;

import 'package:flutter_gpu/gpu.dart' as gpu;

ByteData float32(List<double> values) {
  return Float32List.fromList(values).buffer.asByteData();
}

ByteData float32Mat(Matrix4 matrix) {
  return Float32List.fromList(matrix.storage).buffer.asByteData();
}

class ColorsPainter extends CustomPainter {
  ColorsPainter(this.time, this.seedX, this.seedY);

  double time;
  double seedX;
  double seedY;

  @override
  void paint(Canvas canvas, Size size) {
    /// Allocate a new renderable texture.
    final gpu.Texture? texture =
        gpu.gpuContext.createTexture(gpu.StorageMode.devicePrivate, 300, 300);

    final library =
        gpu.ShaderLibrary.fromAsset('assets/TestLibrary.shaderbundle')!;

    final vertex = library['ColorsVertex']!;
    final fragment = library['ColorsFragment']!;
    final pipeline = gpu.gpuContext.createRenderPipeline(vertex, fragment);

    final gpu.DeviceBuffer? vertexBuffer = gpu.gpuContext
        .createDeviceBuffer(gpu.StorageMode.hostVisible, 4 * 6 * 3);
    vertexBuffer!.overwrite(Float32List.fromList(<double>[
      -0.5, -0.5,  1.0, 0.0, 0.0, 1.0, //
       0,    0.5,  0.0, 1.0, 0.0, 1.0, //
       0.5, -0.5,  0.0, 0.0, 1.0, 1.0, //
    ]).buffer.asByteData());

    final commandBuffer = gpu.gpuContext.createCommandBuffer();

    final renderTarget = gpu.RenderTarget.singleColor(
      gpu.ColorAttachment(texture: texture!),
    );
    final encoder = commandBuffer.createRenderPass(renderTarget);

    encoder.bindPipeline(pipeline);
    encoder.bindVertexBuffer(
        gpu.BufferView(vertexBuffer,
            offsetInBytes: 0, lengthInBytes: vertexBuffer.sizeInBytes), 3);
    encoder.draw();

    commandBuffer.submit();

    /// Wrap the Flutter GPU texture as a ui.Image and draw it like normal!
    final image = texture.asImage();

    canvas.drawImage(image, Offset(-texture.width / 2, 0), Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ColorsPage extends StatefulWidget {
  const ColorsPage({super.key});

  @override
  State<ColorsPage> createState() => _ColorsPageState();
}

class _ColorsPageState extends State<ColorsPage> {
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
          painter: ColorsPainter(time, seedX, seedY),
        ),
      ],
    );
  }
}
