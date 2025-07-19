#!/bin/bash

# Extract meaningful API usage examples from playground and test changes
# Filters out test infrastructure noise and focuses on user-facing API changes
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

# Extract all playground examples globally with API pattern filtering
extract_all_playground_examples() {
    local output_file="$EXAMPLES_DIR/all-playground-examples.md"
    
    # Change to git root for git commands
    GIT_ROOT=$(git rev-parse --show-toplevel)
    cd "$GIT_ROOT"
    
    echo "# Meaningful API Examples from Playgrounds" > "$output_file"
    echo "" >> "$output_file"
    echo "Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH" >> "$output_file"
    echo "" >> "$output_file"
    
    # Find new playground files with API significance
    echo "## 🆕 New Features (New Playground Files)" >> "$output_file"
    new_playground_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- playground/ | grep "^A" | cut -f2)
    if [ -n "$new_playground_files" ]; then
        for file in $new_playground_files; do
            if [[ "$file" == *.cs ]]; then
                # Check if file contains meaningful API patterns
                if git show $TARGET_BRANCH:"$file" 2>/dev/null | grep -qE '\.(Add[A-Z]|With[A-Z]|Run[A-Z])' ; then
                    echo "### 🎯 $file" >> "$output_file"
                    echo "\`\`\`csharp" >> "$output_file"
                    # Extract only lines with API calls (Add*, With*, Run*, etc.)
                    git show $TARGET_BRANCH:"$file" 2>/dev/null | grep -E "(var [a-zA-Z]+ = |\.Add[A-Z]|\.With[A-Z]|\.Run[A-Z]|builder\.)" | head -20 >> "$output_file"
                    echo "\`\`\`" >> "$output_file"
                    echo "" >> "$output_file"
                fi
            fi
        done
    else
        echo "No new playground files with meaningful APIs found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Show meaningful changes in existing playground files
    echo "## 🔄 Enhanced Features (Modified Playground Files)" >> "$output_file"
    modified_playground_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- playground/ | grep "^M" | cut -f2)
    if [ -n "$modified_playground_files" ]; then
        for file in $modified_playground_files; do
            if [[ "$file" == *.cs ]]; then
                # Only show files with meaningful API additions (not just imports)
                meaningful_changes=$(git diff $BASE_BRANCH..$TARGET_BRANCH -- "$file" 2>/dev/null | grep "^+" | grep -E '\.(Add[A-Z]|With[A-Z]|Run[A-Z])' || true)
                if [ -n "$meaningful_changes" ]; then
                    echo "### 🔧 $file" >> "$output_file"
                    echo "\`\`\`diff" >> "$output_file"
                    git diff $BASE_BRANCH..$TARGET_BRANCH -- "$file" 2>/dev/null | grep -A2 -B2 -E '\.(Add[A-Z]|With[A-Z]|Run[A-Z])' || echo "# No specific API patterns found in diff" >> "$output_file"
                    echo "\`\`\`" >> "$output_file"
                    echo "" >> "$output_file"
                fi
            fi
        done
    else
        echo "No modified playground files with meaningful API changes found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Return to original directory
    cd "$TOOLS_DIR"
}

# Extract meaningful test examples that show new APIs (filter out noise)
extract_all_test_examples() {
    local output_file="$EXAMPLES_DIR/all-test-examples.md"
    
    # Change to git root for git commands
    GIT_ROOT=$(git rev-parse --show-toplevel)
    cd "$GIT_ROOT"
    
    echo "# Meaningful API Examples from Tests" > "$output_file"
    echo "" >> "$output_file"
    echo "Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH" >> "$output_file"
    echo "" >> "$output_file"
    echo "> **Note**: Filters out test infrastructure changes and focuses on user-facing API examples" >> "$output_file"
    echo "" >> "$output_file"
    
    # Define noise patterns to exclude
    local noise_patterns="Components\.Common\.Tests|Components\.Common\.TestUtilities|TestSdk\.|TestTargetFramework\.|BuildEnvironment\.|PlatformDetection\.|RequiresDocker|RequiresSSL|ActiveIssue|AsyncTestHelpers|TestModuleInitializer|VerifyExtensions"
    
    # Find new test files with actual API usage (not just test infrastructure)
    echo "## 🧪 New API Test Examples" >> "$output_file"
    new_test_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- tests/ | grep "^A" | cut -f2)
    api_test_count=0
    if [ -n "$new_test_files" ]; then
        for file in $new_test_files; do
            if [[ "$file" == *.cs ]] && ! echo "$file" | grep -qE "$noise_patterns"; then
                # Check if file contains meaningful API patterns
                if git show $TARGET_BRANCH:"$file" 2>/dev/null | grep -qE '\.(Add[A-Z]|With[A-Z]|\.Test.*Add)' ; then
                    echo "### 🆕 $file" >> "$output_file"
                    echo "\`\`\`csharp" >> "$output_file"
                    # Extract test methods that show API usage
                    git show $TARGET_BRANCH:"$file" 2>/dev/null | grep -A5 -B1 -E "(public.*Test|Add[A-Z][a-zA-Z]*)" | head -30 >> "$output_file"
                    echo "\`\`\`" >> "$output_file"
                    echo "" >> "$output_file"
                    ((api_test_count++))
                fi
            fi
        done
    fi
    if [ $api_test_count -eq 0 ]; then
        echo "No new test files with meaningful API examples found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Show meaningful API changes in existing test files (avoid noise)
    echo "## 🔬 Updated API Test Examples" >> "$output_file"
    modified_test_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- tests/ | grep "^M" | cut -f2)
    meaningful_test_count=0
    if [ -n "$modified_test_files" ]; then
        for file in $modified_test_files; do
            if [[ "$file" == *.cs ]]; then
                # Check for meaningful API additions, not just namespace/import changes
                meaningful_changes=$(git diff $BASE_BRANCH..$TARGET_BRANCH -- "$file" 2>/dev/null | grep "^+" | grep -v -E "$noise_patterns" | grep -E '\.(Add[A-Z]|With[A-Z]|\..*Client|\..*Service)' || true)
                if [ -n "$meaningful_changes" ] && [ $(echo "$meaningful_changes" | wc -l) -ge 1 ]; then
                    echo "### 🔧 $file" >> "$output_file"
                    echo "\`\`\`diff" >> "$output_file"
                    # Show only the meaningful changes, not the whole diff
                    git diff $BASE_BRANCH..$TARGET_BRANCH -- "$file" 2>/dev/null | grep -A3 -B3 -E '\.(Add[A-Z]|With[A-Z]|\..*Client|\..*Service)' | head -20 || echo "# No specific patterns found" >> "$output_file"
                    echo "\`\`\`" >> "$output_file"
                    echo "" >> "$output_file"
                    ((meaningful_test_count++))
                fi
            fi
        done
    fi
    if [ $meaningful_test_count -eq 0 ]; then
        echo "No modified test files with meaningful API changes found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Return to original directory
    cd "$TOOLS_DIR"
}

# Extract API patterns summary for quick overview and delegate complex analysis to AI
extract_api_patterns_summary() {
    local output_file="$EXAMPLES_DIR/api-patterns-summary.md"
    
    # Change to git root for git commands
    GIT_ROOT=$(git rev-parse --show-toplevel)
    cd "$GIT_ROOT"
    
    echo "# API Patterns Summary" > "$output_file"
    echo "" >> "$output_file"
    echo "Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH" >> "$output_file"
    echo "" >> "$output_file"
    
    echo "## 🆕 New API Patterns Detected" >> "$output_file"
    echo "" >> "$output_file"
    
    # Search for new API patterns in all C# files
    api_patterns=$(git diff $BASE_BRANCH..$TARGET_BRANCH -- '*.cs' | grep "^+" | grep -oE 'Add[A-Z][a-zA-Z]*|With[A-Z][a-zA-Z]*|Run[A-Z][a-zA-Z]*' | sort | uniq || true)
    
    if [ -n "$api_patterns" ]; then
        for pattern in $api_patterns; do
            # Find examples of this pattern
            examples=$(git diff $BASE_BRANCH..$TARGET_BRANCH -- '*.cs' | grep "^+" | grep "$pattern" | head -3 | sed 's/^+//')
            if [ -n "$examples" ]; then
                echo "### \`$pattern\`" >> "$output_file"
                echo "\`\`\`csharp" >> "$output_file"
                echo "$examples" >> "$output_file"
                echo "\`\`\`" >> "$output_file"
                echo "" >> "$output_file"
            fi
        done
    else
        echo "No new API patterns detected" >> "$output_file"
    fi
    
    echo "" >> "$output_file"
    echo "## 🔍 New Integration Keywords" >> "$output_file"
    echo "" >> "$output_file"
    
    # Look for new integration keywords
    integration_keywords=$(git diff $BASE_BRANCH..$TARGET_BRANCH -- playground/ tests/ | grep "^+" | grep -oE 'Azure[A-Z][a-zA-Z]*|GitHub[A-Z][a-zA-Z]*|External[A-Z][a-zA-Z]*|Chat[A-Z][a-zA-Z]*|AI[A-Z][a-zA-Z]*' | sort | uniq)
    
    if [ -n "$integration_keywords" ]; then
        for keyword in $integration_keywords; do
            echo "- **$keyword**" >> "$output_file"
        done
    else
        echo "No new integration keywords detected" >> "$output_file"
    fi
    
    echo "" >> "$output_file"
    echo "## 🤖 AI Agent Analysis Required" >> "$output_file"
    echo "" >> "$output_file"
    echo "> **Note**: The following tasks require AI agent analysis as they cannot be reliably automated:" >> "$output_file"
    echo "" >> "$output_file"
    echo "1. **Feature Impact Assessment**: Determine which API changes represent major new features vs. minor enhancements" >> "$output_file"
    echo "2. **Developer Benefit Analysis**: Transform technical changes into compelling user benefits" >> "$output_file"
    echo "3. **Code Example Curation**: Select the most representative and educational examples from playground/test files" >> "$output_file"
    echo "4. **Breaking Change Detection**: Identify actual breaking changes vs. internal refactoring" >> "$output_file"
    echo "5. **Section Categorization**: Assign features to appropriate release notes sections (App Model, Dashboard, CLI, etc.)" >> "$output_file"
    echo "6. **Documentation Quality**: Transform raw examples into polished, production-ready documentation" >> "$output_file"
    echo "" >> "$output_file"
    echo "**Process**: Use the extracted data as input for AI agent processing following \`agent-instructions.md\`" >> "$output_file"
    
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
echo "📋 Generating meaningful playground examples..."
extract_all_playground_examples

echo "📋 Generating meaningful test examples..."
extract_all_test_examples

echo "📋 Generating API patterns summary..."
extract_api_patterns_summary

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

# Generate consolidated examples file with signal-to-noise filtering
echo "📋 Generating consolidated examples with API focus..."
consolidated_file="$EXAMPLES_DIR/all-api-examples.md"

cat > "$consolidated_file" << EOF
# Meaningful API Usage Examples

Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH

## 🎯 Overview

This document contains **user-facing API examples** extracted from playground applications and tests.
**Filtered out**: Test infrastructure changes, namespace refactoring, and internal utilities.

## 📊 Signal vs Noise Analysis

Based on the extracted examples, this focuses on:
- ✅ New hosting APIs (Add*, With*, Run*)
- ✅ New client integration patterns
- ✅ Enhanced configuration options
- ✅ New service discovery features
- ❌ Test infrastructure changes (TestSdk, TestUtilities, etc.)
- ❌ Namespace reorganization
- ❌ Internal test helpers

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
