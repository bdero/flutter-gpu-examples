set -ex

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ENGINE_DIR=~/projects/flutter/engine/src
IMPELLERC=$ENGINE_DIR/out/host_debug_unopt_arm64/impellerc

mkdir -p $SCRIPT_DIR/assets
$IMPELLERC \
  --include=$ENGINE_DIR/flutter/impeller/compiler/shader_lib \
  --runtime-stage-metal \
  --sl=assets/TestLibrary.shaderbundle \
  --shader-bundle=\{\
\"UnlitFragment\":\ \{\"type\":\ \"fragment\",\ \"file\":\ \"$SCRIPT_DIR/shaders/flutter_gpu_unlit.frag\"\},\ \
\"UnlitVertex\":\ \{\"type\":\ \"vertex\",\ \"file\":\ \"$SCRIPT_DIR/shaders/flutter_gpu_unlit.vert\"\},\ \
\"TextureFragment\":\ \{\"type\":\ \"fragment\",\ \"file\":\ \"$SCRIPT_DIR/shaders/flutter_gpu_texture.frag\"\},\ \
\"TextureVertex\":\ \{\"type\":\ \"vertex\",\ \"file\":\ \"$SCRIPT_DIR/shaders/flutter_gpu_texture.vert\"\},\ \
\"ColorsFragment\":\ \{\"type\":\ \"fragment\",\ \"file\":\ \"$SCRIPT_DIR/shaders/colors.frag\"\},\ \
\"ColorsVertex\":\ \{\"type\":\ \"vertex\",\ \"file\":\ \"$SCRIPT_DIR/shaders/colors.vert\"\}\}

select opt in macos quit; do
  case $opt in
  macos)
    flutter run \
      --debug \
      --local-engine-src-path $ENGINE_DIR \
      --local-engine=host_debug_unopt_arm64 \
      --local-engine-host=host_debug_unopt_arm64 \
      -d macos \
      --enable-impeller
    ;;
  quit)
    break
    ;;
  *)
    echo "Invalid option $REPLY"
    ;;
  esac
done
