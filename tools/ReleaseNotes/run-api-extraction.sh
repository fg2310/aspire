#!/bin/bash

# Run the full API changes extraction with build + git diff approach
# This is the main script that processes all projects
# Usage: ./run-api-extraction.sh [base_branch] [target_branch]

set -e

BASE_BRANCH=${1:-origin/release/9.3}
TARGET_BRANCH=${2:-origin/release/9.4}

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYSIS_DIR="$TOOLS_DIR/analysis-output"
API_CHANGES_DIR="$ANALYSIS_DIR/api-changes-build"

echo "🚀 Running complete API changes extraction"
echo "📊 Analyzing: $BASE_BRANCH -> $TARGET_BRANCH"
echo "⏱️  This will take several minutes..."

# Start timing
START_TIME=$(date +%s)

# Make sure we have the latest
echo "🔄 Fetching latest changes..."
git fetch --quiet

# Run the full extraction
echo ""
echo "📋 Starting full API extraction process..."
"$TOOLS_DIR/extract-api-changes-via-build.sh" "$BASE_BRANCH" "$TARGET_BRANCH"

# Calculate time
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo ""
echo "✅ Complete API extraction finished!"
echo "⏱️  Total time: ${TOTAL_TIME}s"
echo ""
echo "📂 Results directory: $API_CHANGES_DIR"
echo "📋 Key files:"
echo "   📄 Consolidated report: $API_CHANGES_DIR/consolidated-api-changes.md"
echo "   📄 Summary: $API_CHANGES_DIR/api-changes-summary.md"
echo "   📄 Build impact: $API_CHANGES_DIR/build-impact.md"
echo ""

# Show summary stats
if [ -f "$API_CHANGES_DIR/api-changes-summary.md" ]; then
    echo "📊 Quick Stats:"
    
    # Count how many component files were created (indicates changes)
    COMPONENT_FILES=$(find "$API_CHANGES_DIR" -name "*-api-changes.md" | wc -l)
    echo "   📦 Components with changes: $COMPONENT_FILES"
    
    # Show total file count
    TOTAL_FILES=$(find "$API_CHANGES_DIR" -name "*.md" | wc -l)
    echo "   📄 Total analysis files: $TOTAL_FILES"
    
    echo ""
    echo "🔍 To view results:"
    echo "   📖 View summary: cat $API_CHANGES_DIR/api-changes-summary.md"
    echo "   📖 View full report: cat $API_CHANGES_DIR/consolidated-api-changes.md"
    echo "   📁 Browse all files: ls -la $API_CHANGES_DIR/"
fi
