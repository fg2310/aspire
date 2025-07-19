#!/bin/bash

# Extract API usage examples from playground and test changes
# Usage: ./extract-api-examples.sh <base_branch> <target_branch>

set -e

BASE_BRANCH=${1:-origin/release/9.3}
TARGET_BRANCH=${2:-origin/release/9.4}

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYSIS_DIR="$TOOLS_DIR/analysis-output"
EXAMPLES_DIR="$ANALYSIS_DIR/api-examples"

echo "🔧 Extracting API usage examples"
echo "📊 Analyzing: $BASE_BRANCH -> $TARGET_BRANCH"

mkdir -p "$EXAMPLES_DIR"

# Function to extract usage examples for a specific component (simplified)
extract_usage_examples() {
    local component="$1"
    local output_file="$2"
    
    echo "# Usage Examples for $component" > "$output_file"
    echo "" >> "$output_file"
    
    # For individual component files, just note that examples are in the global files
    echo "## Playground Examples" >> "$output_file"
    echo "See global playground examples in all-playground-examples.md" >> "$output_file"
    echo "" >> "$output_file"
    
    echo "## Test Examples" >> "$output_file"
    echo "See global test examples in all-test-examples.md" >> "$output_file"
    echo "" >> "$output_file"
    
    # Show what files changed in this component (for context)
    echo "## Changed Files in Component" >> "$output_file"
    changed_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- "$component/" 2>/dev/null)
    if [ -n "$changed_files" ]; then
        echo "\`\`\`" >> "$output_file"
        echo "$changed_files" >> "$output_file"
        echo "\`\`\`" >> "$output_file"
    else
        echo "No files changed in this component" >> "$output_file"
    fi
    echo "" >> "$output_file"
}

# Extract all playground examples globally
extract_all_playground_examples() {
    local output_file="$EXAMPLES_DIR/all-playground-examples.md"
    
    # Change to git root for git commands
    GIT_ROOT=$(git rev-parse --show-toplevel)
    cd "$GIT_ROOT"
    
    echo "# All Playground Examples" > "$output_file"
    echo "" >> "$output_file"
    echo "Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH" >> "$output_file"
    echo "" >> "$output_file"
    
    # Find new playground files
    echo "## New Playground Files" >> "$output_file"
    new_playground_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- playground/ | grep "^A" | cut -f2)
    if [ -n "$new_playground_files" ]; then
        for file in $new_playground_files; do
            if [[ "$file" == *.cs ]] || [[ "$file" == *.razor ]] || [[ "$file" == *.csproj ]]; then
                echo "### New file: $file" >> "$output_file"
                echo "\`\`\`csharp" >> "$output_file"
                git show $TARGET_BRANCH:"$file" 2>/dev/null >> "$output_file"
                echo "\`\`\`" >> "$output_file"
                echo "" >> "$output_file"
            fi
        done
    else
        echo "No new playground files found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Show changes in existing playground files
    echo "## Modified Playground Files" >> "$output_file"
    modified_playground_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- playground/ | grep "^M" | cut -f2)
    if [ -n "$modified_playground_files" ]; then
        for file in $modified_playground_files; do
            if [[ "$file" == *.cs ]] || [[ "$file" == *.razor ]] || [[ "$file" == *.csproj ]]; then
                echo "### Modified file: $file" >> "$output_file"
                echo "\`\`\`diff" >> "$output_file"
                git diff $BASE_BRANCH..$TARGET_BRANCH -- "$file" 2>/dev/null >> "$output_file"
                echo "\`\`\`" >> "$output_file"
                echo "" >> "$output_file"
            fi
        done
    else
        echo "No modified playground files found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Return to original directory
    cd "$TOOLS_DIR"
}

# Extract all test examples globally
extract_all_test_examples() {
    local output_file="$EXAMPLES_DIR/all-test-examples.md"
    
    # Change to git root for git commands
    GIT_ROOT=$(git rev-parse --show-toplevel)
    cd "$GIT_ROOT"
    
    echo "# All Test Examples" > "$output_file"
    echo "" >> "$output_file"
    echo "Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH" >> "$output_file"
    echo "" >> "$output_file"
    
    # Find new test files
    echo "## New Test Files" >> "$output_file"
    new_test_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- tests/ | grep "^A" | cut -f2)
    if [ -n "$new_test_files" ]; then
        for file in $new_test_files; do
            if [[ "$file" == *.cs ]]; then
                echo "### New test file: $file" >> "$output_file"
                echo "\`\`\`csharp" >> "$output_file"
                git show $TARGET_BRANCH:"$file" 2>/dev/null >> "$output_file"
                echo "\`\`\`" >> "$output_file"
                echo "" >> "$output_file"
            fi
        done
    else
        echo "No new test files found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Show changes in existing test files
    echo "## Modified Test Files" >> "$output_file"
    modified_test_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- tests/ | grep "^M" | cut -f2)
    if [ -n "$modified_test_files" ]; then
        for file in $modified_test_files; do
            if [[ "$file" == *.cs ]]; then
                echo "### Modified test file: $file" >> "$output_file"
                echo "\`\`\`diff" >> "$output_file"
                git diff $BASE_BRANCH..$TARGET_BRANCH -- "$file" 2>/dev/null >> "$output_file"
                echo "\`\`\`" >> "$output_file"
                echo "" >> "$output_file"
            fi
        done
    else
        echo "No modified test files found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Return to original directory
    cd "$TOOLS_DIR"
}

# Extract examples from major components
echo "🎯 Extracting API examples from major components..."

# Get components from config file, similar to analyze-all-components.sh
CONFIG_FILE="$TOOLS_DIR/config/component-priority.json"

if command -v jq &> /dev/null && [ -f "$CONFIG_FILE" ]; then
    # Use jq to extract components from config file
    RAW_COMPONENTS=($(jq -r '.analysis_priorities[]' "$CONFIG_FILE" 2>/dev/null || echo ""))
    
    # Expand glob patterns to actual directories (same logic as analyze-all-components.sh)
    COMPONENTS=()
    for pattern in "${RAW_COMPONENTS[@]}"; do
        if [[ "$pattern" == *"*"* ]]; then
            # This is a glob pattern, expand it from the git root
            GIT_ROOT=$(git rev-parse --show-toplevel)
            cd "$GIT_ROOT"
            for expanded_path in $pattern; do
                if [ -d "$expanded_path" ]; then
                    COMPONENTS+=("$expanded_path")
                fi
            done
            cd "$TOOLS_DIR"
        else
            # Regular path, add as-is if it exists
            GIT_ROOT=$(git rev-parse --show-toplevel)
            if [ -d "$GIT_ROOT/$pattern" ]; then
                COMPONENTS+=("$pattern")
            fi
        fi
    done
else
    # Fallback if config not available
    COMPONENTS=("src/Aspire.Hosting" "src/Aspire.Cli" "src/Aspire.Dashboard")
fi

# Extract examples from components (limit to first 10 to avoid too much output)
component_count=0
for component in "${COMPONENTS[@]}"; do
    if [ $component_count -ge 10 ]; then
        echo "  📝 (Limited to first 10 components for API extraction)"
        break
    fi
    echo "  📝 Extracting usage examples for: $component"
    component_name=$(basename "$component" | sed 's|/||g')
    output_file="$EXAMPLES_DIR/$component_name-usage-examples.md"
    extract_usage_examples "$component" "$output_file"
    ((component_count++))
done

# Extract global playground and test examples
echo "📋 Generating global playground examples..."
extract_all_playground_examples

echo "📋 Generating global test examples..."
extract_all_test_examples

# Generate general usage examples overview
echo "📋 Generating general usage examples overview..."

# Change to git root for git commands
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

# Get new playground and test files with their actual content
echo "# Playground & Test Examples Overview" > "$EXAMPLES_DIR/usage-overview.md"
echo "" >> "$EXAMPLES_DIR/usage-overview.md"
echo "Generated from: $BASE_BRANCH -> $TARGET_BRANCH" >> "$EXAMPLES_DIR/usage-overview.md"
echo "" >> "$EXAMPLES_DIR/usage-overview.md"

echo "## Summary of New Playground Files" >> "$EXAMPLES_DIR/usage-overview.md"
new_playground=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- playground/ | grep "^A" | cut -f2)
if [ -n "$new_playground" ]; then
    echo "$new_playground" >> "$EXAMPLES_DIR/usage-overview.md"
else
    echo "No new playground files" >> "$EXAMPLES_DIR/usage-overview.md"
fi

echo "" >> "$EXAMPLES_DIR/usage-overview.md"
echo "## Summary of New Test Files" >> "$EXAMPLES_DIR/usage-overview.md"
new_tests=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- tests/ | grep "^A" | cut -f2)
if [ -n "$new_tests" ]; then
    echo "$new_tests" >> "$EXAMPLES_DIR/usage-overview.md"
else
    echo "No new test files" >> "$EXAMPLES_DIR/usage-overview.md"
fi

# Return to original directory
cd "$TOOLS_DIR"

# Generate consolidated examples file
echo "📋 Generating consolidated examples..."
consolidated_file="$EXAMPLES_DIR/all-api-examples.md"

cat > "$consolidated_file" << EOF
# API Usage Examples

Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH

## Overview

This document contains real API usage examples extracted from playground applications,
test files, and commit diffs to demonstrate new and changed APIs in this release.

EOF

# Add each example file
for example_file in "$EXAMPLES_DIR"/*.md; do
    if [ -f "$example_file" ] && [ "$example_file" != "$consolidated_file" ]; then
        echo "" >> "$consolidated_file"
        echo "---" >> "$consolidated_file"
        echo "" >> "$consolidated_file"
        cat "$example_file" >> "$consolidated_file"
    fi
done

echo ""
echo "✅ API examples extraction complete!"
echo "📁 Examples directory: $EXAMPLES_DIR/"
echo "📄 Consolidated examples: $consolidated_file"
echo ""
echo "📋 Generated files:"
ls -1 "$EXAMPLES_DIR"/*.md | sed 's/^/   /'
