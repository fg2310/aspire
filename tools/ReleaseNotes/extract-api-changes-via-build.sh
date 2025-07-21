#!/bin/bash

# Extract API changes by building projects to update API files, then using git diff
# This approach builds each project to regenerate API files, then compares with git
# Usage: ./extract-api-changes-via-build.sh <base_branch> <target_branch>

set -e

BASE_BRANCH=${1:-origin/release/9.3}
TARGET_BRANCH=${2:-origin/release/9.4}

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYSIS_DIR="$TOOLS_DIR/analysis-output"
API_CHANGES_DIR="$ANALYSIS_DIR/api-changes-build"

echo "🔧 Extracting API changes via build + git diff"
echo "📊 Analyzing: $BASE_BRANCH -> $TARGET_BRANCH"
echo "⏱️  This may take several minutes depending on the number of projects..."

# Start total timing
SCRIPT_START_TIME=$(date +%s)

mkdir -p "$API_CHANGES_DIR"

# Get git root
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

# Function to get all projects with API directories
get_projects_with_apis() {
    # Find all directories with 'api' subdirectories
    find src -name "api" -type d | sed 's|/api$||' | while read -r project_dir; do
        # Look for corresponding .csproj file
        local csproj_file="$project_dir/$(basename "$project_dir").csproj"
        if [ -f "$csproj_file" ]; then
            echo "$csproj_file"
        fi
    done | head -15  # Limit to first 15 projects for initial testing
}

# Function to build a project and update its API files
build_and_update_api() {
    local project_path="$1"
    local project_name=$(basename "$project_path" .csproj)
    
    echo "    🔨 Building: $project_name"
    
    # Build the project - this should update the API files
    if dotnet build "$project_path" -f net8.0 -c Release --no-incremental --verbosity quiet > /dev/null 2>&1; then
        echo "    ✅ Built successfully: $project_name"
        return 0
    else
        echo "    ⚠️  Build failed: $project_name"
        return 1
    fi
}

# Function to extract API changes for target branch
extract_target_branch_changes() {
    local start_time=$(date +%s)
    
    echo "🏗️  PHASE 1: Building projects on target branch to update API files"
    
    # Make sure we're on the target branch
    echo "    🔄 Switching to target branch: $TARGET_BRANCH"
    git checkout "$TARGET_BRANCH" --quiet
    
    # Get list of projects with API directories
    local projects=($(get_projects_with_apis))
    local project_count=0
    local total_projects=${#projects[@]}
    local successful_builds=0
    
    echo "    📦 Found $total_projects projects with API directories"
    
    # Build each project to update API files
    for project in "${projects[@]}"; do
        ((project_count++))
        echo "  🔨 [$project_count/$total_projects] Processing: $(basename "$project" .csproj)"
        
        if build_and_update_api "$project"; then
            ((successful_builds++))
        fi
    done
    
    echo "    ✅ Successfully built $successful_builds/$total_projects projects"
    
    local end_time=$(date +%s)
    echo "    ⏱️  Phase 1 completed in $((end_time - start_time))s"
}

# Function to compare API changes
compare_api_changes() {
    local start_time=$(date +%s)
    
    echo "🔍 PHASE 2: Comparing API changes with base branch"
    
    # Create the main comparison file
    local comparison_file="$API_CHANGES_DIR/api-changes-summary.md"
    
    cat > "$comparison_file" << EOF
# API Changes Summary (Build Method)

Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH

## Overview

This document contains API surface changes detected by:
1. Building projects on target branch to update API files
2. Comparing API files with base branch using git diff

## Methodology

- Build each project with: \`dotnet build -f net8.0 -c Release --no-incremental\`
- This updates the existing API files in \`src/*/api/*.cs\`
- Compare the updated API files with the base branch

EOF
    
    # Get all API files that might have changed
    echo "    🔍 Finding API files to compare..."
    local api_files=$(find src -name "*.cs" -path "*/api/*" | head -50)
    local changes_found=false
    local files_with_changes=0
    local total_api_files=$(echo "$api_files" | wc -l)
    
    echo "    📄 Analyzing $total_api_files API files..."
    
    for api_file in $api_files; do
        echo "    🔍 Checking: $api_file"
        
        # Check if this file has changes compared to base branch
        local diff_output=$(git diff "$BASE_BRANCH" -- "$api_file" 2>/dev/null || true)
        
        if [ -n "$diff_output" ]; then
            ((files_with_changes++))
            changes_found=true
            
            # Extract component name from path
            local component_name=$(echo "$api_file" | sed 's|src/||' | sed 's|/api/.*||')
            
            echo "    ✅ Changes found in: $component_name"
            
            # Create detailed file for this component
            local component_file="$API_CHANGES_DIR/$component_name-api-changes.md"
            
            cat > "$component_file" << EOF
# $component_name API Changes

Generated from: $BASE_BRANCH -> $TARGET_BRANCH

## File: $api_file

\`\`\`diff
$diff_output
\`\`\`

## Summary

$(echo "$diff_output" | grep "^+" | grep -v "^+++" | wc -l) additions
$(echo "$diff_output" | grep "^-" | grep -v "^---" | wc -l) deletions
EOF
            
            # Add summary to main file
            echo "### $component_name" >> "$comparison_file"
            echo "" >> "$comparison_file"
            echo "**File**: \`$api_file\`" >> "$comparison_file"
            echo "" >> "$comparison_file"
            echo "- **Additions**: $(echo "$diff_output" | grep "^+" | grep -v "^+++" | wc -l) lines" >> "$comparison_file"
            echo "- **Deletions**: $(echo "$diff_output" | grep "^-" | grep -v "^---" | wc -l) lines" >> "$comparison_file"
            echo "" >> "$comparison_file"
            
            # Show a preview of key changes (new public APIs)
            local new_apis=$(echo "$diff_output" | grep "^+" | grep -E "public.*class|public.*interface|public.*enum|public.*struct|public.*delegate" | head -5)
            if [ -n "$new_apis" ]; then
                echo "**New Public Types**:" >> "$comparison_file"
                echo '```csharp' >> "$comparison_file"
                echo "$new_apis" | sed 's/^+//' >> "$comparison_file"
                echo '```' >> "$comparison_file"
                echo "" >> "$comparison_file"
            fi
            
            # Show new public methods/properties
            local new_members=$(echo "$diff_output" | grep "^+" | grep -E "public.*[A-Za-z]+.*\(" | head -5)
            if [ -n "$new_members" ]; then
                echo "**New Public Members**:" >> "$comparison_file"
                echo '```csharp' >> "$comparison_file"
                echo "$new_members" | sed 's/^+//' >> "$comparison_file"
                echo '```' >> "$comparison_file"
                echo "" >> "$comparison_file"
            fi
            
            echo "---" >> "$comparison_file"
            echo "" >> "$comparison_file"
        fi
    done
    
    if [ "$changes_found" = false ]; then
        echo "    ℹ️  No API changes detected"
        cat >> "$comparison_file" << EOF

## No API Changes Detected

No API surface changes were found between the base and target branches.

This could mean:
- No public API changes were made
- Changes are internal/private only  
- API files were not properly regenerated during build

**Troubleshooting**:
- Verify that the build process completed successfully
- Check if the API generation targets are working properly
- Look for changes in non-API files (implementation changes)
EOF
    else
        echo "    ✅ Found changes in $files_with_changes API files"
        cat >> "$comparison_file" << EOF

## Summary

**Total API Files Analyzed**: $total_api_files
**Files with Changes**: $files_with_changes

The above changes represent the public API surface differences between the two branches.
Review each component's detailed changes for specific API additions, modifications, or removals.
EOF
    fi
    
    local end_time=$(date +%s)
    echo "    ⏱️  Phase 2 completed in $((end_time - start_time))s"
}

# Function to generate git status report (what files were actually modified by the build)
generate_build_impact_report() {
    local start_time=$(date +%s)
    
    echo "📊 PHASE 3: Checking which files were modified by build process"
    
    local impact_file="$API_CHANGES_DIR/build-impact.md"
    
    cat > "$impact_file" << EOF
# Build Impact Report

This shows which files were actually modified by the build process on the target branch.

## Git Status After Build

EOF
    
    # Check git status to see what files were modified
    local modified_files=$(git status --porcelain | grep "^ M" | cut -c4- || true)
    
    if [ -n "$modified_files" ]; then
        echo "**Modified Files**:" >> "$impact_file"
        echo '```' >> "$impact_file"
        echo "$modified_files" >> "$impact_file"
        echo '```' >> "$impact_file"
        echo "" >> "$impact_file"
        
        # Focus on API files that were modified
        local modified_api_files=$(echo "$modified_files" | grep "/api/" || true)
        if [ -n "$modified_api_files" ]; then
            echo "**Modified API Files**:" >> "$impact_file"
            echo '```' >> "$impact_file"
            echo "$modified_api_files" >> "$impact_file"
            echo '```' >> "$impact_file"
            echo "" >> "$impact_file"
            
            echo "    ✅ Build process modified $(echo "$modified_api_files" | wc -l) API files"
        else
            echo "    ℹ️  No API files were modified by the build process"
        fi
    else
        echo "**No files were modified by the build process**" >> "$impact_file"
        echo "" >> "$impact_file"
        echo "This suggests either:" >> "$impact_file"
        echo "- The API files were already up to date" >> "$impact_file"
        echo "- The build process is not updating API files as expected" >> "$impact_file"
        echo "- All changes are contained within the commits already" >> "$impact_file"
        
        echo "    ℹ️  No files were modified by the build process"
    fi
    
    local end_time=$(date +%s)
    echo "    ⏱️  Phase 3 completed in $((end_time - start_time))s"
}

# Main execution
echo ""
echo "🚀 Starting API changes extraction via build method..."

# Extract and compare API changes
extract_target_branch_changes
compare_api_changes  
generate_build_impact_report

# Generate consolidated report
echo ""
echo "📋 PHASE 4: Generating consolidated report..."
PHASE4_START=$(date +%s)

consolidated_file="$API_CHANGES_DIR/consolidated-api-changes.md"

cat > "$consolidated_file" << EOF
# Consolidated API Changes Report

Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH

## 🎯 Methodology

This report uses the **Build + Git Diff** approach:

1. **Checkout target branch** ($TARGET_BRANCH)
2. **Build all projects** with API directories using: \`dotnet build -f net8.0 -c Release --no-incremental\`
3. **Compare API files** with base branch ($BASE_BRANCH) using \`git diff\`
4. **Extract meaningful changes** focusing on public API surface

## 📊 Analysis Results

EOF

# Add each analysis file
analysis_files=("$API_CHANGES_DIR"/*.md)
file_count=0
total_analysis_files=0

# Count files first (excluding the consolidated file itself)
for analysis_file in "${analysis_files[@]}"; do
    if [ -f "$analysis_file" ] && [ "$analysis_file" != "$consolidated_file" ]; then
        ((total_analysis_files++))
    fi
done

echo "    📂 Consolidating $total_analysis_files analysis files..."

# Add each analysis file
for analysis_file in "${analysis_files[@]}"; do
    if [ -f "$analysis_file" ] && [ "$analysis_file" != "$consolidated_file" ]; then
        ((file_count++))
        echo "    📄 [$file_count/$total_analysis_files] Adding $(basename "$analysis_file")"
        echo "" >> "$consolidated_file"
        echo "---" >> "$consolidated_file"
        echo "" >> "$consolidated_file"
        cat "$analysis_file" >> "$consolidated_file"
    fi
done

PHASE4_END=$(date +%s)
echo "✅ Phase 4 completed in $((PHASE4_END - PHASE4_START))s"

# Calculate total time
SCRIPT_END_TIME=$(date +%s)
TOTAL_TIME=$((SCRIPT_END_TIME - SCRIPT_START_TIME))

echo ""
echo "✅ API changes extraction complete!"
echo "⏱️  Total execution time: ${TOTAL_TIME}s"
echo ""
echo "📁 API changes directory: $API_CHANGES_DIR/"
echo "📄 Consolidated report: $consolidated_file"
echo ""
echo "📋 Generated files:"
ls -1 "$API_CHANGES_DIR"/*.md | sed 's/^/   /'
echo ""
echo "🔍 Next steps:"
echo "   1. Review the consolidated API changes report"
echo "   2. Focus on the specific component changes"
echo "   3. Identify new public APIs for release notes"
echo "   4. Check for any breaking changes"
