# Copilot Instructions for AI Coding Agents

## Security and Compliance

**IMPORTANT**: All AI coding assistants must adhere to security and compliance guidelines documented in [copilot-security-instructions.md](./copilot-security-instructions.md). This includes mandatory requirements for:
- GPG commit signing (never bypass or disable)
- Branch protection and pull request workflows
- Production configuration change control
- Authentication and authorization controls
- Security standards compliance (ISO 27001, NIST, PCI DSS, GDPR, etc.)

Failure to follow these security guidelines may result in policy violations and security incidents.

## Project Overview

- This repository implements the Amido Independent Runner, a PowerShell-based automation toolkit for CI/CD pipelines.
- The core logic resides in the `src/modules/EnsonoBuild/` directory, structured as a PowerShell module with supporting scripts, classes, and utilities.
- Documentation is maintained in the `docs/` folder (Asciidoc format) and the root `README.md`.

## Key Components

- **PowerShell Module:**
  - Main entry: `src/modules/EnsonoBuild/EnsonoBuild.psm1` and manifest `EnsonoBuild.psd1`.
  - Subfolders: `api/`, `cloud/`, `command/`, `exported/`, `projects/`, `utils/`, etc. Each contains related cmdlets and tests.
  - Tests: Each cmdlet typically has a corresponding `*.Tests.ps1` file in the same directory.
- **Test Infrastructure:**
  - Shared test helpers in `test/TestHelpers.ps1` (e.g., `New-TestDir` for creating isolated test directories).
  - Tests use dot-sourcing to import helpers: `. $PSScriptRoot/../../../../test/TestHelpers.ps1`
  - Pester v5+ with TestDrive disabled in favor of explicit temporary directory management.
- **Build Scripts:**
  - Located in `build/scripts/` (e.g., `Invoke-PesterTests.ps1`, `Build-Help.ps1`).
  - Used for running tests, generating help, and other automation tasks.
- **Configuration:**
  - YAML files in `build/config/` and `build/eirctl/` define environment variables, contexts, and tasks.

## Developer Workflows

- **Testing:**
  - Run all tests using: `pwsh -File ./build/scripts/Invoke-PesterTests.ps1 .`
  - Or use containerized testing: `eirctl tests`
  - Tests may modify environment variables; always run in a separate PowerShell instance.
  - Current status: 270 passing, 0 failing, 20 skipped, 80.25% coverage.
- **Building Documentation:**
  - Use scripts in `build/scripts/` or refer to `docs/` for Asciidoc sources.
- **Adding Cmdlets:**
  - Place new cmdlets in the appropriate subfolder under `src/modules/EnsonoBuild/`.
  - Add corresponding `*.Tests.ps1` files for each cmdlet.
  - Use shared test helpers from `test/TestHelpers.ps1` for common test utilities.
  - Import helpers with: `. $PSScriptRoot/../../../../test/TestHelpers.ps1`

## Project Conventions

- **File Naming:**
  - Cmdlets: `Verb-Noun.ps1` (e.g., `Invoke-API.ps1`).
  - Tests: `Verb-Noun.Tests.ps1` in the same directory as the cmdlet.
- **Environment Management:**
  - Some tests and scripts alter environment variables; avoid running in shared shells.
- **Documentation:**
  - Asciidoc format in `docs/`.
  - Update `README.md` for high-level changes.

## Integration Points

- **External Dependencies:**
  - PowerShell modules (see `src/modules/EnsonoBuild/` for imports).
  - YAML configuration files for pipeline/environment setup.

## Examples

- To run all tests: `pwsh -File ./build/scripts/Invoke-PesterTests.ps1 .`
- To add a new API cmdlet: create `src/modules/EnsonoBuild/api/New-ApiCmdlet.ps1` and `New-ApiCmdlet.Tests.ps1`.

Refer to `src/modules/EnsonoBuild/` and `build/scripts/` for implementation patterns. See `README.md` for more context.
