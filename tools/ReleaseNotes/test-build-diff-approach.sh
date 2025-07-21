#!/bin/bash

# Test the build + git diff approach on a single project
# Usage: ./test-build-diff-approach.sh [base_branch] [target_branch]

set -e

BASE_BRANCH=${1:-origin/release/9.3}
TARGET_BRANCH=${2:-origin/release/9.4}

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

echo "🧪 Testing build + git diff approach for API extraction"
echo "📊 Comparing: $BASE_BRANCH -> $TARGET_BRANCH"
echo "📍 Working in: $(pwd)"

# Test with Aspire.Hosting project
TEST_PROJECT="src/Aspire.Hosting/Aspire.Hosting.csproj"
API_FILE="src/Aspire.Hosting/api/Aspire.Hosting.cs"

if [ ! -f "$TEST_PROJECT" ]; then
    echo "❌ Test project not found: $TEST_PROJECT"
    exit 1
fi

if [ ! -f "$API_FILE" ]; then
    echo "❌ API file not found: $API_FILE"
    exit 1
fi

echo ""
echo "📦 Test project: $(basename "$TEST_PROJECT")"
echo "📄 API file: $API_FILE"
echo "📏 Current API file size: $(wc -l < "$API_FILE") lines"

echo ""
echo "🔄 Step 1: Switch to target branch and build"
git checkout "$TARGET_BRANCH" --quiet
echo "✅ Switched to: $TARGET_BRANCH"

echo "🔨 Building project to update API files..."
if dotnet build "$TEST_PROJECT" -f net8.0 -c Release --no-incremental --verbosity minimal; then
    echo "✅ Build completed successfully"
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "📏 Updated API file size: $(wc -l < "$API_FILE") lines"

echo ""
echo "🔍 Step 2: Check for changes compared to base branch"
echo "🔍 Running: git diff $BASE_BRANCH -- $API_FILE"

DIFF_OUTPUT=$(git diff "$BASE_BRANCH" -- "$API_FILE" 2>/dev/null || true)

if [ -n "$DIFF_OUTPUT" ]; then
    echo "✅ Changes detected!"
    echo ""
    echo "📊 Diff statistics:"
    echo "   Additions: $(echo "$DIFF_OUTPUT" | grep "^+" | grep -v "^+++" | wc -l) lines"
    echo "   Deletions: $(echo "$DIFF_OUTPUT" | grep "^-" | grep -v "^---" | wc -l) lines"
    echo ""
    
    echo "🔍 New public APIs (preview):"
    NEW_APIS=$(echo "$DIFF_OUTPUT" | grep "^+" | grep -E "public.*(class|interface|enum|struct|delegate)" | head -5)
    if [ -n "$NEW_APIS" ]; then
        echo "$NEW_APIS" | sed 's/^+/   /'
    else
        echo "   (No new public types detected)"
    fi
    echo ""
    
    echo "🔍 New public members (preview):"
    NEW_MEMBERS=$(echo "$DIFF_OUTPUT" | grep "^+" | grep -E "public.*[A-Za-z]+.*\(" | head -5)
    if [ -n "$NEW_MEMBERS" ]; then
        echo "$NEW_MEMBERS" | sed 's/^+/   /'
    else
        echo "   (No new public members detected)"
    fi
    echo ""
    
    echo "📋 Full diff (first 20 lines):"
    echo "$DIFF_OUTPUT" | head -20
    
    # Save diff to file for inspection
    TEMP_DIFF_FILE="/tmp/aspire-api-diff-test.txt"
    echo "$DIFF_OUTPUT" > "$TEMP_DIFF_FILE"
    echo ""
    echo "💾 Full diff saved to: $TEMP_DIFF_FILE"
    
else
    echo "ℹ️  No changes detected between $BASE_BRANCH and $TARGET_BRANCH"
    echo ""
    echo "🔍 This could mean:"
    echo "   - No API changes were made"
    echo "   - API files are already up to date"  
    echo "   - Build process didn't update the API files"
fi

echo ""
echo "🔍 Step 3: Check git status (what files were modified by build)"
MODIFIED_FILES=$(git status --porcelain | grep "^ M" | cut -c4- || true)

if [ -n "$MODIFIED_FILES" ]; then
    echo "✅ Build process modified files:"
    echo "$MODIFIED_FILES" | sed 's/^/   /'
    
    # Check if API file was modified
    if echo "$MODIFIED_FILES" | grep -q "$API_FILE"; then
        echo "✅ API file was updated by build process"
    else
        echo "ℹ️  API file was not modified by build process"
    fi
else
    echo "ℹ️  No files were modified by the build process"
fi

echo ""
echo "🧪 Test completed!"
echo ""
echo "📋 Summary:"
echo "   - Build: ✅ Successful"
echo "   - API Changes: $([ -n "$DIFF_OUTPUT" ] && echo "✅ Detected" || echo "ℹ️  None")"
echo "   - Files Modified: $([ -n "$MODIFIED_FILES" ] && echo "✅ Yes" || echo "ℹ️  None")"
