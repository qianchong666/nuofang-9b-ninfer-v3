@echo off
REM ============================================================================
REM  build-sm86.bat  --  build ninfer-serve for RTX 3090 (sm_86) on Windows
REM
REM  Prereqs (adjust the four paths below if yours differ):
REM    * Visual Studio 18 BuildTools (MSVC 14.51)  -- VS2022 14.44 fails with C2326
REM    * CUDA Toolkit 13.3
REM    * CMake 4.x + Ninja
REM    * vcpkg with curl / zlib / ffmpeg installed for x64-windows
REM    * source: git clone --depth 1 https://github.com/wemxueming/ninfer-for-index-translate-9b-4060
REM ============================================================================
setlocal

set "SRC=G:\build\wemx-9b\src\src-tree\fusion-engine-src"
set "BUILD=G:\build\wemx-86"
set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set "CUDAROOT=G:\cuda-13.3"
set "VCPKG=G:\build\vcpkg"
set "CMAKE=G:\cmake-4.4.3-windows-x86_64\bin\cmake.exe"
set "NINJA=G:\miniconda3\Scripts\ninja.exe"

if not exist "%SRC%" echo [x] source not found: %SRC% & exit /b 1
if not exist "%BUILD%" mkdir "%BUILD%"

call "%VCVARS%" >nul
set "PATH=%CUDAROOT%\bin;%CUDAROOT%\bin\x64;%PATH%"
set "CUDACXX=%CUDAROOT%\bin\nvcc.exe"
set "VCPKG_ROOT=%VCPKG%"
set "VCPKG_TARGET_TRIPLET=x64-windows"

echo [1/3] configure
"%CMAKE%" -S "%SRC%" -B "%BUILD%" -G Ninja ^
 -DCMAKE_MAKE_PROGRAM=%NINJA% ^
 -DCMAKE_BUILD_TYPE=Release ^
 -DCMAKE_CUDA_ARCHITECTURES=86 ^
 -DCMAKE_CUDA_COMPILER=%CUDAROOT%/bin/nvcc.exe ^
 -DCMAKE_CUDA_COMPILER_TOOLKIT_ROOT=%CUDAROOT% ^
 -DCMAKE_PREFIX_PATH=%VCPKG%/installed/x64-windows ^
 -DVCPKG_TARGET_TRIPLET=x64-windows ^
 -DNINFER_BUILD_APPS=ON -DBUILD_TESTING=OFF -DNINFER_BUILD_BENCHMARKS=OFF
if errorlevel 1 exit /b 1

echo [2/3] build (this takes tens of minutes: small_t_i8_* / launch.cu are heavy)
"%NINJA%" -C "%BUILD%" -j 20 ninfer-serve
if errorlevel 1 exit /b 1

echo [3/3] stage CRT DLLs next to the exe
for %%F in ("%VCPKG%\..\ninfer-86\apps\api-ms-win-crt-*.dll") do if not exist "%BUILD%\apps\%%~nxF" copy "%%~fF" "%BUILD%\apps\" >nul

echo.
echo Done: %BUILD%\apps\ninfer-serve.exe
echo Next: copy cublasLt64_13.dll / cublas64_13.dll / cudart64_13.dll (CUDA 13.3) and the
echo       FFmpeg av* / sw* DLLs next to the exe, then run examples\run-sm86-262k.bat
