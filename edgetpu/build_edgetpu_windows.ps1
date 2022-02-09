# Run on GitHub Actions


# Set env
# $env:BAZEL_VC="C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC"
# $env:BAZEL_VS="C:/Program Files (x86)/Microsoft Visual Studio/2019/Community"
$env:BAZEL_VS="C:/Program Files (x86)/Microsoft Visual Studio/2019/Enterprise"

$env:EDGETPU_VERSION_TAG="release-grouper"
$env:TFLITE_VERSION_TAG="v2.8.0"
$env:TFLITE_VERSION_HASH="3f878cff5b698b82eea85db2b60d65a2e320850e"
$env:TFLITE_VERSION_SHA256="21d919ad6d96fcc0477c8d4f7b1f7e4295aaec2986e035551ed263c2b1cd52ee"

# Install requirements
pip install numpy


# Get dependencies (libusb)
curl -L https://github.com/libusb/libusb/releases/download/v1.0.24/libusb-1.0.24.7z -o temp.7z
7z x -o"./libusb" temp.7z
# 7z x -o"c:/libusb" temp.7z


# Get code
git clone https://github.com/google-coral/libedgetpu.git
cd libedgetpu
git checkout $env:EDGETPU_VERSION_TAG
## Replace TENSORFLOW_COMMIT and TENSORFLOW_SHA256
Get-Content workspace.bzl | foreach { $_ -creplace "a4dfb8d1a71385bd6d122e4f27f86dcebb96712d", $env:TFLITE_VERSION_HASH } > temp1.txt
Get-Content temp1.txt | foreach { $_ -creplace "cb99f136dc5c89143669888a44bfdd134c086e1e2d9e36278c1eb0f03fe62d76", $env:TFLITE_VERSION_SHA256 } > temp2.txt
cat temp2.txt | Out-File workspace.bzl -Encoding ascii
rm *.txt
cd ..

# Build for Release mode
cd libedgetpu
./build.bat

## Collect artifacts
cd ..
mkdir -p edgetpu_prebuilt/direct/windows-vs2019
cp -r libedgetpu/bazel-out/x64_windows-opt/bin/tflite/public/edgetpu_direct_all.dll edgetpu_prebuilt/direct/windows-vs2019/.
cp -r libedgetpu/bazel-out/x64_windows-opt/bin/tflite/public/edgetpu_direct_all.dll.if.lib edgetpu_prebuilt/direct/windows-vs2019/.
cp -r libedgetpu/bazel-out/x64_windows-opt/bin/tflite/public/libusb-1.0.dll edgetpu_prebuilt/direct/windows-vs2019/.


# Build for Debug mode
cd libedgetpu
./build.bat /DBG

## Collect artifacts
cd ..
mkdir -p edgetpu_prebuilt/direct/windows-vs2019/debug
cp -r libedgetpu/bazel-out/x64_windows-opt/bin/tflite/public/edgetpu_direct_all.dll edgetpu_prebuilt/direct/windows-vs2019/debug/.
cp -r libedgetpu/bazel-out/x64_windows-opt/bin/tflite/public/edgetpu_direct_all.dll.if.lib edgetpu_prebuilt/direct/windows-vs2019/debug/.
cp -r libedgetpu/bazel-out/x64_windows-opt/bin/tflite/public/libusb-1.0.dll edgetpu_prebuilt/direct/windows-vs2019/debug/.


## Compress artifacts
powershell Compress-Archive -Path edgetpu_prebuilt -DestinationPath edgetpu_prebuilt_windows.zip
