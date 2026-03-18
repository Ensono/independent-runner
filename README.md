# Ensono Independent Runner

This repository contains the documentation on how the Ensono Independent Runner is expected to work. It also contains the PowerShell module that is used in each of the pipelines that use the Independent Runner.

## Running Tests

Tests should be run in another instance of Pwsh as there are Tests that modify
environment variables and don't always set them back.

An example safe invocation is:
`pwsh -File ./build/scripts/Invoke-PesterTests.ps1 .`
