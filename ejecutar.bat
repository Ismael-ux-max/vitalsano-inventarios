@echo off
rem Compila y ejecuta el sistema de inventario de VitalSano (requiere JDK 11 o superior en el PATH).
chcp 65001 > nul
cd /d "%~dp0"
if not exist out mkdir out
javac -encoding UTF-8 -d out src\modelo\*.java src\negocio\*.java src\interfaz\*.java
if errorlevel 1 (
    echo.
    echo No se pudo compilar. Verifique que el JDK 11 o superior este instalado y en el PATH.
    pause
    exit /b 1
)
java -Dfile.encoding=UTF-8 -Dstdout.encoding=UTF-8 -cp out interfaz.Main
pause
