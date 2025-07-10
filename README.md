# ZeroFailed.Build.DotNet

[![Build Status](https://github.com/zerofailed/ZeroFailed.Build.DotNet/actions/workflows/build.yml/badge.svg)](https://github.com/zerofailed/ZeroFailed.Build.DotNet/actions/workflows/build.yml)  
[![GitHub Release](https://img.shields.io/github/release/endjin/ZeroFailed.Build.DotNet.svg)](https://github.com/zerofailed/ZeroFailed.Build.DotNet/releases)  
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ZeroFailed.Build.DotNet?color=blue)](https://www.powershellgallery.com/packages/ZeroFailed.Build.DotNet)  
[![License](https://img.shields.io/github/license/endjin/ZeroFailed.Build.DotNet.svg)](https://github.com/zerofailed/ZeroFailed.Build.DotNet/blob/main/LICENSE)

A [ZeroFailed](https://github.com/zerofailed/ZeroFailed) extension containing features that support build processes for .NET projects.

## Overview

| Component Type | Included | Notes               |
|----------------|----------|---------------------|
| Tasks          | yes      | |
| Functions      | yes      | |
| Processes      | no       | Designed to be compatible with the default process provided by the [ZeroFailed.Build.Common](https://github.com/zerofailed/ZeroFailed.Build.Common) extension |

For more information about the different component types, please refer to the [ZeroFailed documentation](https://github.com/zerofailed/ZeroFailed/blob/main/README.md#extensions).

This extension consists of the following feature groups, click the links to see their documentation:

- Compilation
- Testing
- SBOM generation
- Packaging
- Publishing

## Dependencies

| Extension                | Reference Type | Version |
|--------------------------|----------------|---------|
| [ZeroFailed.Build.Common](https://github.com/zerofailed/ZeroFailed.Build.Common) | git            | `main`  |
