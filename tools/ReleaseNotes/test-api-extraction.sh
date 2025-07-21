#!/bin/bash

# Simple test script to validate the API extraction approach
# Tests the dotnet build command and reference assembly generation

set -e

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

echo "🧪 Testing API extraction approach..."
echo "📍 Working in: $(pwd)"

# Test with a single project first
TEST_PROJECT="src/Aspire.Hosting/Aspire.Hosting.csproj"

if [ ! -f "$TEST_PROJECT" ]; then
    echo "❌ Test project not found: $TEST_PROJECT"
    exit 1
fi

echo "🔨 Testing build with reference assembly generation..."
echo "📦 Project: $TEST_PROJECT"

# Create a temp directory for output
TEMP_DIR=$(mktemp -d)
echo "📁 Temp directory: $TEMP_DIR"

# Test the build command
echo "⚡ Running: dotnet build $TEST_PROJECT -f net8.0 -c Release --no-incremental /t:\"Build;GenAPIGenerateReferenceAssemblySource\""

if dotnet build "$TEST_PROJECT" -f net8.0 -c Release --no-incremental /t:"Build;GenAPIGenerateReferenceAssemblySource" --verbosity normal > "$TEMP_DIR/build.log" 2>&1; then
    echo "✅ Build succeeded!"
    
    # Look for generated reference assembly files
    PROJECT_DIR=$(dirname "$TEST_PROJECT")
    echo "🔍 Looking for reference assembly files in: $PROJECT_DIR"
    
    # Common locations for generated reference assemblies
    REF_FILES=$(find "$PROJECT_DIR" -name "*.cs" -path "*/obj/Release/*/ref/*" 2>/dev/null || true)
    
    if [ -n "$REF_FILES" ]; then
        echo "✅ Found reference assembly files:"
        for file in $REF_FILES; do
            echo "  📄 $file"
            echo "     Size: $(wc -l < "$file") lines"
            # Show first few lines
            echo "     Preview:"
            head -5 "$file" | sed 's/^/       /'
        done
    else
        echo "⚠️  No reference assembly files found in expected locations"
        echo "🔍 Searching for any .cs files in obj directories..."
        find "$PROJECT_DIR" -name "*.cs" -path "*/obj/*" 2>/dev/null | head -10 | while read -r file; do
            echo "  📄 $file"
        done
    fi
    
    echo ""
    echo "📋 Build log location: $TEMP_DIR/build.log"
    echo "📄 Build log preview (last 10 lines):"
    tail -10 "$TEMP_DIR/build.log" | sed 's/^/   /'
    
else
    echo "❌ Build failed!"
    echo "📋 Build log:"
    cat "$TEMP_DIR/build.log" | sed 's/^/   /'
fi

echo ""
echo "🔍 Alternative: Look for existing API files..."
API_FILES=$(find "$PROJECT_DIR" -name "*.cs" -path "*/api/*" 2>/dev/null || true)
if [ -n "$API_FILES" ]; then
    echo "✅ Found existing API files:"
    for file in $API_FILES; do
        echo "  📄 $file"
        echo "     Size: $(wc -l < "$file") lines"
    done
else
    echo "ℹ️  No existing API files found"
fi

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "🧪 Test completed!"
