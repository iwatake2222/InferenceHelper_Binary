# InferenceHelper_Binary
- Pre-built libraries for InferenceHelper ( https://github.com/iwatake2222/InferenceHelper )

- Build scripts for:
    - [todo] TensorFlow Lite : https://github.com/tensorflow/tensorflow
    - [todo] Edge TPU : https://github.com/google-coral/libedgetpu
    - MNN : https://github.com/alibaba/MNN
        - with + without Vulkan
        - [![MNN Linux](https://github.com/iwatake2222/InferenceHelper_Binary/actions/workflows/build_mnn_linux.yml/badge.svg)](https://github.com/iwatake2222/InferenceHelper_Binary/actions/workflows/build_mnn_linux.yml) [![MNN Windows](https://github.com/iwatake2222/InferenceHelper_Binary/actions/workflows/build_mnn_windows.yml/badge.svg)](https://github.com/iwatake2222/InferenceHelper_Binary/actions/workflows/build_mnn_windows.yml)
    - [todo] Arm NN : https://github.com/ARM-software/armnn
    - [todo] NNabla : https://github.com/sony/nnabla

- Targets:
    - Windows (Visual Studio 2019)
    - Linux (x64)
    - Linux (aarch64)
    - Linux (armv7)
    - Linux (Android arm64-v8a)
    - Linux (Android armeabi-v7a)

- As for the following frameworks, the official provides pre-built libraries
    - ncnn : https://github.com/Tencent/ncnn
    - SNPE (Snapdragon Neural Processing Engine SDK) : https://developer.qualcomm.com/software/qualcomm-neural-processing-sdk/tools
    - OpenCV : https://github.com/opencv/opencv
    - OpenVINO : https://www.intel.com/content/www/us/en/developer/tools/openvino-toolkit-download.html