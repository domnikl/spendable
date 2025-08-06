#!/bin/bash

# Test runner script to ensure all tests pass
# Run this script to verify test suite integrity

echo "🧪 Running comprehensive test suite..."
echo

# Run all tests
echo "Running all tests..."
if mix test; then
    echo "✅ All tests passed!"
    echo
    
    # Run specific critical test suites
    echo "🔍 Running critical payment functionality tests..."
    if mix test test/spendable/payment_ui_fix_test.exs test/spendable/partial_finalization_test.exs; then
        echo "✅ Payment functionality tests passed!"
        echo
        
        echo "🔍 Running domain logic tests..."
        if mix test test/spendable/; then
            echo "✅ Domain logic tests passed!"
            echo
            echo "🎉 Test suite is healthy and ready for future development!"
        else
            echo "❌ Domain logic tests failed"
            exit 1
        fi
    else
        echo "❌ Payment functionality tests failed"
        exit 1
    fi
else
    echo "❌ Some tests failed"
    exit 1
fi