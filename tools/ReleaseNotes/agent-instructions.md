# Comprehensive Agent Instructions for .NET Aspire Release Notes Generation

*This document provides complete instructions for an AI agent to generate professional .NET Aspire release notes from automated analysis data.*

## 🎯 Primary Mission

Transform raw git analysis data into polished, professional release notes that match the exact style and quality of official .NET Aspire release notes.

## 📥 Input Data Sources

You will receive:
1. **Comprehensive analysis file** containing:
   - Executive summary with key statistics
   - Detailed component analyses (CLI, Dashboard, Hosting, etc.)
   - File change counts and commit messages
   - API changes and new features identified
   - Real code examples from playground/tests

2. **Official Aspire style reference** showing:
   - Professional writing patterns
   - Section organization structure
   - Code example formats
   - Breaking change documentation style

## 📋 Output Requirements

Generate a complete `.NET Aspire` release notes document with this exact structure:

```markdown
# .NET Aspire [VERSION]

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
```

## 🎨 Style Requirements (Critical)

### **Voice & Tone**
- ✅ **Use**: "Aspire now supports", "This release introduces"
- ❌ **Avoid**: "Support has been added", "A new feature was implemented"
- **Active voice, present tense** throughout
- **Developer-focused**: Explain benefits and practical impact
- **Professional but approachable** tone matching Microsoft documentation

### **Technical Formatting**
- **Method names in backticks**: `AddParameter`, `WithHostPort`, `AddExternalService`
- **Types in backticks**: `IDistributedApplicationBuilder`, `IConfiguration`
- **Bold for emphasis**: **major concepts**, **important warnings**, **key benefits**
- **Complete code examples** with ````csharp` syntax highlighting
- **Inline comments** in code examples explaining key concepts

### **Content Organization**
- **Start each section** with compelling overview paragraph
- **Group related features** together logically
- **Most impactful changes first** within each section
- **Problem → Solution → Example → Benefits** flow for new features
- **Include real code examples** from playground/tests (extract from analysis data)

### **Emoji Usage (Consistent)**
- ✨ = New features
- 🔧 = Enhancements to existing features
- 🧪 = Preview features  
- ⚠️ = Breaking changes
- 📊 = Performance improvements
- 🛡️ = Security improvements
- 🔗 = Integration features

## 📝 Feature Documentation Pattern

For each major feature, use this proven template:

```markdown
### ✨ {Feature Name}

{Paragraph explaining what was difficult/complex before}

{Paragraph explaining how the new feature solves the problem}

```csharp
{Complete, runnable code example with inline comments}
```

{Paragraph explaining specific developer benefits and impact}

{Additional notes about preview limitations, future roadmap, etc.}
```

**Example Implementation:**
```markdown
### ✨ External service resources

Managing connections to external services like existing databases or APIs was previously complex, requiring manual connection string management and custom resource definitions.

This release introduces **external service resources**, enabling you to seamlessly integrate any external service into your app model with full support for service discovery and configuration.

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
```

## ⚠️ Breaking Changes Pattern

For breaking changes, use this format:

```markdown
### 🛡️ {Descriptive Title} (Breaking change)

{Paragraph explaining what was problematic about old behavior}

{Paragraph explaining why the change was necessary}

#### ✅ New behavior in this release

{Clear explanation of new behavior}

- {Specific change 1}
- {Specific change 2}
- {Specific change 3}

#### ⚠️ Breaking change

{Clear statement of what breaks and who is affected}

**Before:**
```csharp
{Complete old working example}
```

**After:**
```csharp
{Complete new working example}
```

**Migration:**
1. {Step-by-step migration instruction}
2. {Step-by-step migration instruction}
3. {Step-by-step migration instruction}
```

## 🔍 Processing Instructions

### **1. Extract Key Features**
From the analysis data, identify:
- **CLI improvements**: New commands, backchannel communication, internationalization
- **Dashboard enhancements**: UI improvements, interaction features, telemetry
- **Hosting platform**: External services, publishing pipeline, resource management
- **Component updates**: New integrations, enhanced existing components
- **Azure services**: New Azure integrations and improvements

### **2. Transform Technical Details**
Convert raw technical information into developer benefits:
- **File counts → Feature impact**: "219 files changed" → "Major CLI transformation"
- **Commit messages → User stories**: Technical commits → "What developers can now do"
- **API changes → Usage examples**: Method additions → Real code showing benefits

### **3. Find and Polish Code Examples**
Extract real examples from the analysis data:
- Look for playground code showing new APIs
- Find test examples demonstrating expected behavior
- Create complete, runnable examples (not fragments)
- Add inline comments explaining key concepts

### **4. Create Compelling Introductions**
Each section needs a strong opening that:
- Explains the component's role in Aspire
- Summarizes the major improvements in this release
- Sets context for why changes matter to developers

### **5. Quality Validation**
Ensure every piece of content:
- **Focuses on developer benefits** (not just what changed)
- **Uses specific, concrete language** (not generic descriptions)
- **Includes complete code examples** (compilable and runnable)
- **Matches official Microsoft documentation tone**
- **Provides practical value** to developers

## 🎯 Section-Specific Guidelines

### **🖥️ App Model Enhancements**
Focus on: External services, resource management, publishing improvements
Key APIs: `AddExternalService`, new hosting capabilities, publishing pipeline

### **📊 Dashboard Delights**
Focus on: UI improvements, interaction features, telemetry enhancements
Emphasize: Better developer experience, enhanced debugging capabilities

### **🚀 Deployment & Publish**
Focus on: New deployment targets, publishing improvements, infrastructure support
Key themes: Production readiness, deployment flexibility

### **🖥️ CLI Enhancements**
Focus on: New commands, improved discovery, better user experience
Key changes: Backchannel communication, internationalization, interaction features

### **☁️ Azure Goodies**
Focus on: New Azure service integrations, enhanced existing services
Emphasize: Cloud-native development, Azure ecosystem integration

### **🧩 Component Integrations**
Focus on: New component packages, enhanced existing components
Show: Real integration examples, improved developer experience

### **💔 Breaking Changes**
**Important**: Based on analysis results, determine if there are significant breaking changes to highlight
- Only include if real breaking changes are found in the analysis
- Focus on API changes in components that developers code against
- **Exclude** CLI and Dashboard internal API changes (developers don't code against these)

## 🏆 Success Criteria

The final output should:
- ✅ Read like official Microsoft documentation
- ✅ Help developers understand what's new and how to use it
- ✅ Include practical, real-world examples
- ✅ Match official .NET Aspire style and quality exactly
- ✅ Focus on developer benefits and practical impact
- ✅ Be ready for publication without additional editing

## 🚀 Final Notes

**Remember**: You're not just documenting changes—you're helping developers understand how .NET Aspire makes their development experience better. Every feature should be presented in terms of problems solved and benefits gained.

**Quality Standard**: The output should be indistinguishable from official Microsoft .NET Aspire documentation in terms of style, tone, and professionalism.

**Developer Focus**: Always lead with "what can developers do now that they couldn't do before" rather than "what files changed in the codebase."
