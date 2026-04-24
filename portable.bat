@echo off
setlocal

set "ROOT=%~dp0"
set "SOURCE=%ROOT%flutter_app\build\windows\x64\runner\Release"
set "OUT=%ROOT%dist"
set "NAME=hedef_dorking"
set "MAIN_EXE=hedef_dorking.exe"

if not exist "%SOURCE%\%MAIN_EXE%" (
    echo HATA: Release uygulamasi bulunamadi.
    echo Once build.bat calistirip release uretilmeli.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%tools\new-portable-package.ps1" ^
  -SourceDir "%SOURCE%" ^
  -MainExe "%MAIN_EXE%" ^
  -OutDir "%OUT%" ^
  -PackageName "%NAME%"

if %errorlevel% neq 0 (
    echo HATA: Portable paket olusturma basarisiz.
    exit /b 1
)

echo.
echo Portable paketler hazir: %OUT%
echo - %NAME%.zip
echo - %NAME%_portable.exe

endlocal
