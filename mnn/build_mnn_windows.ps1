# Run on Visual Studio 2019 Developer PowerShell
# You may need the following command before executing this script
# Set-ExecutionPolicy Unrestricted -Scope Process

# Get code
git clone https://github.com/alibaba/MNN.git
cd MNN
git checkout 1.2.6

powershell ./schema/generate.ps1

# Build libraries
mkdir build
cd build
cmake -DMNN_BUILD_TOOLS=OFF -DCMAKE_INSTALL_PREFIX=windows-vs2019 ..
MSBuild ./MNN.sln /p:Configuration=Release
MSBuild INSTALL.vcxproj /p:Configuration=Release
mv Release/MNN.dll windows-vs2019/lib/.
cd ..

mkdir build_vulkan
cd build_vulkan
cmake -DMNN_BUILD_TOOLS=OFF -DMNN_VULKAN=ON -DCMAKE_INSTALL_PREFIX=windows-vs2019-vulkan ..
MSBuild ./MNN.sln /p:Configuration=Release
MSBuild INSTALL.vcxproj /p:Configuration=Release
mv Release/MNN.dll windows-vs2019-vulkan/lib/.
cd ..

# Build tools
## Build protobuf
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v3.19.4
mkdir build_protobuf
cd build_protobuf
cmake -Dprotobuf_MSVC_STATIC_RUNTIME=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=install ../cmake
MSBuild ./protobuf.sln /p:Configuration=Release
MSBuild INSTALL.vcxproj /p:Configuration=Release

## Build MNN tools
cd ../../
mkdir build_tools
cd build_tools
cmake -DMNN_BUILD_TOOLS=OFF -DMNN_BUILD_SHARED_LIBS=OFF -DMNN_BUILD_CONVERTER=ON -DMNN_BUILD_QUANTOOLS=on -DCMAKE_BUILD_TYPE=Release ..
MSBuild ./MNN.sln /p:Configuration=Release
mkdir tools_windows-vs2019
mv Release/*.exe tools_windows-vs2019/
cd ..

# Compress artifacts
mkdir mnn_prebuilt
mv build/windows-vs2019 mnn_prebuilt/.
mv build_vulkan/windows-vs2019-vulkan mnn_prebuilt/.
mv build_tools/tools_windows-vs2019 mnn_prebuilt/.
powershell Compress-Archive -Path mnn_prebuilt -DestinationPath mnn_prebuilt_windows.zip
