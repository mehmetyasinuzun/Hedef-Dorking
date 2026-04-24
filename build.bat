@echo off
setlocal

set "ROOT=%~dp0"
set "BACKEND_DIR=%ROOT%backend"
set "FLUTTER_DIR=%ROOT%flutter_app"
set "BACKEND_EXE=%BACKEND_DIR%\dorking.exe"
set "ASSET_EXE=%FLUTTER_DIR%\assets\backend\dorking.exe"
set "APP_EXE=%FLUTTER_DIR%\build\windows\x64\runner\Release\hedef_dorking.exe"

echo [1/5] Go backend derleniyor...
pushd "%BACKEND_DIR%"
go build -o dorking.exe .
if %errorlevel% neq 0 (
    popd
    echo HATA: go build basarisiz
    exit /b 1
)
popd

echo [2/5] Go exe assets klasorune kopyalaniyor...
copy /y "%BACKEND_EXE%" "%ASSET_EXE%" >nul
if %errorlevel% neq 0 (
    echo HATA: exe kopyalanamadi
    exit /b 1
)

echo [3/5] Flutter bagimliliklari yukleniyor...
pushd "%FLUTTER_DIR%"
call flutter pub get
if %errorlevel% neq 0 (
    popd
    echo HATA: flutter pub get basarisiz
    exit /b 1
)

echo [4/5] Flutter derleniyor...
call flutter build windows --release
if %errorlevel% neq 0 (
    popd
    echo HATA: flutter build basarisiz
    exit /b 1
)
popd

if not exist "%APP_EXE%" (
    echo HATA: derlenen uygulama bulunamadi
    echo Beklenen yol: %APP_EXE%
    exit /b 1
)

echo.
echo Tamamlandi.
echo Cikti: %APP_EXE%

echo [5/5] Derlenen uygulama aciliyor...
start "" "%APP_EXE%"

endlocal
