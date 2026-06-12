# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

The **Ensono Independent Runner** is a PowerShell module designed to enable cross-platform CI/CD pipelines that can run consistently across developer workstations, Azure DevOps, and other CI/CD platforms. The module provides a vendor-agnostic approach to build automation by using containerized tasks and PowerShell as the primary scripting language.

## Core Architecture

### Module Structure

- **`src/modules/EnsonoBuild/`** - The main PowerShell module containing all functionality
  - **`exported/`** - Public cmdlets available to users (e.g., `Build-DockerImage.ps1`, `Invoke-Terraform.ps1`)
  - **`api/`**, **`cloud/`**, **`utils/`**, **`vcs/`**, **`wiki/`** - Internal function categories
  - **`classes/`** - PowerShell class definitions
  - **`EnsonoBuild.psd1`** - Module manifest defining exported functions and dependencies
  - **`EnsonoBuild.psm1`** - Main module loader that dot-sources all functions

### Pipeline Architecture

- **EIRctl** - The task runner orchestrating containerized execution contexts
- **Container-based execution** - Tasks run in Docker containers (Ensono images) for consistency
- **Pipeline definitions** - YAML-based pipeline configurations in `eirctl.yaml`

## Development Commands

### Running Tests

**IMPORTANT**: Tests must be run in a separate PowerShell session due to environment variable modifications:

```bash
pwsh -File ./build/scripts/Invoke-PesterTests.ps1 .
```

For unit tests with coverage:

```bash
eirctl tests
```

### Building the Module

```bash
eirctl build
```

### Generating Documentation

```bash
eirctl docs
```

### Complete Build Pipeline

```bash
eirctl all
```

### Individual Pipeline Components

- `eirctl clean` - Clean output directories
- `eirctl tests:unit` - Run unit tests only
- `eirctl tests:coverage_report` - Generate coverage reports
- `eirctl build:module` - Build PowerShell module only

## Testing Architecture

### Pester Framework

- All PowerShell functions have corresponding `*.Tests.ps1` files
- Tests use Pester v5+ framework
- Coverage reports generated in JaCoCo format, converted to Cobertura for Azure DevOps
- Test results output in NUnit XML format

### Test Organization

- Unit tests co-located with source files (e.g., `Build-DockerImage.Tests.ps1`)
- Test stubs in `test/stubs/` directory
- Coverage and unit test results written to `outputs/tests/`

### Container Test Contexts

Tests run in containerized environments defined in `build/eirctl/contexts.yaml`:

- **`powershell_test`** - Uses `ensono/eir-infrastructure` image for PowerShell testing
- **`dotnet`** - Uses `ensono/eir-dotnet` for .NET tooling (coverage reports)

## Build System (EIRctl)

### Task Definitions

The `build/eirctl/tasks.yaml` file defines all available tasks:

- **Container contexts** ensure consistent execution environments
- **Dependency management** between tasks using `depends_on`
- **Environment variable passing** between host and containers

### Key Build Contexts

- **`powershell`** - Standard PowerShell execution in `ensono/eir-infrastructure`
- **`docsenv`** - Documentation generation using `ensono/eir-asciidoctor`
- **`dotnet`** - .NET tooling for coverage analysis

### Azure DevOps Integration

- **`build/azuredevops-runner.yml`** - Main Azure Pipelines definition
- Multi-stage pipeline: Docs → Build/Test → Release
- Conditional release stage (main branch or forced)
- Artifact publishing for documentation and modules

## Key PowerShell Functions

### Infrastructure and Cloud

- **`Invoke-Terraform`** - Terraform wrapper with plan/apply/output operations
- **`Connect-Azure`**, **`Connect-EKS`** - Cloud platform authentication
- **`Build-DockerImage`** - Docker build/push with multi-registry support

### Build and Deploy

- **`Build-PowerShellModule`** - Module packaging and versioning
- **`Invoke-DotNet`**, **`Invoke-Helm`**, **`Invoke-Kubectl`** - Tool wrappers
- **`Publish-GitHubRelease`** - Release automation

### Documentation

- **`Build-Documentation`** - AsciiDoc to multiple formats (PDF, HTML, DOCX)
- **`Build-Help`** - PowerShell help documentation generation
- **`Publish-Confluence`** - Wiki integration

## Documentation System

### AsciiDoc-based

- Main documentation in `docs/` using AsciiDoc format
- **`docs.json`** - Configuration for multi-format output (PDF, HTML, DOCX)
- Custom styling in `docs/styles/` with PDF themes and DOCX templates
- Diagram support via `asciidoctor-diagram`

### Auto-generated Reference

- PowerShell help generated from function comment-based help
- Combined with manual documentation for comprehensive user guides

## Environment and Dependencies

### PowerShell Requirements

- **PowerShell 7.0+** required (cross-platform)
- **PowerShell-Yaml** module dependency
- Module functions use modern PowerShell patterns (parameter sets, validation)

### Container Dependencies

- Docker required for task execution
- Ensono-specific container images with pre-installed tooling
- Cross-platform support (Linux containers on Windows/macOS/Linux)

## Common Development Patterns

### Function Structure

- All exported functions follow consistent patterns:
  - Comment-based help with synopsis, description, and examples
  - Parameter validation and environment variable fallbacks
  - Error handling with `Write-Error` and early returns
  - Information logging with `Write-Information`

### Environment Variable Convention

- Functions accept parameters or environment variables (e.g., `$env:DOCKER_IMAGE_NAME`)
- Container execution contexts pass environment variables appropriately
- Build numbers and versions managed via `$env:BUILD_BUILDNUMBER`

### Cross-platform Considerations

- File path handling using `[IO.Path]::Combine()`
- Architecture detection for multi-platform Docker builds
- Conditional logic for Linux vs Windows behaviors

## Release Process

### Automated Release

- Releases triggered on main branch or via `force_release` parameter
- Artifacts include: PowerShell module files, generated documentation PDF
- GitHub releases with auto-generated release notes
- Version management through Azure DevOps build numbers

### Manual Testing

- Local testing via `eirctl` commands before pushing
- Documentation verification in multiple output formats
- Module functionality validation in clean environments
