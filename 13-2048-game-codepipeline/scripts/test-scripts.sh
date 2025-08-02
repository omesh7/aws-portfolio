#!/bin/bash

echo "Testing Linux Scripts"
echo "====================="

echo ""
echo "1. Testing run.sh with status..."
./run.sh status
echo "Status: $?"

echo ""
echo "2. Testing run.sh with deploy (will fail at terraform.tfvars check)..."
echo "n" | timeout 10 ./run.sh deploy 2>/dev/null || echo "Deploy test completed (expected failure)"

echo ""
echo "3. Testing run.sh with destroy (cancelled)..."
echo "n" | ./run.sh destroy
echo "Destroy: $?"

echo ""
echo "All Linux script tests completed!"