# Comprehensive Agent Instructions for .NET Aspire Release Notes Generation

*This document provides complete instructions for an AI agent to generate professional .NET Aspire release notes from automated analysis data.*

## 🎯 Primary Mission

Transform raw git analysis data into polished, professional release notes that match the exact style and quality of official .NET Aspire release notes.

## 📥 Input Data Sources

You will receive automated analysis data from the release notes generation pipeline:

### **1. Comprehensive Analysis Files**
- **Component analyses**: Individual analyses of CLI, Dashboard, Hosting, etc. components
- **Executive summary**: Key statistics and high-level changes
- **File change counts**: Detailed breakdown of modifications across the codebase

### **2. Meaningful API Examples** (📁 `api-examples/`)
- **`all-playground-examples.md`**: Real new API usage from playground applications (high signal)
- **`all-test-examples.md`**: Filtered test examples showing API patterns (noise filtered out)
- **`api-patterns-summary.md`**: Detected new API methods and integration keywords
- **Component-specific examples**: Individual component usage patterns

### **3. Raw Data Context**
- **Git commit analysis**: Full commit history between releases
- **File modification lists**: What files changed in each component
- **Breaking change markers**: Potential API compatibility issues identified

## 🧠 AI-Driven Analysis Tasks

The automated scripts provide raw data - **your job is intelligent interpretation**:

### **🎯 Critical AI-Only Tasks**

#### **1. Feature Impact Assessment**
**Input**: Raw API patterns like `AddAzureAIFoundry`, `AddExternalService`, `RunAsFoundryLocal`
**Your Task**: 
- Determine which represent **major new features** vs. minor enhancements
- Assess **developer impact** and **adoption likelihood**
- Prioritize features by **strategic importance** to .NET Aspire ecosystem

#### **2. Developer Benefit Transformation**
**Input**: Technical changes like "219 files modified in CLI component"
**Your Task**:
- Transform into **compelling developer benefits**: "CLI now provides real-time feedback"
- Focus on **problems solved** rather than technical implementation
- Explain **practical impact** on day-to-day development workflows

#### **3. Code Example Curation & Enhancement**
**Input**: Raw playground/test code snippets
**Your Task**:
- **Select the most educational examples** from available options
- **Create complete, runnable examples** (not fragments)
- **Add meaningful inline comments** explaining key concepts
- **Structure examples** to show progression from simple to advanced usage

#### **4. Intelligent Section Assignment**
**Input**: Mixed list of features and changes
**Your Task**:
- **Categorize appropriately**: App Model vs. Dashboard vs. CLI vs. Azure vs. Components
- **Group related features** for logical flow
- **Sequence features** from most impactful to least within each section

#### **5. Breaking Change Intelligence**
**Input**: Potential breaking change markers from automated analysis
**Your Task**:
- **Distinguish real breaking changes** from internal refactoring
- **Focus on developer-facing APIs** (exclude CLI/Dashboard internal changes)
- **Create migration examples** showing before/after with clear steps

#### **6. Documentation Quality Polish**
**Input**: Technical documentation fragments
**Your Task**:
- **Apply consistent Microsoft style** and tone
- **Ensure professional quality** ready for publication
- **Add context and motivation** for why features matter
- **Create compelling section introductions** that set the stage

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

### **Phase 1: Data Analysis & Feature Extraction**

#### **A. Parse Automated Analysis Data**
1. **Review `api-patterns-summary.md`** for new API method patterns
2. **Analyze `all-playground-examples.md`** for real-world usage demonstrations  
3. **Examine component analyses** for context on file changes and commit messages
4. **Identify integration keywords**: Azure*, GitHub*, External*, Chat*, AI*

#### **B. Feature Impact Classification**
Classify each detected change by impact:
- **🌟 Major Features**: New integrations, significant capabilities (e.g., Azure AI Foundry, External Services)
- **🔧 Enhancements**: Improvements to existing features (e.g., parameter customization, configuration options)
- **🧪 Preview Features**: Experimental or early-access capabilities
- **⚠️ Breaking Changes**: API compatibility breaks requiring migration

#### **C. Developer Benefit Mapping**
For each feature, define:
- **Problem it solves**: What was difficult/impossible before?
- **Developer value**: How does this improve the development experience?
- **Use case scenarios**: When would developers use this?
- **Integration context**: How does this fit into the broader Aspire ecosystem?

### **Phase 2: Content Creation & Organization**

#### **A. Section Assignment Strategy**
Use this decision tree for feature placement:

- **🖥️ App Model Enhancements**: 
  - External service integrations (`AddExternalService`)
  - Resource management improvements
  - Hosting platform capabilities
  - Publishing pipeline changes

- **📊 Dashboard Delights**:
  - UI/UX improvements (visible in screenshots/descriptions)
  - Interaction features (commands, real-time updates)
  - Telemetry and monitoring enhancements

- **🚀 Deployment & Publish**:
  - Container deployment improvements
  - Kubernetes enhancements
  - Publishing workflow changes
  - Infrastructure provisioning updates

- **🖥️ CLI Enhancements**:
  - New commands or command improvements
  - Developer experience improvements
  - Backchannel communication features

- **☁️ Azure Goodies**:
  - New Azure service integrations (AI Foundry, WebPubSub, etc.)
  - Enhanced existing Azure components
  - Azure-specific hosting improvements

- **🧩 Component Integrations**:
  - New component packages
  - Enhanced existing components
  - Integration library improvements

#### **B. Code Example Development**
Transform raw examples into polished documentation:

1. **Extract meaningful snippets** from playground examples
2. **Create complete, runnable examples** (not fragments)
3. **Add explanatory comments** highlighting key concepts
4. **Show practical scenarios** rather than toy examples
5. **Include before/after examples** for enhanced features

#### **C. Breaking Change Analysis**
Apply this filter to potential breaking changes:
- **Include**: Public API changes in components developers code against
- **Include**: Configuration or behavior changes requiring code updates
- **Exclude**: CLI internal APIs (developers don't code against these)
- **Exclude**: Dashboard internal APIs (not used by developer code)
- **Exclude**: Internal refactoring without external impact

### **Phase 3: Quality Assurance & Style Application**

### **Phase 3: Quality Assurance & Style Application**

#### **A. Content Review Checklist**
- ✅ **Developer benefits emphasized** over technical implementation details
- ✅ **Complete code examples** that can be copy-pasted and run
- ✅ **Consistent emoji usage** and section formatting
- ✅ **Active voice** and present tense throughout
- ✅ **Professional Microsoft tone** matching official documentation

#### **B. Technical Accuracy Validation**
- ✅ **API method names correct** (verified against extracted examples)
- ✅ **Code examples syntactically valid** C# or configuration
- ✅ **Namespace and using statements** included where necessary
- ✅ **Real-world scenarios** demonstrated (not contrived examples)

#### **C. Strategic Messaging Alignment**
- ✅ **Aspire value proposition** reinforced throughout
- ✅ **Cloud-native development focus** highlighted
- ✅ **Developer productivity benefits** clearly articulated
- ✅ **Ecosystem integration** advantages demonstrated

## 🎨 Enhanced Style Requirements

### **Critical AI Judgment Calls**

#### **Feature Prioritization**
When organizing features within sections:
1. **Lead with highest-impact features** that affect most developers
2. **Group related capabilities** to tell a coherent story
3. **Sequence from foundational to advanced** where logical
4. **Highlight ecosystem synergies** between features

#### **Language Precision**
- **"Aspire now supports"** vs. **"Support has been added"** (active vs. passive)
- **"This release introduces"** vs. **"A new feature was implemented"** (outcome vs. process)
- **"Developers can now"** vs. **"It is now possible to"** (personal vs. impersonal)
- **"Simplifies [specific task]"** vs. **"Provides improvements"** (concrete vs. vague)

#### **Technical Depth Balance**
- **Enough detail** to understand the feature's value
- **Not so much detail** that it becomes implementation documentation
- **Focus on what's possible** rather than how it's implemented
- **Practical examples** that show real-world usage patterns

### **Code Example Standards**

#### **Completeness Requirements**
```csharp
// ✅ Good: Complete, runnable example
var builder = DistributedApplication.CreateBuilder(args);

var externalService = builder.AddExternalService("api", "https://api.example.com");

builder.AddProject<Projects.WebApp>("webapp")
       .WithReference(externalService);

builder.Build().Run();
```

```csharp
// ❌ Bad: Fragment without context
builder.AddExternalService("api", "https://api.example.com");
```

#### **Educational Value**
- **Progressive examples**: Simple → Advanced usage patterns
- **Inline comments**: Explain non-obvious concepts
- **Practical scenarios**: Real problems developers face
- **Before/after comparisons**: Show improvement over previous approaches

## 🤖 AI-Specific Processing Guidelines

### **When Analyzing Playground Examples**
Look for these patterns that indicate significant features:
- **New builder methods**: `Add*` methods indicate new integrations
- **New configuration patterns**: `With*` methods indicate enhanced capabilities  
- **New hosting modes**: `RunAs*` methods indicate deployment options
- **Integration patterns**: Service references and dependency injection usage

### **When Evaluating Test Examples**
Focus on tests that demonstrate:
- **Public API usage patterns** (not internal testing utilities)
- **Integration scenarios** (how components work together)
- **Configuration examples** (realistic setup patterns)
- **Error handling and edge cases** (production considerations)

### **When Assessing Breaking Changes**
Consider breaking change severity:
- **High Impact**: Changes to commonly-used public APIs
- **Medium Impact**: Configuration changes requiring code updates
- **Low Impact**: Advanced/less-common API changes
- **No Impact**: Internal changes not visible to developers

### **Quality Indicators for Generated Content**
Your output should achieve:
- **Immediate comprehension**: Developers understand value within 30 seconds
- **Actionable information**: Clear next steps for trying features
- **Contextual relevance**: Features positioned within broader Aspire ecosystem
- **Professional polish**: Ready for Microsoft publication without editing

## 🚀 Workflow Summary: Automated + AI Pipeline

### **What the Scripts Provide** ✅
- **Raw API pattern detection**: New method names and integration keywords
- **Filtered code examples**: Playground and test usage (noise removed)
- **Component change analysis**: File modification counts and affected areas
- **Technical data extraction**: Git diffs, commit analysis, file listings

### **What AI Agents Must Do** 🧠
- **Strategic feature assessment**: Determine which changes matter most to developers
- **Developer benefit translation**: Transform technical changes into compelling user value
- **Code example curation**: Select and enhance the most educational examples
- **Content organization**: Create logical flow and professional presentation
- **Quality assurance**: Ensure Microsoft-level documentation standards

### **Success Metrics** 🎯
The final release notes should:
- ✅ **Immediately communicate value** to .NET Aspire developers
- ✅ **Include actionable examples** developers can use right away
- ✅ **Match official Microsoft quality** in style and presentation
- ✅ **Focus on problems solved** rather than features implemented
- ✅ **Be ready for publication** without additional editing

### **Key AI Advantages Over Pure Automation**
1. **Context understanding**: Recognize which technical changes represent major vs. minor improvements
2. **Developer empathy**: Translate features into practical benefits developers care about
3. **Content quality**: Apply nuanced style and tone matching Microsoft standards
4. **Strategic positioning**: Present features in the context of broader ecosystem value
5. **Educational value**: Create examples that teach concepts, not just demonstrate syntax

**Remember**: The automated scripts filter noise and extract signals - your role is to transform those signals into compelling, professional documentation that helps developers understand and adopt .NET Aspire improvements.
