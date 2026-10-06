@echo off
setlocal enabledelayedexpansion
REM Run every headless test suite (tests\**\test_*.gd) under the project's autoloads.
REM Usage: tests\run_all_tests.bat
REM Set GODOT to the Godot 4.5 binary if it is not "godot" on PATH, e.g.
REM   set GODOT=..\Godot_v4.5-stable_win64.exe

if "%GODOT%"=="" set GODOT=godot
cd /d "%~dp0.."

where "%GODOT%" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Godot not found ^(%GODOT%^). Set GODOT to the Godot 4.5 binary.
    exit /b 1
)

echo Running Dragon Ranch Tests
echo ==========================

set TOTAL_PASSED=0
set TOTAL_FAILED=0
set FAILED_NAMES=

for /r tests %%F in (test_*.gd) do (
    echo.
    echo --- %%F
    "%GODOT%" --headless --path . --script "%%F"
    if !ERRORLEVEL! EQU 0 (
        set /a TOTAL_PASSED+=1
    ) else (
        set /a TOTAL_FAILED+=1
        set FAILED_NAMES=!FAILED_NAMES! %%~nxF
    )
)

echo.
echo ==========================
echo Overall Results: %TOTAL_PASSED% suites passed, %TOTAL_FAILED% failed
if not "%FAILED_NAMES%"=="" echo Failed:%FAILED_NAMES%
echo ==========================

exit /b %TOTAL_FAILED%
