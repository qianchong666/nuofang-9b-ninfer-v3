@echo off
setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
set "PATH=G:\cuda-13.3\bin;G:\cuda-13.3\bin\x64;%PATH%"
set "CUDACXX=G:\cuda-13.3\bin\nvcc.exe"
set "VCPKG_ROOT=G:\build\vcpkg"
set "VCPKG_TARGET_TRIPLET=x64-windows"
echo CONFIG_START=%DATE% %TIME% > G:\build\wemx-config.log
"G:\cmake-4.4.3-windows-x86_64\bin\cmake.exe" -S "G:\build\wemx-9b\src\src-tree\fusion-engine-src" -B "G:\build\wemx-86" -G Ninja ^
 -DCMAKE_MAKE_PROGRAM=G:/miniconda3/Scripts/ninja.exe ^
 -DCMAKE_BUILD_TYPE=Release ^
 -DCMAKE_CUDA_ARCHITECTURES=86 ^
 -DCMAKE_CUDA_COMPILER=G:/cuda-13.3/bin/nvcc.exe ^
 -DCMAKE_CUDA_COMPILER_TOOLKIT_ROOT=G:/cuda-13.3 ^
 -DCMAKE_PREFIX_PATH=G:/build/vcpkg/installed/x64-windows ^
 -DVCPKG_TARGET_TRIPLET=x64-windows ^
 -DNINFER_BUILD_APPS=ON -DBUILD_TESTING=OFF -DNINFER_BUILD_BENCHMARKS=OFF >> G:\build\wemx-config.log 2>&1
echo CONFIG_EXIT=%ERRORLEVEL% >> G:\build\wemx-config.log
