#!/bin/bash
set -e

echo "=== Building UNJUST dashboard + report ==="

# 1. Build the React dashboard
echo "--- Building dashboard ---"
cd dashboard
npm ci
npm run build
cd ..

# 2. Build the Quarto report
echo "--- Building report ---"
cd report
quarto render
cd ..

# 3. Assemble dist/
echo "--- Assembling dist/ ---"
rm -rf dist
mkdir -p dist/report

# Dashboard at root
cp -r dashboard/dist/* dist/

# Report at /report/
cp -r report/_book/* dist/report/

echo "=== Build complete. Output in dist/ ==="
