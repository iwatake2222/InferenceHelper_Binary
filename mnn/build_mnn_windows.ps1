# Visual Studio 2019 Developer PowerShell

# Set-ExecutionPolicy RemoteSigned -Scope Process
# cd /path/to/MNN

powershell ./schema/generate.ps1

mkdir build
cd build
cmake -DMNN_BUILD_TOOLS=OFF -DCMAKE_INSTALL_PREFIX=windows-vs2019 ..
MSBuild ./MNN.sln /p:Configuration=Release
MSBuild INSTALL.vcxproj
mv Release/MNN.dll windows-vs2019/lib/.
cd ..

mkdir build-vulkan
cd build-vulkan
cmake -DMNN_BUILD_TOOLS=OFF -DMNN_VULKAN=ON -DCMAKE_INSTALL_PREFIX=windows-vs2019-vulkan ..
MSBuild ./MNN.sln /p:Configuration=Release
MSBuild INSTALL.vcxproj
mv Release/MNN.dll windows-vs2019-vulkan/lib/.
cd ..

mkdir mnn_prebuilt
mv build/windows-vs2019 mnn_prebuilt/.
mv build-vulkan/windows-vs2019-vulkan mnn_prebuilt/.
powershell Compress-Archive -Path mnn_prebuilt -DestinationPath mnn_prebuilt_windows.zip
