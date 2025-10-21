# Copilot Instructions for AI Coding Agents

## Project Overview

- This repository implements the Amido Independent Runner, a PowerShell-based automation toolkit for CI/CD pipelines.
- The core logic resides in the `src/modules/EnsonoBuild/` directory, structured as a PowerShell module with supporting scripts, classes, and utilities.
- Documentation is maintained in the `docs/` folder (Asciidoc format) and the root `README.md`.

## Key Components

- **PowerShell Module:**
  - Main entry: `src/modules/EnsonoBuild/EnsonoBuild.psm1` and manifest `EnsonoBuild.psd1`.
  - Subfolders: `api/`, `cloud/`, `command/`, `exported/`, `projects/`, `utils/`, etc. Each contains related cmdlets and tests.
  - Tests: Each cmdlet typically has a corresponding `*.Tests.ps1` file in the same directory.
- **Build Scripts:**
  - Located in `build/scripts/` (e.g., `Invoke-PesterTests.ps1`, `Build-Help.ps1`).
  - Used for running tests, generating help, and other automation tasks.
- **Configuration:**
  - YAML files in `build/config/` and `build/eirctl/` define environment variables, contexts, and tasks.

## Developer Workflows

- **Testing:**
  - Run all tests using: `pwsh -File ./build/scripts/Invoke-PesterTests.ps1 .`
  - Tests may modify environment variables; always run in a separate PowerShell instance.
- **Building Documentation:**
  - Use scripts in `build/scripts/` or refer to `docs/` for Asciidoc sources.
- **Adding Cmdlets:**
  - Place new cmdlets in the appropriate subfolder under `src/modules/EnsonoBuild/`.
  - Add corresponding `*.Tests.ps1` files for each cmdlet.

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
