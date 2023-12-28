import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:ui' as ui;

import 'package:flutter_gpu/gpu.dart' as gpu;

ByteData float32(List<double> values) {
  return Float32List.fromList(values).buffer.asByteData();
}

ByteData uint16(List<int> values) {
  return Uint16List.fromList(values).buffer.asByteData();
}

ByteData uint32(List<int> values) {
  return Uint32List.fromList(values).buffer.asByteData();
}

ByteData float32Mat(Matrix4 matrix) {
  return Float32List.fromList(matrix.storage).buffer.asByteData();
}

class TextureCubePainter extends CustomPainter {
  TextureCubePainter(this.time, this.seedX, this.seedY);

  double time;
  double seedX;
  double seedY;

  @override
  void paint(Canvas canvas, Size size) {
    /// Allocate a new renderable texture.
    final gpu.Texture? renderTexture = gpu.gpuContext.createTexture(
        gpu.StorageMode.devicePrivate, 300, 300,
        enableRenderTargetUsage: true,
        enableShaderReadUsage: true,
        coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture);
    if (renderTexture == null) {
      return;
    }

    final gpu.Texture? depthTexture = gpu.gpuContext.createTexture(
        gpu.StorageMode.deviceTransient, 300, 300,
        format: gpu.gpuContext.defaultDepthStencilFormat,
        enableRenderTargetUsage: true,
        coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture);
    if (depthTexture == null) {
      return;
    }

    /// Create the command buffer. This will be used to submit all encoded
    /// commands at the end.
    final commandBuffer = gpu.gpuContext.createCommandBuffer();

    /// Define a render target. This is just a collection of attachments that a
    /// RenderPass will write to.
    final renderTarget = gpu.RenderTarget.singleColor(
      gpu.ColorAttachment(texture: renderTexture),
      depthStencilAttachment: gpu.DepthStencilAttachment(
          texture: depthTexture, depthClearValue: 1.0),
    );

    /// Add a render pass encoder to the command buffer so that we can start
    /// encoding commands.
    final encoder = commandBuffer.createRenderPass(renderTarget);

    /// Load a shader bundle asset.
    final library =
        gpu.ShaderLibrary.fromAsset('assets/TestLibrary.shaderbundle')!;

    /// Create a RenderPipeline using shaders from the asset.
    final vertex = library['TextureVertex']!;
    final fragment = library['TextureFragment']!;
    final pipeline = gpu.gpuContext.createRenderPipeline(vertex, fragment);

    encoder.bindPipeline(pipeline);

    encoder.setDepthWriteEnable(true);
    encoder.setDepthCompareOperation(gpu.CompareFunction.less);

    /// (Optional) Configure blending for the first color attachment.
    encoder.setColorBlendEnable(true);
    encoder.setColorBlendEquation(gpu.ColorBlendEquation(
        colorBlendOperation: gpu.BlendOperation.add,
        sourceColorBlendFactor: gpu.BlendFactor.one,
        destinationColorBlendFactor: gpu.BlendFactor.oneMinusSourceAlpha,
        alphaBlendOperation: gpu.BlendOperation.add,
        sourceAlphaBlendFactor: gpu.BlendFactor.one,
        destinationAlphaBlendFactor: gpu.BlendFactor.oneMinusSourceAlpha));

    /// Append quick geometry and uniforms to a host buffer that will be
    /// automatically uploaded to the GPU later on.
    final transients = gpu.HostBuffer();
    final vertices = transients.emplace(float32(<double>[
      -1, -1, -1, /* */ 0, 0, /* */ 1, 0, 0, 1, //
      1, -1, -1, /*  */ 1, 0, /* */ 0, 1, 0, 1, //
      1, 1, -1, /*   */ 1, 1, /* */ 0, 0, 1, 1, //
      -1, 1, -1, /*  */ 0, 1, /* */ 0, 0, 0, 1, //
      -1, -1, 1, /*  */ 0, 0, /* */ 0, 1, 1, 1, //
      1, -1, 1, /*   */ 1, 0, /* */ 1, 0, 1, 1, //
      1, 1, 1, /*    */ 1, 1, /* */ 1, 1, 0, 1, //
      -1, 1, 1, /*   */ 0, 1, /* */ 1, 1, 1, 1, //
    ]));
    final indices = transients.emplace(uint16(<int>[
      0, 1, 3, 3, 1, 2, //
      1, 5, 2, 2, 5, 6, //
      5, 4, 6, 6, 4, 7, //
      4, 0, 7, 7, 0, 3, //
      3, 2, 7, 7, 2, 6, //
      4, 5, 0, 0, 5, 1, //
    ]));
    final mvp = transients.emplace(float32Mat(Matrix4(
          0.5, 0, 0, 0, //
          0, 0.5, 0, 0, //
          0, 0, 0.2, 0, //
          0, 0, 0.5, 1, //
        ) *
        Matrix4.rotationX(time) *
        Matrix4.rotationY(time * seedX) *
        Matrix4.rotationZ(time * seedY)));

    /// Bind the vertex and index buffer.
    encoder.bindVertexBuffer(vertices, 8);
    encoder.bindIndexBuffer(indices, gpu.IndexType.int16, 36);

    /// Bind the host buffer data we just created to the vertex shader's uniform
    /// slots. Although the locations are specified in the shader and are
    /// predictable, we can optionally fetch the uniform slots by name for
    /// convenience.
    final mvpSlot = pipeline.vertexShader.getUniformSlot('mvp')!;
    encoder.bindUniform(mvpSlot, mvp);

    final sampledTexture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible, 5, 5,
        enableShaderReadUsage: true);
    sampledTexture!.overwrite(uint32(<int>[
      0xFFFFFFFF, 0x00000000, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF, //
      0x00000000, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF, 0x00000000, //
      0xFFFFFFFF, 0x00000000, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF, //
      0x00000000, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF, 0x00000000, //
      0xFFFFFFFF, 0x00000000, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF, //
    ]));

    final texSlot = pipeline.fragmentShader.getUniformSlot('tex')!;
    encoder.bindTexture(texSlot, sampledTexture);

    /// And finally, we append a draw call.
    encoder.draw();

    /// Submit all of the previously encoded passes. Passes are encoded in the
    /// same order they were created in.
    commandBuffer.submit();

    /// Wrap the Flutter GPU texture as a ui.Image and draw it like normal!
    final image = renderTexture.asImage();

    canvas.drawImage(image, Offset(-renderTexture.width / 2, 0), Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class TextureCubePage extends StatefulWidget {
  const TextureCubePage({super.key});

  @override
  State<TextureCubePage> createState() => _TextureCubePageState();
}

class _TextureCubePageState extends State<TextureCubePage> {
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
          painter: TextureCubePainter(time, seedX, seedY),
        ),
      ],
    );
  }
}
