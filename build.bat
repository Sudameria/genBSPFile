@echo off

REM Limpiar los archivos previos
rmdir /S /Q build
rmdir /S /Q dist
del *.spec

REM Ejecutar PyInstaller para crear un ejecutable standalone
pyinstaller --onefile gen.py

REM Mensaje de éxito
echo Ejecutable creado en la carpeta dist
pause
