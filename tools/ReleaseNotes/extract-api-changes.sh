#!/bin/bash

# Extract new APIs by building reference assemblies and comparing git diffs
# This approach focuses on actual API surface changes rather than usage examples
# Usage: ./extract-api-changes.sh <base_branch> <target_branch>

set -e

BASE_BRANCH=${1:-origin/release/9.3}
TARGET_BRANCH=${2:-origin/release/9.4}

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYSIS_DIR="$TOOLS_DIR/analysis-output"
API_CHANGES_DIR="$ANALYSIS_DIR/api-changes"

echo "🔧 Extracting API changes using reference assembly generation"
echo "📊 Analyzing: $BASE_BRANCH -> $TARGET_BRANCH"
echo "⏱️  This may take several minutes depending on the number of projects..."

# Start total timing
SCRIPT_START_TIME=$(date +%s)

mkdir -p "$API_CHANGES_DIR"

# Get git root
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

# Function to build reference assembly for a project
build_reference_assembly() {
    local project_path="$1"
    local project_name=$(basename "$project_path" .csproj)
    local output_dir="$2"
    
    echo "    🔨 Building reference assembly for: $project_name"
    
    # Create output directory for this project
    mkdir -p "$output_dir/$project_name"
    
    # Build the project with reference assembly generation
    # Suppress most output but capture errors
    if dotnet build "$project_path" -f net8.0 -c Release --no-incremental /t:"Build;GenAPIGenerateReferenceAssemblySource" --verbosity quiet > "$output_dir/$project_name/build.log" 2>&1; then
        echo "    ✅ Successfully built: $project_name"
        return 0
    else
        echo "    ⚠️  Build failed for: $project_name (see build.log)"
        return 1
    fi
}

# Function to find and extract reference assembly source files
extract_reference_assembly_source() {
    local project_path="$1"
    local project_name=$(basename "$project_path" .csproj)
    local output_dir="$2"
    
    # Look for generated reference assembly source files
    # These are typically in obj/Release/net8.0/ref/ or similar paths
    local project_dir=$(dirname "$project_path")
    local ref_files=$(find "$project_dir" -name "*.cs" -path "*/obj/Release/*/ref/*" 2>/dev/null || true)
    
    if [ -n "$ref_files" ]; then
        echo "    📄 Found reference assembly source for: $project_name"
        # Copy the reference assembly source file
        for ref_file in $ref_files; do
            local filename=$(basename "$ref_file")
            cp "$ref_file" "$output_dir/$project_name/$filename" 2>/dev/null || true
        done
        return 0
    else
        echo "    ⚠️  No reference assembly source found for: $project_name"
        return 1
    fi
}

# Function to get all Aspire projects that should have APIs
get_aspire_projects() {
    # Find all .csproj files in src/ that are likely to contain public APIs
    # Focus on main Aspire libraries that have public APIs
    find src -name "*.csproj" | grep -E "(Aspire\.(Hosting|Dashboard|Cli|AppHost|ProjectTemplates))" | grep -v -E "(\.Tests\.|\.Test\.)" | head -15
}

# Function to extract API changes for all projects
extract_api_changes() {
    local start_time=$(date +%s)
    
    echo "🏗️  PHASE 1: Building reference assemblies on target branch"
    
    # Switch to target branch
    echo "    🔄 Switching to target branch: $TARGET_BRANCH"
    git checkout "$TARGET_BRANCH" --quiet
    
    # Create temp directory for target branch APIs
    local target_apis_dir=$(mktemp -d)
    echo "    📁 Target APIs directory: $target_apis_dir"
    
    # Get list of projects
    local projects=($(get_aspire_projects))
    local project_count=0
    local total_projects=${#projects[@]}
    
    echo "    📦 Processing $total_projects projects on target branch..."
    
    # Build each project and extract reference assemblies
    for project in "${projects[@]}"; do
        ((project_count++))
        echo "  🔨 [$project_count/$total_projects] Processing: $(basename "$project" .csproj)"
        
        if build_reference_assembly "$project" "$target_apis_dir"; then
            extract_reference_assembly_source "$project" "$target_apis_dir"
        fi
    done
    
    echo "🏗️  PHASE 2: Building reference assemblies on base branch"
    
    # Switch to base branch
    echo "    🔄 Switching to base branch: $BASE_BRANCH"
    git checkout "$BASE_BRANCH" --quiet
    
    # Create temp directory for base branch APIs
    local base_apis_dir=$(mktemp -d)
    echo "    📁 Base APIs directory: $base_apis_dir"
    
    project_count=0
    echo "    📦 Processing $total_projects projects on base branch..."
    
    # Build each project and extract reference assemblies
    for project in "${projects[@]}"; do
        ((project_count++))
        echo "  🔨 [$project_count/$total_projects] Processing: $(basename "$project" .csproj)"
        
        if build_reference_assembly "$project" "$base_apis_dir"; then
            extract_reference_assembly_source "$project" "$base_apis_dir"
        fi
    done
    
    echo "🔍 PHASE 3: Comparing API changes"
    
    # Compare the APIs and generate diff reports
    local comparison_file="$API_CHANGES_DIR/api-changes-summary.md"
    
    cat > "$comparison_file" << EOF
# API Changes Summary

Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH

## Overview

This document contains API surface changes detected by comparing reference assemblies
between the base and target branches.

## Methodology

1. Build each Aspire project with reference assembly generation
2. Extract generated reference assembly source files (.cs)
3. Compare the API surfaces using git diff

EOF
    
    # Compare each project's APIs
    echo "    📊 Generating API comparison reports..."
    local changes_found=false
    
    for project in "${projects[@]}"; do
        local project_name=$(basename "$project" .csproj)
        echo "    🔍 Comparing APIs for: $project_name"
        
        local base_ref_files="$base_apis_dir/$project_name"
        local target_ref_files="$target_apis_dir/$project_name"
        
        if [ -d "$base_ref_files" ] && [ -d "$target_ref_files" ]; then
            # Find corresponding reference assembly files
            local base_files=$(find "$base_ref_files" -name "*.cs" 2>/dev/null || true)
            local target_files=$(find "$target_ref_files" -name "*.cs" 2>/dev/null || true)
            
            if [ -n "$base_files" ] && [ -n "$target_files" ]; then
                # Compare the files
                local project_changes_file="$API_CHANGES_DIR/$project_name-api-changes.md"
                
                echo "### $project_name API Changes" >> "$comparison_file"
                echo "" >> "$comparison_file"
                
                # Create detailed comparison for this project
                echo "# $project_name API Changes" > "$project_changes_file"
                echo "" >> "$project_changes_file"
                echo "Generated from: $BASE_BRANCH -> $TARGET_BRANCH" >> "$project_changes_file"
                echo "" >> "$project_changes_file"
                
                # For each target file, compare with base
                for target_file in $target_files; do
                    local filename=$(basename "$target_file")
                    local base_file="$base_ref_files/$filename"
                    
                    if [ -f "$base_file" ]; then
                        # Files exist in both, show diff
                        local diff_output=$(diff -u "$base_file" "$target_file" 2>/dev/null || true)
                        if [ -n "$diff_output" ]; then
                            echo "## Changes in $filename" >> "$project_changes_file"
                            echo "" >> "$project_changes_file"
                            echo '```diff' >> "$project_changes_file"
                            echo "$diff_output" >> "$project_changes_file"
                            echo '```' >> "$project_changes_file"
                            echo "" >> "$project_changes_file"
                            changes_found=true
                            
                            # Add summary to main file
                            echo "- **$filename**: API changes detected" >> "$comparison_file"
                        fi
                    else
                        # New file in target
                        echo "## New API File: $filename" >> "$project_changes_file"
                        echo "" >> "$project_changes_file"
                        echo '```csharp' >> "$project_changes_file"
                        cat "$target_file" >> "$project_changes_file"
                        echo '```' >> "$project_changes_file"
                        echo "" >> "$project_changes_file"
                        changes_found=true
                        
                        # Add summary to main file
                        echo "- **$filename**: New API file" >> "$comparison_file"
                    fi
                done
                
                # Check for removed files
                for base_file in $base_files; do
                    local filename=$(basename "$base_file")
                    local target_file="$target_ref_files/$filename"
                    
                    if [ ! -f "$target_file" ]; then
                        echo "## Removed API File: $filename" >> "$project_changes_file"
                        echo "" >> "$project_changes_file"
                        echo "This API file was removed in the target branch." >> "$project_changes_file"
                        echo "" >> "$project_changes_file"
                        changes_found=true
                        
                        # Add summary to main file
                        echo "- **$filename**: API file removed" >> "$comparison_file"
                    fi
                done
                
                echo "" >> "$comparison_file"
            else
                echo "- No reference assemblies found for comparison" >> "$comparison_file"
                echo "" >> "$comparison_file"
            fi
        else
            echo "- Could not build reference assemblies for comparison" >> "$comparison_file"
            echo "" >> "$comparison_file"
        fi
    done
    
    if [ "$changes_found" = false ]; then
        echo "" >> "$comparison_file"
        echo "## No API Changes Detected" >> "$comparison_file"
        echo "" >> "$comparison_file"
        echo "No significant API surface changes were detected between the two branches." >> "$comparison_file"
        echo "This could mean:" >> "$comparison_file"
        echo "- No public API changes were made" >> "$comparison_file"
        echo "- Changes are internal/private only" >> "$comparison_file"
        echo "- Reference assembly generation failed" >> "$comparison_file"
    fi
    
    # Clean up temp directories
    rm -rf "$target_apis_dir" "$base_apis_dir"
    
    # Switch back to target branch
    git checkout "$TARGET_BRANCH" --quiet
    
    local end_time=$(date +%s)
    echo "    ✅ API changes extraction completed in $((end_time - start_time))s"
}

# Function to generate alternative API analysis using source diffs
extract_source_api_changes() {
    local start_time=$(date +%s)
    local output_file="$API_CHANGES_DIR/source-api-changes.md"
    
    echo "🔍 PHASE 4: Analyzing source code API changes (fallback method)"
    
    cat > "$output_file" << EOF
# Source Code API Changes

Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH

This analysis looks at source code changes in API-related files as a fallback
when reference assembly generation is not available.

## Public API Pattern Changes

EOF
    
    # Look for changes in files that likely contain public APIs
    echo "    🔍 Searching for API-related source changes..."
    
    # Find changes in .cs files that likely contain public APIs
    local api_files=$(git diff --name-only $BASE_BRANCH..$TARGET_BRANCH -- 'src/**/*.cs' | grep -v -E "(\.Tests\.|\.Test\.|test|Test)" | head -20)
    
    if [ -n "$api_files" ]; then
        echo "    📄 Found $(echo "$api_files" | wc -l) potentially API-related files"
        
        for file in $api_files; do
            echo "    🔍 Analyzing: $file"
            
            # Look for public API changes in this file
            local public_changes=$(git diff $BASE_BRANCH..$TARGET_BRANCH -- "$file" | grep -E "^\+.*public " | head -10)
            
            if [ -n "$public_changes" ]; then
                echo "### $(basename "$file")" >> "$output_file"
                echo "" >> "$output_file"
                echo "File: \`$file\`" >> "$output_file"
                echo "" >> "$output_file"
                echo '```diff' >> "$output_file"
                git diff $BASE_BRANCH..$TARGET_BRANCH -- "$file" | grep -A2 -B2 -E "^\+.*public " | head -20 >> "$output_file"
                echo '```' >> "$output_file"
                echo "" >> "$output_file"
            fi
        done
    else
        echo "    ℹ️  No API-related source files found"
        echo "No API-related source file changes detected." >> "$output_file"
    fi
    
    local end_time=$(date +%s)
    echo "    ✅ Source API analysis completed in $((end_time - start_time))s"
}

# Main execution
echo ""
echo "🚀 Starting API changes extraction..."

# Extract API changes using reference assemblies
extract_api_changes

# Also generate source-based analysis as fallback
extract_source_api_changes

# Generate consolidated report
echo ""
echo "📋 PHASE 5: Generating consolidated API changes report..."
PHASE5_START=$(date +%s)

consolidated_file="$API_CHANGES_DIR/all-api-changes.md"

cat > "$consolidated_file" << EOF
# Complete API Changes Analysis

Generated from analysis of: $BASE_BRANCH -> $TARGET_BRANCH

## 🎯 Overview

This document contains API surface changes detected using multiple analysis methods:

1. **Reference Assembly Comparison**: Compares generated reference assemblies
2. **Source Code Analysis**: Analyzes public API patterns in source code

## 📊 Analysis Methods

### Method 1: Reference Assembly Generation
- Build projects with: \`dotnet build -f net8.0 -c Release --no-incremental /t:"Build;GenAPIGenerateReferenceAssemblySource"\`
- Compare generated reference assembly source files
- Most accurate for detecting API surface changes

### Method 2: Source Code Pattern Analysis
- Analyze git diffs in source files
- Look for public API additions/changes
- Fallback method when reference assembly generation fails

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

PHASE5_END=$(date +%s)
echo "✅ Phase 5 completed in $((PHASE5_END - PHASE5_START))s"

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
echo "   2. Use the detected changes to update release notes"
echo "   3. Focus on public API additions and breaking changes"
