# <copyright file="_GetDotNetTestParamsForVsTest.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<# 
    .SYNOPSIS
    Generates the command-line arguments required for using 'dotnet test' with VSTest.

    .DESCRIPTION
    Generates the command-line arguments required for using 'dotnet test' with VSTest.
    Directly consumes script-scoped variables expected to be available via the 'RunTestsWithDotNetCoverage'
    InvokeBuild task.

    .EXAMPLE
    $testParams = _GetDotNetTestParamsForVsTest
#>
function _GetDotNetTestParamsForVsTest {
    [CmdletBinding()]
    param ()

    $dotnetTestArgs = @(
        $script:SolutionToBuild
    )

    $script:_resolvedLoggers |
        Where-Object { $_ } |
        ForEach-Object { 
            $dotnetTestArgs += @("--logger", $_)
        }

    # Derive the path to the bundled logger assemblies
    $moduleDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $binDir = Join-Path $moduleDir "bin"
    Write-Verbose "LoggersBinDir: $binDir"

    $dotnetTestArgs += "--test-adapter-path", $binDir
    $dotnetTestArgs += ($script:_fileLoggerProps ? $script:_fileLoggerProps : "/fl")

    return $dotnetTestArgs
}