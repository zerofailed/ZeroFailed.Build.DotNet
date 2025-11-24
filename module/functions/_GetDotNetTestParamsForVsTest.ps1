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
        $SolutionToBuild
        "--verbosity", $LogLevel
    )

    $_resolvedLoggers | ForEach-Object {
        $dotnetTestArgs += @("--logger", $_)
    }

    $dotnetTestArgs += "--test-adapter-path", (Join-Path $moduleDir "bin")
    $dotnetTestArgs += ($_fileLoggerProps ? $_fileLoggerProps : "/fl")

    return $dotnetTestArgs
}