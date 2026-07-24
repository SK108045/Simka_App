@echo off
cd /d "%~dp0"
where python >nul 2>nul
if %errorlevel%==0 (
    set PYCMD=python
) else (
    set PYCMD=py
)
echo Installing required package...
%PYCMD% -m pip install -r requirements.txt
echo Starting SIMKA Invoice Web App...
%PYCMD% app.py
pause
