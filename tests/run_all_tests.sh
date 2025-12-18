#!/bin/bash
# Run all genetics tests
# Usage: ./tests/run_all_tests.sh

echo "Running Dragon Ranch Genetics Tests"
echo "===================================="
echo ""

# Check if godot is available
if ! command -v godot &> /dev/null; then
    echo "ERROR: Godot not found in PATH"
    echo "Please ensure Godot 4.x is installed and in your PATH"
    exit 1
fi

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0

# Run breeding tests
echo "Running breeding tests..."
godot --headless --script tests/genetics/test_breeding.gd
if [ $? -eq 0 ]; then
    ((TOTAL_PASSED++))
else
    ((TOTAL_FAILED++))
fi

echo ""

# Run phenotype tests
echo "Running phenotype tests..."
godot --headless --script tests/genetics/test_phenotype.gd
if [ $? -eq 0 ]; then
    ((TOTAL_PASSED++))
else
    ((TOTAL_FAILED++))
fi

echo ""

# Run normalization tests
echo "Running normalization tests..."
godot --headless --script tests/genetics/test_normalization.gd
if [ $? -eq 0 ]; then
    ((TOTAL_PASSED++))
else
    ((TOTAL_FAILED++))
fi

echo ""
echo "===================================="
echo "Overall Results: $TOTAL_PASSED test suites passed, $TOTAL_FAILED failed"
echo "===================================="

exit $TOTAL_FAILED
