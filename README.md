# Ensono Independent Runner

A PowerShell module designed to enable cross-platform CI/CD pipelines that can run consistently across developer workstations, Azure DevOps, and other CI/CD platforms. The module provides a vendor-agnostic approach to build automation using containerized tasks and PowerShell as the primary scripting language.

## 🚀 Quick Start

### Prerequisites

- **PowerShell 7.0+** (cross-platform)
- **Docker** (for containerized task execution)
- **Git** (for version control)

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd independent-runner

# Verify prerequisites
pwsh --version  # Should be 7.0+
docker --version
```

### 2. Available Commands

The project uses `eirctl` (Ensono Independent Runner Control) for task orchestration:

```bash
# Run all tests
eirctl tests

# Run unit tests only (recommended for development)
pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage

# Build the PowerShell module
eirctl build

# Generate documentation
eirctl docs

# Clean output directories
eirctl clean

# Complete build pipeline
eirctl all
```

### 3. Key PowerShell Functions

Once the module is loaded, you'll have access to these core functions:

```powershell
# Infrastructure & Cloud
Invoke-Terraform -Path ./terraform -Action plan
Connect-Azure -SubscriptionId "your-sub-id"
Build-DockerImage -Path . -ImageName "myapp:latest"

# Build & Deploy
Build-PowerShellModule -Path ./src -Name MyModule
Invoke-DotNet -Action build -Path ./src
Invoke-Helm -Action install -Chart ./charts/myapp

# Documentation
Build-Documentation -Config ./docs.json -Type pdf
Publish-Confluence -Page "My Page" -Content ./README.md
```

### 4. Development Workflow

```bash
# 1. Make your changes
# 2. Run tests (use PowerShell directly to avoid container issues)
pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage

# 3. Build and test the module
eirctl build

# 4. Generate documentation
eirctl docs

# 5. Commit your changes
git add .
git commit -m "feat: your feature description"
```

## 🏗️ Architecture Overview

### Module Structure

```text
src/modules/EnsonoBuild/
├── exported/           # Public cmdlets (Build-DockerImage.ps1, etc.)
├── api/               # API interaction functions
├── cloud/             # Cloud platform integrations
├── utils/             # Utility functions
├── vcs/               # Version control functions
├── wiki/              # Documentation functions
├── classes/           # PowerShell class definitions
├── EnsonoBuild.psd1   # Module manifest
└── EnsonoBuild.psm1   # Main module loader
```

### Pipeline Architecture

- **EIRctl** - Task runner orchestrating containerized execution contexts
- **Container-based execution** - Tasks run in Docker containers for consistency
- **Pipeline definitions** - YAML-based configurations in `eirctl.yaml`

## 🧪 Testing

### Running Tests

**IMPORTANT**: For development, run tests directly with PowerShell to avoid container TestDrive conflicts:

```bash
# Recommended: Direct PowerShell execution (all tests pass)
pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage

# Alternative: Container execution (may have TestDrive conflicts)
eirctl tests
```

### Test Results

- **290 total tests** when running directly with PowerShell
- **84.74% code coverage** (exceeds 75% target)
- Tests validate all PowerShell functions with mocked external dependencies

### Test Organization

- Unit tests co-located with source files (`*.Tests.ps1`)
- Pester v5+ framework
- Coverage reports in JaCoCo/Cobertura format
- Test results in NUnit XML format

## 📁 Key Files and Directories

| Path                       | Description                               |
| -------------------------- | ----------------------------------------- |
| `src/modules/EnsonoBuild/` | Main PowerShell module                    |
| `build/eirctl/`            | Task and context definitions              |
| `docs/`                    | Documentation source (AsciiDoc)           |
| `outputs/`                 | Generated artifacts (tests, docs, module) |
| `eirctl.yaml`              | Main pipeline configuration               |

## 🔧 Configuration

### Environment Variables

Functions accept parameters or environment variables:

```bash
# Docker configuration
export DOCKER_IMAGE_NAME="myapp"
export DOCKER_REGISTRY="docker.io"

# Build configuration
export BUILD_BUILDNUMBER="1.0.0"

# Cloud configuration
export AZURE_SUBSCRIPTION_ID="your-sub-id"
```

### Pipeline Configuration

Edit `eirctl.yaml` to customize pipeline behavior:

```yaml
pipelines:
  tests:
    - task: tests:unit
      allow_failure: true
    - task: tests:coverage_report

  build:
    - task: setup:environment
    - task: build:module
```

## 🚨 Common Issues

### TestDrive Conflicts

- **Issue**: "A drive with the name 'TestDrive' already exists" when running `eirctl tests`
- **Solution**: Use direct PowerShell execution: `pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage`

### Permission Issues

- **Issue**: Container permission errors
- **Solution**: Ensure Docker is running and you have proper permissions

### Missing Dependencies

- **Issue**: Module or command not found
- **Solution**: Run `eirctl build` to ensure the module is built correctly

## 🤖 For LLMs and Automation

### Quick Analysis Commands

```bash
# Test the entire codebase
pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage

# Build and validate module
eirctl build

# Check documentation
eirctl docs

# Lint and validate (if available)
eirctl tests
```

### Understanding the Codebase

1. **Entry Point**: `src/modules/EnsonoBuild/EnsonoBuild.psm1`
2. **Public Functions**: `src/modules/EnsonoBuild/exported/`
3. **Tests**: Co-located `*.Tests.ps1` files
4. **Configuration**: `eirctl.yaml` and `build/eirctl/`
5. **Documentation**: `docs/` directory and inline PowerShell help

### Making Changes

1. Modify PowerShell functions in `src/modules/EnsonoBuild/`
2. Update corresponding `*.Tests.ps1` files
3. Run tests: `pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage`
4. Build: `eirctl build`
5. Test integration: `eirctl all`
