# Copilot Instructions for AI Coding Agents

## Security and Compliance

> **⚠️ MANDATORY**: All AI coding assistants **MUST** adhere to security and compliance guidelines documented in [copilot-security-instructions.md](./copilot-security-instructions.md).

### Critical Security Requirements

| Requirement | Description |
|-------------|-------------|
| **GPG Commit Signing** | Never bypass or disable. If signing fails, halt and alert—do not suggest `--no-gpg-sign` or similar workarounds. |
| **Branch Protection** | Never force push, bypass protections, or commit directly to `main`/`master`. Always use feature branches and PRs. |
| **Change Control** | Never make direct production configuration changes. Follow formal change management processes. |
| **Authentication/Authorization** | Never disable auth mechanisms, hard-code credentials, or reduce security levels. |
| **Compliance Standards** | All code must comply with ISO 27001, NIST SP 800-53, FIPS 140-2/3, PCI DSS v4.0, CIS Controls, and OWASP Top 10. |

Failure to follow these security guidelines may result in policy violations and security incidents.

---

## Project Overview

**Ensono Independent Runner** is a PowerShell-based automation toolkit enabling cross-platform CI/CD pipelines that run consistently across developer workstations, Azure DevOps, and other CI/CD platforms.

### Key Characteristics

- **Language**: PowerShell 7.0+ (cross-platform)
- **Architecture**: Containerized task execution via Docker
- **Task Runner**: `eirctl` (Ensono Independent Runner Control)
- **Module Location**: `src/modules/EnsonoBuild/`
- **Documentation Format**: AsciiDoc (in `docs/`)

---

## Repository Structure

```text
independent-runner/
├── src/modules/EnsonoBuild/     # Main PowerShell module
│   ├── EnsonoBuild.psd1         # Module manifest
│   ├── EnsonoBuild.psm1         # Main module loader
│   ├── exported/                # Public cmdlets (Build-*, Invoke-*, etc.)
│   ├── api/                     # API interaction functions
│   ├── cloud/                   # Cloud platform integrations (Azure, EKS)
│   ├── command/                 # Command execution utilities
│   ├── utils/                   # Utility functions
│   ├── vcs/                     # Version control functions
│   ├── wiki/                    # Documentation/wiki functions
│   ├── projects/                # Project management functions
│   └── classes/                 # PowerShell class definitions
├── build/
│   ├── eirctl/                  # Task and context definitions
│   │   ├── tasks.yaml           # Task definitions
│   │   └── contexts.yaml        # Execution contexts (containers)
│   ├── scripts/                 # Build automation scripts
│   │   ├── Invoke-PesterTests.ps1
│   │   ├── Build-Help.ps1
│   │   └── Test-PesterExitCode.ps1
│   └── config/                  # Environment variable configs
├── docs/                        # AsciiDoc documentation sources
├── test/                        # Shared test infrastructure
│   ├── TestHelpers.ps1          # Common test utilities
│   └── stubs/                   # Module stubs for testing
├── eirctl.yaml                  # Main pipeline configuration
└── outputs/                     # Generated artifacts (gitignored)
```

---

## Key Components

### PowerShell Module (`src/modules/EnsonoBuild/`)

| Component | Location | Description |
|-----------|----------|-------------|
| **Entry Point** | `EnsonoBuild.psm1` | Main module loader |
| **Manifest** | `EnsonoBuild.psd1` | Module metadata and exports |
| **Public Cmdlets** | `exported/` | User-facing functions (Build-*, Invoke-*, etc.) |
| **API Functions** | `api/` | REST API interaction (Get-AuthHeader, Invoke-API) |
| **Cloud Integrations** | `cloud/` | Connect-Azure, Connect-EKS |
| **Utilities** | `utils/` | Helper functions |
| **VCS Functions** | `vcs/` | Version control operations |

### Test Infrastructure

| Component | Location | Description |
|-----------|----------|-------------|
| **Test Helpers** | `test/TestHelpers.ps1` | Shared utilities (e.g., `New-TestDir`) |
| **Unit Tests** | `*.Tests.ps1` (co-located) | Pester v5+ tests alongside source |
| **Module Stubs** | `test/stubs/modules/` | Mock modules for isolated testing |

### Build & Orchestration

| Component | Location | Description |
|-----------|----------|-------------|
| **Pipeline Config** | `eirctl.yaml` | Main pipeline definitions |
| **Tasks** | `build/eirctl/tasks.yaml` | Individual task definitions |
| **Contexts** | `build/eirctl/contexts.yaml` | Container execution contexts |
| **Environment** | `build/config/stage_envvars.yml` | Required environment variables |

---

## Developer Workflows

### Prerequisites

```bash
# Required
pwsh --version       # PowerShell 7.0+
docker --version     # For containerized execution
git --version        # Version control
```

### Running Tests

```bash
# Option 1: Direct PowerShell (faster, recommended for development)
pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage

# Option 2: Containerized (matches CI/CD environment)
eirctl tests

# Run specific test file
pwsh -Command "Invoke-Pester -Path ./src/modules/EnsonoBuild/api/Invoke-API.Tests.ps1"
```

**Test Status**: 270 passing, 0 failing, 20 skipped, 80.25% coverage (exceeds 75% target)

### Building

```bash
# Build the module
eirctl build

# Build documentation
eirctl docs

# Clean outputs
eirctl clean

# Full pipeline (clean + docs + tests + build)
eirctl all
```

### Adding New Cmdlets

1. **Create the cmdlet** in the appropriate subfolder:
   ```powershell
   # src/modules/EnsonoBuild/api/New-ApiEndpoint.ps1
   function New-ApiEndpoint {
       [CmdletBinding()]
       param(
           [Parameter(Mandatory)]
           [string]$Url
       )
       # Implementation
   }
   ```

2. **Create corresponding tests** in the same directory:
   ```powershell
   # src/modules/EnsonoBuild/api/New-ApiEndpoint.Tests.ps1
   . $PSScriptRoot/../../../../test/TestHelpers.ps1
   
   Describe "New-ApiEndpoint" {
       It "Should create an endpoint" {
           # Test implementation
       }
   }
   ```

3. **Export the function** (if public) by adding to the module manifest or export list.

4. **Run tests** to verify:
   ```bash
   pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild/api -UnitTests
   ```

---

## Coding Conventions

### File Naming

| Type | Pattern | Example |
|------|---------|---------|
| Cmdlets | `Verb-Noun.ps1` | `Invoke-API.ps1`, `Build-DockerImage.ps1` |
| Tests | `Verb-Noun.Tests.ps1` | `Invoke-API.Tests.ps1` |
| Classes | `ClassName.ps1` | `StopTaskException.ps1` |

### PowerShell Best Practices

```powershell
# Use approved verbs (Get, Set, New, Remove, Invoke, Build, etc.)
function Invoke-CustomAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputObject,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        # Initialization
    }
    
    process {
        # Main logic
    }
    
    end {
        # Cleanup
    }
}
```

### Test Patterns

```powershell
# Import test helpers at the top
. $PSScriptRoot/../../../../test/TestHelpers.ps1

Describe "Function-Name" {
    BeforeAll {
        # Create isolated test directory
        $script:testDir = New-TestDir
    }
    
    AfterAll {
        # Cleanup
        if (Test-Path $script:testDir) {
            Remove-Item -Recurse -Force $script:testDir
        }
    }
    
    Context "When condition X" {
        It "Should do Y" {
            # Arrange, Act, Assert
        }
    }
}
```

### Environment Variables

Tests may modify environment variables. **Always run tests in a separate PowerShell instance** to avoid polluting your shell:

```bash
# Recommended: separate instance
pwsh -File ./build/scripts/Invoke-PesterTests.ps1 .

# Avoid: running in current shell can leave modified env vars
```

---

## Pipeline Configuration

### Available eirctl Commands

| Command | Description |
|---------|-------------|
| `eirctl tests` | Run unit tests with coverage |
| `eirctl build` | Build the PowerShell module |
| `eirctl docs` | Generate documentation |
| `eirctl clean` | Clean output directories |
| `eirctl all` | Full pipeline (clean + docs + tests + build) |
| `eirctl release` | Publish release to GitHub |

### Execution Contexts

Tasks run in containerized contexts defined in `build/eirctl/contexts.yaml`:

| Context | Container | Purpose |
|---------|-----------|---------|
| `powershell` | `ensono/eir-infrastructure` | General PowerShell execution |
| `powershell_test` | `ensono/eir-infrastructure` | Test execution with coverage |
| `docsenv` | `ensono/eir-asciidoctor` | Documentation generation |
| `dotnet` | `ensono/eir-dotnet` | .NET operations (coverage reports) |

---

## Common Issues & Troubleshooting

### Permission Errors

```bash
# Ensure Docker is running and accessible
docker ps

# Check Docker permissions (Linux)
groups | grep docker
```

### Module Not Found

```bash
# Rebuild the module
eirctl build

# Verify module path
pwsh -Command "Get-Module -ListAvailable EnsonoBuild"
```

### Test Failures

```bash
# Run with verbose output
pwsh -Command "Invoke-Pester -Path ./src/modules/EnsonoBuild -Verbose"

# Check for environment variable pollution
pwsh -Command "Get-ChildItem Env:"
```

### Skipped Tests

Some tests are intentionally skipped:
- **Build-DockerImage tests**: Docker-in-Docker complexities ([issue #44](https://github.com/Ensono/independent-runner/issues/44))
- **YamlLint Python test**: Skipped when Python unavailable

---

## Integration Points

### External Dependencies

- **PowerShell Modules**: Az.ContainerRegistry, Powershell-Yaml (stubs in `test/stubs/`)
- **Container Images**: `ensono/eir-infrastructure`, `ensono/eir-asciidoctor`, `ensono/eir-dotnet`
- **CI/CD**: Azure DevOps (`build/azuredevops-runner.yml`)

> [!NOTE]
> Ensure that all external dependencies are pinned to a specific version, i.e. `ensono/eir-asciidoctor:1.2.39`, to maintain build consistency and reproducibility.

### Environment Variables for Release

| Variable | Description |
|----------|-------------|
| `BUILD_BUILDNUMBER` | Version number for build |
| `OWNER` | GitHub repository owner |
| `API_KEY` | GitHub API token |
| `PUBLISH_RELEASE` | Enable release publishing |
| `ARTIFACTS_DIR` | Output artifacts directory |

---

## Documentation

### Formats

- **Source**: AsciiDoc files in `docs/`
- **Output**: PDF documentation, command reference

### Key Documents

| File | Description |
|------|-------------|
| `docs/index.adoc` | Main documentation entry |
| `docs/cmdref.adoc` | Command reference |
| `docs/usage/usage.adoc` | Usage guide |
| `docs/pipelines.adoc` | Pipeline configuration |

### Building Documentation

```bash
# Generate all documentation
eirctl docs

# Output appears in outputs/ directory
```

---

## Quick Reference for AI Agents

### Understanding the Codebase

1. **Entry Point**: `src/modules/EnsonoBuild/EnsonoBuild.psm1`
2. **Public Functions**: `src/modules/EnsonoBuild/exported/`
3. **Tests**: Co-located `*.Tests.ps1` files
4. **Configuration**: `eirctl.yaml` and `build/eirctl/`

### Making Changes Checklist

- [ ] Modify PowerShell functions in `src/modules/EnsonoBuild/`
- [ ] Update or create corresponding `*.Tests.ps1` files
- [ ] Use test helpers from `test/TestHelpers.ps1`
- [ ] Run tests: `pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage`
- [ ] Ensure all tests pass and coverage remains above 75%
- [ ] Update documentation if adding public cmdlets
- [ ] Follow security guidelines from `copilot-security-instructions.md`

### Code Analysis Commands

```bash
# Run all tests with coverage
pwsh -File ./build/scripts/Invoke-PesterTests.ps1 -Path ./src/modules/EnsonoBuild -UnitTests -Coverage

# Containerized testing (matches CI/CD)
eirctl tests

# Build and validate
eirctl build

# Full validation
eirctl all
```
