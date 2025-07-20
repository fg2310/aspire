#!/bin/bash

# Master script for automated release notes generation
# Usage: ./generate-release-notes.sh <base_branch> <target_branch>
# Example: ./generate-release-notes.sh release/9.3 release/9.4

set -e

BASE_BRANCH=${1:-origin/release/9.3}
TARGET_BRANCH=${2:-origin/release/9.4}
VERSION=$(echo $TARGET_BRANCH | grep -o '[0-9]\+\.[0-9]\+' || echo "unknown")

echo "🚀 Starting automated release notes generation"
echo "📊 Analyzing changes: $BASE_BRANCH -> $TARGET_BRANCH"
echo "📝 Target version: $VERSION"
echo "⏱️  This process may take 5-10 minutes depending on repository size..."
echo ""

# Start total timing
SCRIPT_START_TIME=$(date +%s)

# Setup workspace
TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYSIS_DIR="$TOOLS_DIR/analysis-output"
OUTPUT_FILE="$TOOLS_DIR/release-notes-$VERSION.md"

mkdir -p "$ANALYSIS_DIR"

# Step 1: Initialize and validate
echo "🔍 Step 1: Initializing analysis workspace..."
STEP1_START=$(date +%s)
if [ -f "$TOOLS_DIR/init-release-analysis.sh" ]; then
    "$TOOLS_DIR/init-release-analysis.sh" "$BASE_BRANCH" "$TARGET_BRANCH"
else
    echo "⚠️  init-release-analysis.sh not found, skipping validation"
fi
STEP1_END=$(date +%s)
echo "✅ Step 1 completed in $((STEP1_END - STEP1_START))s"

# Step 2: Analyze all components
echo "📁 Step 2: Analyzing all components..."
STEP2_START=$(date +%s)
if [ -f "$TOOLS_DIR/analyze-all-components.sh" ]; then
    "$TOOLS_DIR/analyze-all-components.sh" "$BASE_BRANCH" "$TARGET_BRANCH"
else
    echo "⚠️  analyze-all-components.sh not found, using basic analysis"
    # Fallback to existing script
    if [ -f "$TOOLS_DIR/analyze_folder.sh" ]; then
        echo "Using existing analyze_folder.sh for major components..."
        for component in "src/Aspire.Cli" "src/Aspire.Dashboard" "src/Aspire.ProjectTemplates" "src/Aspire.Hosting"; do
            echo "Analyzing $component..."
            "$TOOLS_DIR/analyze_folder.sh" "$component" > "$ANALYSIS_DIR/$(basename $component).md"
        done
    fi
fi
STEP2_END=$(date +%s)
echo "✅ Step 2 completed in $((STEP2_END - STEP2_START))s"

# Step 3: Extract API usage examples
echo "🔧 Step 3: Extracting API usage examples..."
STEP3_START=$(date +%s)
if [ -f "$TOOLS_DIR/extract-api-examples.sh" ]; then
    "$TOOLS_DIR/extract-api-examples.sh" "$BASE_BRANCH" "$TARGET_BRANCH"
else
    echo "⚠️  extract-api-examples.sh not found, using manual extraction"
    # Basic playground/tests analysis
    git log --oneline --no-merges $BASE_BRANCH..$TARGET_BRANCH -- playground/ > "$ANALYSIS_DIR/playground-changes.txt"
    git log --oneline --no-merges $BASE_BRANCH..$TARGET_BRANCH -- tests/ > "$ANALYSIS_DIR/test-changes.txt"
fi
STEP3_END=$(date +%s)
echo "✅ Step 3 completed in $((STEP3_END - STEP3_START))s"

# Step 4: Generate structured release notes
echo "📝 Step 4: Generating structured release notes..."
STEP4_START=$(date +%s)
if [ -f "$TOOLS_DIR/generate-structured-notes.sh" ]; then
    "$TOOLS_DIR/generate-structured-notes.sh" "$VERSION"
else
    echo "⚠️  generate-structured-notes.sh not found, using basic template"
    # Basic release notes generation
    cat > "$OUTPUT_FILE" << EOF
# .NET Aspire $VERSION Release Notes

## 🎯 What's New

### Major Components Updated

EOF
    
    # Add analysis from each component if available
    for analysis_file in "$ANALYSIS_DIR"/*.md; do
        if [ -f "$analysis_file" ]; then
            echo "Adding analysis from $(basename "$analysis_file")"
            echo "" >> "$OUTPUT_FILE"
            cat "$analysis_file" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    done
fi
STEP4_END=$(date +%s)
echo "✅ Step 4 completed in $((STEP4_END - STEP4_START))s"

# Step 5: Finalize and format
echo "✨ Step 5: Finalizing release notes..."
STEP5_START=$(date +%s)
if [ -f "$TOOLS_DIR/finalize-release-notes.sh" ]; then
    "$TOOLS_DIR/finalize-release-notes.sh" "$OUTPUT_FILE"
else
    echo "⚠️  finalize-release-notes.sh not found, using basic formatting"
    # Add table of contents and final formatting
    echo "# Table of Contents" > "$OUTPUT_FILE.tmp"
    echo "" >> "$OUTPUT_FILE.tmp"
    grep "^##" "$OUTPUT_FILE" | sed 's/^## /- [/' | sed 's/$/)/' | sed 's/\] /]\(#/' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' >> "$OUTPUT_FILE.tmp"
    echo "" >> "$OUTPUT_FILE.tmp"
    cat "$OUTPUT_FILE" >> "$OUTPUT_FILE.tmp"
    mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
fi
STEP5_END=$(date +%s)
echo "✅ Step 5 completed in $((STEP5_END - STEP5_START))s"

# Calculate total time
SCRIPT_END_TIME=$(date +%s)
TOTAL_TIME=$((SCRIPT_END_TIME - SCRIPT_START_TIME))

echo ""
echo "✅ Release notes generation complete!"
echo "⏱️  Total execution time: ${TOTAL_TIME}s"
echo ""
echo "📊 Step Timing Summary:"
echo "   Step 1 (Initialize): $((STEP1_END - STEP1_START))s"
echo "   Step 2 (Components): $((STEP2_END - STEP2_START))s" 
echo "   Step 3 (API Examples): $((STEP3_END - STEP3_START))s"
echo "   Step 4 (Generate Notes): $((STEP4_END - STEP4_START))s"
echo "   Step 5 (Finalize): $((STEP5_END - STEP5_START))s"
echo ""
echo "📄 Output file: $OUTPUT_FILE"
echo "📊 Analysis data: $ANALYSIS_DIR/"
echo ""
echo "🔍 Next steps:"
echo "   1. Review the generated release notes"
echo "   2. Add any missing context or examples"
echo "   3. Validate breaking changes and migration guides"
echo "   4. Format for final publication"
