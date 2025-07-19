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

# Function to extract code examples from a commit diff
extract_examples_from_commit() {
    local commit_hash="$1"
    local output_file="$2"
    
    echo "# API Examples from commit $commit_hash" > "$output_file"
    echo "" >> "$output_file"
    
    # Get commit message
    echo "## Commit: $(git log --format="%s" -n 1 $commit_hash)" >> "$output_file"
    echo "" >> "$output_file"
    
    # Extract C# code blocks from the diff
    git show "$commit_hash" -- playground/ tests/ | \
        awk '/^+.*\.cs$|^+.*builder\.|^+.*Add[A-Z]|^+.*With[A-Z]/ { 
            if ($0 ~ /^\+/ && $0 !~ /^\+\+\+/) {
                gsub(/^\+/, "", $0)
                print $0
            }
        }' | \
        grep -E "(AddParameter|WithDescription|WithCustomInput|AddExternalService|WithHealthCheck|builder\.)" | \
        head -20 >> "$output_file" 2>/dev/null || echo "No API examples found" >> "$output_file"
    
    echo "" >> "$output_file"
}

# Find commits that modified playground or test files with API examples
echo "🔍 Finding commits with API examples..."

api_commits=$(git log --oneline --no-merges $BASE_BRANCH..$TARGET_BRANCH -- playground/ tests/ | \
    grep -E "(parameter|external|input|dialog|interaction)" | \
    head -10 | \
    awk '{print $1}')

if [ -z "$api_commits" ]; then
    echo "⚠️  No API-related commits found in playground/tests"
    # Fallback: get recent commits
    api_commits=$(git log --oneline --no-merges $BASE_BRANCH..$TARGET_BRANCH -- playground/ tests/ | head -5 | awk '{print $1}')
fi

# Extract examples from each commit
for commit in $api_commits; do
    if [ -n "$commit" ]; then
        output_file="$EXAMPLES_DIR/examples-$commit.md"
        echo "  📝 Extracting from commit: $commit"
        extract_examples_from_commit "$commit" "$output_file"
    fi
done

# Extract specific API patterns from key files
echo "🎯 Extracting specific API patterns..."

# Parameter API examples
echo "## Parameter API Examples" > "$EXAMPLES_DIR/parameter-apis.md"
echo "" >> "$EXAMPLES_DIR/parameter-apis.md"
git show $TARGET_BRANCH:playground/ParameterEndToEnd/ParameterEndToEnd.AppHost/Program.cs 2>/dev/null | \
    grep -A 10 -B 2 "AddParameter\|WithDescription\|WithCustomInput" >> "$EXAMPLES_DIR/parameter-apis.md" || \
    echo "Parameter examples not found" >> "$EXAMPLES_DIR/parameter-apis.md"

# External service examples  
echo "## External Service API Examples" > "$EXAMPLES_DIR/external-service-apis.md"
echo "" >> "$EXAMPLES_DIR/external-service-apis.md"
git show $TARGET_BRANCH:playground/ExternalServices/ExternalServices.AppHost/AppHost.cs 2>/dev/null | \
    grep -A 10 -B 2 "AddExternalService\|WithHealthCheck" >> "$EXAMPLES_DIR/external-service-apis.md" || \
    echo "External service examples not found" >> "$EXAMPLES_DIR/external-service-apis.md"

# Test examples showing expected behavior
echo "## Test API Examples" > "$EXAMPLES_DIR/test-apis.md" 
echo "" >> "$EXAMPLES_DIR/test-apis.md"
git diff $BASE_BRANCH..$TARGET_BRANCH -- tests/Aspire.Hosting.Tests/AddParameterTests.cs | \
    grep -A 5 -B 5 "^\+" | \
    grep -E "(AddParameter|WithDescription|WithCustomInput|Assert\.Equal)" >> "$EXAMPLES_DIR/test-apis.md" 2>/dev/null || \
    echo "Test examples not found" >> "$EXAMPLES_DIR/test-apis.md"

# Generate breaking changes examples
echo "⚠️  Extracting breaking change examples..."
echo "## Breaking Change Examples" > "$EXAMPLES_DIR/breaking-changes.md"
echo "" >> "$EXAMPLES_DIR/breaking-changes.md"

# Find removed public APIs
git diff $BASE_BRANCH..$TARGET_BRANCH -- src/ | \
    grep "^-.*public" | \
    head -10 >> "$EXAMPLES_DIR/breaking-changes.md" 2>/dev/null || \
    echo "No breaking changes detected" >> "$EXAMPLES_DIR/breaking-changes.md"

echo "" >> "$EXAMPLES_DIR/breaking-changes.md"
echo "### New APIs" >> "$EXAMPLES_DIR/breaking-changes.md"

# Find new public APIs
git diff $BASE_BRANCH..$TARGET_BRANCH -- src/ | \
    grep "^+.*public" | \
    head -10 >> "$EXAMPLES_DIR/breaking-changes.md" 2>/dev/null || \
    echo "No new public APIs detected" >> "$EXAMPLES_DIR/breaking-changes.md"

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
