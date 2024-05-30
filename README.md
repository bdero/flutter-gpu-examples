# Flutter GPU examples

Currently only supports MacOS.

## Build instructions

1. Follow the instructions in the [Flutter GPU documentation](https://github.com/flutter/flutter/blob/master/docs/engine/impeller/Flutter-GPU.md) to properly set up your Flutter checkout.
2. Edit the `flutter_gpu` path in `pubspec.yaml` to match your local engine checkout.
3. Edit the `IMPELLERC` and `ENGINE_DIR` paths in `run.sh`.
4. Run `run.sh` to install dependencies and build shaders.
5. `flutter run -d macos`
