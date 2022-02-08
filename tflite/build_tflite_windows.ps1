pip install numpy

git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout v2.8.0

# $env:PYTHON_BIN_PATH = "C:\iwatake\devel\python\.venv\py38_test01\Scripts\python.exe"
# $env:PYTHON_LIB_PATH = "C:\iwatake\devel\python\.venv\py38_test01\lib\site-packages"
$env:PYTHON_BIN_PATH = "C:\hostedtoolcache\windows\Python\3.8.10\x64\python.exe"

# $env:PYTHON_LIB_PATH = "C:\iwatake\devel\python\.venv\py38_test01\lib\site-packages"



$env:TF_NEED_ROCM = 0
$env:TF_NEED_CUDA = 0
$env:TF_DOWNLOAD_CLANG = 0
$env:CC_OPT_FLAGS = "/arch:AVX"
$env:TF_SET_ANDROID_WORKSPACE = 0
$env:TF_OVERRIDE_EIGEN_STRONG_INLINE = 1
python configure.py
bazel build //tensorflow/lite:libtensorflowlite.so
