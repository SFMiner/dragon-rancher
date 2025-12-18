@echo off
REM Run all genetics tests on Windows
REM Usage: tests\run_all_tests.bat

echo Running Dragon Ranch Genetics Tests
echo ====================================
echo.

REM Check if godot is available
where godot >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Godot not found in PATH
    echo Please ensure Godot 4.x is installed and in your PATH
    exit /b 1
)

REM Track overall results
set TOTAL_PASSED=0
set TOTAL_FAILED=0

REM Run breeding tests
echo Running breeding tests...
godot --headless --script tests/genetics/test_breeding.gd
if %ERRORLEVEL% EQU 0 (
    set /a TOTAL_PASSED+=1
) else (
    set /a TOTAL_FAILED+=1
)

echo.

REM Run phenotype tests
echo Running phenotype tests...
godot --headless --script tests/genetics/test_phenotype.gd
if %ERRORLEVEL% EQU 0 (
    set /a TOTAL_PASSED+=1
) else (
    set /a TOTAL_FAILED+=1
)

echo.

REM Run normalization tests
echo Running normalization tests...
godot --headless --script tests/genetics/test_normalization.gd
if %ERRORLEVEL% EQU 0 (
    set /a TOTAL_PASSED+=1
) else (
    set /a TOTAL_FAILED+=1
)

echo.
echo ====================================
echo Overall Results: %TOTAL_PASSED% test suites passed, %TOTAL_FAILED% failed
echo ====================================

exit /b %TOTAL_FAILED%
