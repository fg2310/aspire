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
echo "⏱️  This may take a few minutes depending on the number of changes..."

# Start total timing
SCRIPT_START_TIME=$(date +%s)

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
    local start_time=$(date +%s)
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
    echo "    🔍 Scanning for new playground files..."
    local scan_start=$(date +%s)
    new_playground_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- playground/ | grep "^A" | cut -f2)
    local scan_end=$(date +%s)
    echo "    ⏱️  Scan completed in $((scan_end - scan_start))s"
    if [ -n "$new_playground_files" ]; then
        file_count=0
        total_files=$(echo "$new_playground_files" | wc -l)
        echo "    📁 Processing $total_files new playground files..."
        for file in $new_playground_files; do
            ((file_count++))
            echo "    📝 Analyzing file $file_count/$total_files: $(basename "$file")"
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
        echo "    ℹ️  No new playground files found"
        echo "No new playground files with meaningful APIs found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Show meaningful changes in existing playground files
    echo "## 🔄 Enhanced Features (Modified Playground Files)" >> "$output_file"
    echo "    🔍 Scanning for modified playground files..."
    local modified_scan_start=$(date +%s)
    modified_playground_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- playground/ | grep "^M" | cut -f2)
    local modified_scan_end=$(date +%s)
    echo "    ⏱️  Modified files scan completed in $((modified_scan_end - modified_scan_start))s"
    if [ -n "$modified_playground_files" ]; then
        modified_count=0
        total_modified=$(echo "$modified_playground_files" | wc -l)
        echo "    📁 Processing $total_modified modified playground files..."
        for file in $modified_playground_files; do
            ((modified_count++))
            echo "    🔧 Analyzing changes $modified_count/$total_modified: $(basename "$file")"
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
        echo "    ℹ️  No modified playground files found"
        echo "No modified playground files with meaningful API changes found" >> "$output_file"
    fi
    echo "" >> "$output_file"
    
    # Return to original directory
    cd "$TOOLS_DIR"
    
    local end_time=$(date +%s)
    echo "    ✅ Playground analysis completed in $((end_time - start_time))s"
}

# Extract meaningful test examples that show new APIs (filter out noise)
extract_all_test_examples() {
    local start_time=$(date +%s)
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
    echo "    🔍 Scanning for new test files..."
    local test_scan_start=$(date +%s)
    new_test_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- tests/ | grep "^A" | cut -f2)
    local test_scan_end=$(date +%s)
    echo "    ⏱️  New test files scan completed in $((test_scan_end - test_scan_start))s"
    api_test_count=0
    if [ -n "$new_test_files" ]; then
        test_file_count=0
        total_test_files=$(echo "$new_test_files" | wc -l)
        echo "    📁 Processing $total_test_files new test files..."
        for file in $new_test_files; do
            ((test_file_count++))
            echo "    🧪 Analyzing test $test_file_count/$total_test_files: $(basename "$file")"
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
        echo "    ℹ️  No meaningful API test examples found"
        echo "No new test files with meaningful API examples found" >> "$output_file"
    else
        echo "    ✅ Found $api_test_count meaningful API test examples"
    fi
    echo "" >> "$output_file"
    
    # Show meaningful API changes in existing test files (avoid noise)
    echo "## 🔬 Updated API Test Examples" >> "$output_file"
    echo "    🔍 Scanning for modified test files..."
    local modified_test_scan_start=$(date +%s)
    modified_test_files=$(git diff --name-status $BASE_BRANCH..$TARGET_BRANCH -- tests/ | grep "^M" | cut -f2)
    local modified_test_scan_end=$(date +%s)
    echo "    ⏱️  Modified test files scan completed in $((modified_test_scan_end - modified_test_scan_start))s"
    meaningful_test_count=0
    if [ -n "$modified_test_files" ]; then
        modified_test_count=0
        total_modified_tests=$(echo "$modified_test_files" | wc -l)
        echo "    📁 Processing $total_modified_tests modified test files..."
        for file in $modified_test_files; do
            ((modified_test_count++))
            echo "    🔬 Analyzing test changes $modified_test_count/$total_modified_tests: $(basename "$file")"
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
        echo "    ℹ️  No meaningful API test changes found"
        echo "No modified test files with meaningful API changes found" >> "$output_file"
    else
        echo "    ✅ Found $meaningful_test_count meaningful API test changes"
    fi
    echo "" >> "$output_file"
    
    # Return to original directory
    cd "$TOOLS_DIR"
    
    local end_time=$(date +%s)
    echo "    ✅ Test analysis completed in $((end_time - start_time))s"
}

# Extract API patterns summary for quick overview and delegate complex analysis to AI
extract_api_patterns_summary() {
    local start_time=$(date +%s)
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
    
    echo "    🔍 Analyzing git diff for API patterns..."
    local patterns_start=$(date +%s)
    # Search for new API patterns in all C# files
    api_patterns=$(git diff $BASE_BRANCH..$TARGET_BRANCH -- '*.cs' | grep "^+" | grep -oE 'Add[A-Z][a-zA-Z]*|With[A-Z][a-zA-Z]*|Run[A-Z][a-zA-Z]*' | sort | uniq || true)
    local patterns_end=$(date +%s)
    echo "    ⏱️  API pattern detection completed in $((patterns_end - patterns_start))s"
    
    if [ -n "$api_patterns" ]; then
        echo "    📝 Found $(echo "$api_patterns" | wc -l) unique API patterns"
        pattern_count=0
        total_patterns=$(echo "$api_patterns" | wc -l)
        for pattern in $api_patterns; do
            ((pattern_count++))
            echo "    🔧 Processing pattern $pattern_count/$total_patterns: $pattern"
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
        echo "    ℹ️  No new API patterns detected"
        echo "No new API patterns detected" >> "$output_file"
    fi
    
    echo "" >> "$output_file"
    echo "## 🔍 New Integration Keywords" >> "$output_file"
    echo "" >> "$output_file"
    
    echo "    🔍 Searching for integration keywords..."
    local keywords_start=$(date +%s)
    # Look for new integration keywords
    integration_keywords=$(git diff $BASE_BRANCH..$TARGET_BRANCH -- playground/ tests/ | grep "^+" | grep -oE 'Azure[A-Z][a-zA-Z]*|GitHub[A-Z][a-zA-Z]*|External[A-Z][a-zA-Z]*|Chat[A-Z][a-zA-Z]*|AI[A-Z][a-zA-Z]*' | sort | uniq)
    local keywords_end=$(date +%s)
    echo "    ⏱️  Integration keywords search completed in $((keywords_end - keywords_start))s"
    
    if [ -n "$integration_keywords" ]; then
        echo "    📋 Found $(echo "$integration_keywords" | wc -l) integration keywords"
        for keyword in $integration_keywords; do
            echo "- **$keyword**" >> "$output_file"
        done
    else
        echo "    ℹ️  No new integration keywords detected"
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
    
    local end_time=$(date +%s)
    echo "    ✅ API patterns summary completed in $((end_time - start_time))s"
}

# Extract examples from major components
echo ""
echo "🎯 PHASE 1: Extracting API examples from major components..."
PHASE1_START=$(date +%s)

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
total_components=${#COMPONENTS[@]}
if [ $total_components -gt 10 ]; then
    total_components=10
fi

echo "📝 Processing $total_components components for API extraction..."
for component in "${COMPONENTS[@]}"; do
    if [ $component_count -ge 10 ]; then
        echo "  📝 (Limited to first 10 components for API extraction)"
        break
    fi
    ((component_count++))
    echo "  📝 [$component_count/$total_components] Extracting usage examples for: $component"
    component_name=$(basename "$component" | sed 's|/||g')
    output_file="$EXAMPLES_DIR/$component_name-usage-examples.md"
    extract_usage_examples "$component" "$output_file"
done

PHASE1_END=$(date +%s)
echo "✅ Phase 1 completed in $((PHASE1_END - PHASE1_START))s"

# Extract global playground and test examples
echo ""
echo "🎮 PHASE 2: Generating meaningful playground examples..."
PHASE2_START=$(date +%s)
extract_all_playground_examples
PHASE2_END=$(date +%s)
echo "✅ Phase 2 completed in $((PHASE2_END - PHASE2_START))s"

echo ""
echo "🧪 PHASE 3: Generating meaningful test examples..."
PHASE3_START=$(date +%s)
extract_all_test_examples
PHASE3_END=$(date +%s)
echo "✅ Phase 3 completed in $((PHASE3_END - PHASE3_START))s"

echo ""
echo "🔍 PHASE 4: Generating API patterns summary..."
PHASE4_START=$(date +%s)
extract_api_patterns_summary
PHASE4_END=$(date +%s)
echo "✅ Phase 4 completed in $((PHASE4_END - PHASE4_START))s"

# Generate general usage examples overview
echo ""
echo "📋 PHASE 5: Generating general usage examples overview..."
PHASE5_START=$(date +%s)

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

PHASE5_END=$(date +%s)
echo "✅ Phase 5 completed in $((PHASE5_END - PHASE5_START))s"

# Generate consolidated examples file with signal-to-noise filtering
echo ""
echo "📋 PHASE 6: Generating consolidated examples with API focus..."
PHASE6_START=$(date +%s)
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

# Count and add each example file
example_files=("$EXAMPLES_DIR"/*.md)
file_count=0
total_example_files=0

# Count files first (excluding the consolidated file itself)
for example_file in "${example_files[@]}"; do
    if [ -f "$example_file" ] && [ "$example_file" != "$consolidated_file" ]; then
        ((total_example_files++))
    fi
done

echo "    📂 Consolidating $total_example_files example files..."

# Add each example file
for example_file in "${example_files[@]}"; do
    if [ -f "$example_file" ] && [ "$example_file" != "$consolidated_file" ]; then
        ((file_count++))
        echo "    📄 [$file_count/$total_example_files] Adding $(basename "$example_file")"
        echo "" >> "$consolidated_file"
        echo "---" >> "$consolidated_file"
        echo "" >> "$consolidated_file"
        cat "$example_file" >> "$consolidated_file"
    fi
done

PHASE6_END=$(date +%s)
echo "✅ Phase 6 completed in $((PHASE6_END - PHASE6_START))s"

# Calculate total time
SCRIPT_END_TIME=$(date +%s)
TOTAL_TIME=$((SCRIPT_END_TIME - SCRIPT_START_TIME))

echo ""
echo "✅ API examples extraction complete!"
echo "⏱️  Total execution time: ${TOTAL_TIME}s"
echo ""
echo "📊 Phase Timing Summary:"
echo "   Phase 1 (Components): $((PHASE1_END - PHASE1_START))s"
echo "   Phase 2 (Playground): $((PHASE2_END - PHASE2_START))s"
echo "   Phase 3 (Tests): $((PHASE3_END - PHASE3_START))s"
echo "   Phase 4 (API Patterns): $((PHASE4_END - PHASE4_START))s"
echo "   Phase 5 (Overview): $((PHASE5_END - PHASE5_START))s"
echo "   Phase 6 (Consolidation): $((PHASE6_END - PHASE6_START))s"
echo ""
echo "📁 Examples directory: $EXAMPLES_DIR/"
echo "📄 Consolidated examples: $consolidated_file"
echo ""
echo "📋 Generated files:"
ls -1 "$EXAMPLES_DIR"/*.md | sed 's/^/   /'
