# Run on GitHub Actions


# Set env
## Might be no need
# $env:BAZEL_VC="C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC"
# $env:BAZEL_VS="C:/Program Files (x86)/Microsoft Visual Studio/2019/Community"
$env:BAZEL_VS="C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise"

## No need to set env vars (default is automatically selected even without interaction)
## Also, don't set PYTHON_BIN_PATH to use the default version of Python (numpy is installed beforehand)
## $env:PYTHON_BIN_PATH = "C:/hostedtoolcache/windows/Python/3.8.10/x64/python.exe"   don't do this
## $env:PYTHON_LIB_PATH = "C:/hostedtoolcache/windows/Python/3.8.10/x64/lib/site-packages"   don't do this
# $env:TF_NEED_ROCM = 0
# $env:TF_NEED_CUDA = 0
# $env:TF_DOWNLOAD_CLANG = 0
# $env:CC_OPT_FLAGS = "/arch:AVX"
# $env:TF_SET_ANDROID_WORKSPACE = 0
# $env:TF_OVERRIDE_EIGEN_STRONG_INLINE = 1


# Install requirements
pip install numpy


# Get code
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout v2.8.0
# git checkout v2.6.0
cd ..

# Build for Release mode
cd tensorflow
python configure.py
bazel build //tensorflow/lite:libtensorflowlite.so `
-c opt `
--copt -O3 `
--strip always `
--define tflite_with_xnnpack=true

## Collect artifacts
cd ..
mkdir -p tflite_prebuilt/windows-vs2019
mv tensorflow/bazel-bin/tensorflow/lite/libtensorflowlite.so tflite_prebuilt/windows-vs2019/.
mv tensorflow/bazel-bin/tensorflow/lite/libtensorflowlite.so.if.lib tflite_prebuilt/windows-vs2019/.


# Build for Debug mode
cd tensorflow
python configure.py
bazel build //tensorflow/lite:libtensorflowlite.so `
-c dbg `
--define tflite_with_xnnpack=true

## Collect artifacts
cd ..
mkdir -p tflite_prebuilt/windows-vs2019/debug
mv tensorflow/bazel-bin/tensorflow/lite/libtensorflowlite.so tflite_prebuilt/windows-vs2019/debug/.
mv tensorflow/bazel-bin/tensorflow/lite/libtensorflowlite.so.if.lib tflite_prebuilt/windows-vs2019/debug/.


# Compress artifacts
powershell Compress-Archive -Path tflite_prebuilt -DestinationPath tflite_prebuilt_windows.zip