# LLM Prompt Templates for Release Notes Generation

This document contains the key prompt template for transforming automated analysis data into professional Aspire-style release notes.

## 🎯 Primary Synthesis Prompt

```
You are transforming .NET Aspire 9.4 analysis data into professional release notes that match the exact style of official Aspire 9.3 release notes.

INPUT DATA:
{comprehensive_analysis_markdown_file}

TASK:
Transform this raw analysis into polished, developer-focused release notes that match the official Aspire 9.3 style exactly.

OUTPUT STRUCTURE:
# .NET Aspire 9.4

{compelling_introduction_paragraph}

## 🖥️ App model enhancements

{hosting_and_core_platform_improvements}

## 📊 Dashboard delights  

{ui_ux_and_telemetry_improvements}

## 🚀 Deployment & publish

{publishing_docker_kubernetes_improvements}

## 🖥️ CLI enhancements

{command_line_tooling_improvements}

## ☁️ Azure goodies

{azure_specific_integrations_and_services}

## 🧩 Component integrations

{component_library_and_integration_updates}

## 💔 Breaking changes

{migration_guides_with_before_after_examples}

STYLE REQUIREMENTS:
1. **Voice & Tone**:
   - Use "Aspire now supports" not "Support has been added"
   - Write in active voice, present tense
   - Developer-focused: explain benefits and impact
   - Professional but approachable tone

2. **Technical Formatting**:
   - Method names in backticks: `AddParameter`, `WithHostPort`
   - Types in backticks: `IDistributedApplicationBuilder`
   - Bold for emphasis: **major concepts**, **important warnings**
   - Complete, runnable code examples with ```csharp

3. **Content Organization**:
   - Start each section with overview paragraph
   - Group related features together
   - Most impactful changes first
   - Include real code examples from playground/tests
   - Explain "what was hard before" → "what's easy now"

4. **Emoji Usage** (be consistent):
   - ✨ = New features
   - 🔧 = Enhancements to existing features
   - 🧪 = Preview features  
   - ⚠️ = Breaking changes
   - 📊 = Performance improvements
   - 🛡️ = Security improvements

5. **Quality Standards**:
   - All code examples must be complete and runnable
   - Focus on practical developer benefits
   - Use specific, concrete language
   - Include context about why changes matter
   - Highlight integration with broader ecosystem

EXAMPLE FEATURE FORMAT:
### ✨ External service resources

Managing connections to external services like existing databases or APIs was previously complex, requiring manual connection string management and custom resource definitions.

Aspire 9.4 introduces **external service resources**, enabling you to seamlessly integrate any external service into your app model with full support for service discovery and configuration.

```csharp
var builder = DistributedApplication.CreateBuilder(args);

// Connect to existing external database
var userDb = builder.AddExternalService("userdb")
    .WithHostPort("userdb.company.com", 5432)
    .WithConnectionString("Server=userdb.company.com;Database=users");

var api = builder.AddProject<Projects.UserApi>("userapi")
    .WithReference(userDb);  // Automatic connection injection

builder.Build().Run();
```

This enables **hybrid architectures** where new Aspire applications can seamlessly connect to existing infrastructure, making migration and integration scenarios much simpler.

PROCESSING INSTRUCTIONS:
1. Extract key features from the CLI, Dashboard, Hosting, and Component sections
2. Transform technical file/commit details into user benefits
3. Find and polish real code examples from the analysis
4. Create compelling section introductions that explain impact
5. Ensure breaking changes have proper before/after examples
6. Match the professional, developer-friendly tone of Aspire 9.3

CRITICAL: The output should read like official Microsoft documentation - professional, clear, and focused on helping developers understand what's new and how to use it.
```

```
You are analyzing .NET Aspire changes to generate release notes in the style of Aspire 9.3. 

CONTEXT:
- Component: {component_name}
- Files changed: {file_count}
- Key commits: {commit_messages}
- API changes detected: {api_changes_summary}
- Code examples available: {code_examples_paths}

ANALYSIS DATA:
{git_diff_summary}
{playground_examples}
{test_examples}

INSTRUCTIONS:
1. Identify the main feature or improvement from the changes
2. Explain what was difficult before (problem context)  
3. Describe how the new feature solves it (solution overview)
4. Extract real code examples showing the new capability
5. List specific benefits for developers
6. Note any preview limitations or future roadmap items

OUTPUT FORMAT:
Use this exact template structure:

### {emoji} {feature_title}

{problem_context_paragraph}

{solution_overview_paragraph}

```csharp
{real_usage_example}
```

{detailed_benefits_explanation}

{additional_notes_if_applicable}

STYLE GUIDELINES:
- Use descriptive, developer-friendly language
- Include specific method names in backticks
- Show complete, runnable code examples
- Use emojis consistently (✨ new, 🔧 improvements, 🧪 preview)
- Bold key concepts and important notes
- Write in active voice, present tense
- Focus on practical developer benefits
```

## ⚠️ Breaking Change Analysis Prompt

```
You are analyzing breaking changes in .NET Aspire to generate migration documentation.

CONTEXT:
- Component: {component_name}
- Breaking changes detected: {breaking_changes_list}
- Old behavior examples: {old_code_examples}
- New behavior examples: {new_code_examples}

CHANGE ANALYSIS:
{api_diff_showing_removed_or_changed_methods}
{before_after_code_comparison}

INSTRUCTIONS:
1. Explain what was problematic about the old behavior
2. Describe why the change was necessary (technical/strategic reasons)
3. Detail exactly what the new behavior does
4. Show complete before/after code examples
5. Provide step-by-step migration instructions
6. Identify who is affected and how severely

OUTPUT FORMAT:
### 🛡️ {descriptive_title} (Breaking change)

{paragraph_explaining_old_behavior_problems}

{paragraph_explaining_why_change_was_needed}

#### ✅ New behavior in {version}

{explanation_of_new_behavior}

{bulleted_list_of_specific_changes}

#### ⚠️ Breaking change

{clear_statement_of_what_breaks}

{description_of_who_is_affected}

**Before:**
```csharp
{complete_old_working_example}
```

**After:**
```csharp
{complete_new_working_example}
```

**Migration**:
{numbered_migration_steps}

{additional_migration_notes}

QUALITY REQUIREMENTS:
- Code examples must be complete and runnable
- Migration steps must be actionable and specific
- Clearly state the scope of impact (all users, specific scenarios, etc.)
- Include any available workarounds or alternatives
```

## 📊 Component Summary Prompt

```
You are creating a high-level summary of changes to a .NET Aspire component.

CONTEXT:
- Component: {component_name} ({component_path})
- Change scope: {file_count} files, {additions} additions, {deletions} deletions
- Major commits: {top_commits}
- API analysis: {new_apis}, {changed_apis}, {removed_apis}

DETAILED ANALYSIS:
{component_analysis_output}
{extracted_features}
{breaking_changes}

INSTRUCTIONS:
1. Create a compelling section title with appropriate emoji
2. Write a brief overview paragraph explaining the component's role
3. Summarize the major improvements in this release
4. Group related features together logically
5. Highlight the most impactful changes for developers
6. Note any architectural or foundational changes

OUTPUT FORMAT:
## {emoji} {component_name} enhancements

{brief_component_description_and_role}

{overview_of_changes_in_this_release}

{subsections_for_each_major_feature_using_feature_template}

ORGANIZATION GUIDELINES:
- Start with most impactful features first
- Group related improvements together
- Use consistent emoji categories:
  * ✨ = New features
  * 🔧 = Enhancements to existing features  
  * 🧪 = Preview features
  * ⚠️ = Breaking changes
  * 🛡️ = Security improvements
  * 📊 = Performance improvements
- End sections with preview limitations or future roadmap notes
```

## 🔧 API Example Extraction Prompt

```
You are extracting real API usage examples from .NET Aspire playground and test code.

CONTEXT:
- Target APIs: {api_methods_to_demonstrate}
- Playground files: {playground_file_paths}
- Test files: {test_file_paths}
- Commit context: {relevant_commits}

CODE SAMPLES:
{playground_code_snippets}
{test_code_snippets}

INSTRUCTIONS:
1. Find examples that show new or changed APIs in action
2. Extract complete, working code examples (not fragments)
3. Add inline comments explaining key concepts
4. Show real-world usage patterns, not toy examples
5. Include error handling and edge cases where relevant
6. Demonstrate best practices and recommended patterns

OUTPUT FORMAT:
For each API or feature, provide:

#### {api_or_feature_name}

**From playground/{example_name}:**
```csharp
{complete_working_example_with_comments}
```

**From tests/{test_name}:**
```csharp
{test_example_showing_expected_behavior}
```

**Key points:**
- {bullet_point_explaining_usage}
- {bullet_point_about_best_practices}
- {bullet_point_about_common_patterns}

QUALITY STANDARDS:
- Examples must compile and run
- Include necessary using statements and setup code
- Show parameter values and configuration options
- Demonstrate integration with other Aspire features
- Include comments explaining non-obvious aspects
- Focus on practical, real-world scenarios
```

## 🎨 Style and Voice Guidelines

### Writing Style
- **Active voice**: "Aspire now supports" not "Support for X has been added"
- **Present tense**: "The CLI now walks upward" not "The CLI will walk upward"
- **Developer-focused**: Explain benefits and impact, not just what changed
- **Concrete examples**: Show actual code, not descriptions of code
- **Clear hierarchy**: Use consistent heading levels and organization

### Technical Terminology
- **Method names in backticks**: `AddParameter`, `WithHostPort`
- **Types in backticks**: `IConfiguration`, `BlobContainerClient`
- **Bold for emphasis**: **major concepts**, **important warnings**
- **Italic for parameters**: *connectionName*, *resourceName*
- **Code blocks with language**: ```csharp for C# code

### Content Organization Priorities
1. **New major features** - Biggest impact, most exciting
2. **Enhancements to existing features** - Improvements developers will notice
3. **Developer experience improvements** - Better APIs, easier usage
4. **Preview features** - Clearly marked with limitations
5. **Breaking changes** - Always clearly marked with migration guidance

### Quality Checklist
- [ ] All code examples are complete and runnable
- [ ] Breaking changes include before/after examples
- [ ] Preview features are clearly marked with limitations
- [ ] Benefits are explained from developer perspective  
- [ ] Examples show real-world usage patterns
- [ ] Migration guidance is actionable and specific
- [ ] Section organization follows logical flow
- [ ] Emojis are used consistently for categories
