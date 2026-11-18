@echo off
setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
set "PATH=G:\cuda-13.3\bin;G:\cuda-13.3\bin\x64;%PATH%"
set "CUDACXX=G:\cuda-13.3\bin\nvcc.exe"
set "VCPKG_ROOT=G:\build\vcpkg"
echo NINJA_START=%DATE% %TIME% > G:\build\wemx-ninja2.log
"G:\miniconda3\Scripts\ninja.exe" -C "G:\build\wemx-86" -j 20 ninfer-serve >> G:\build\wemx-ninja2.log 2>&1
echo NINJA_EXIT=%ERRORLEVEL% >> G:\build\wemx-ninja2.log
