# <copyright file="_GetDotNetTestParamsForMtp.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<# 
    .SYNOPSIS
    Generates the command-line arguments required for using 'dotnet test' with the Microsoft Testing Platform.

    .DESCRIPTION
    Generates the command-line arguments required for using 'dotnet test' with the Microsoft Testing Platform.
    Directly consumes script-scoped variables expected to be available via the 'RunTestsWithDotNetCoverage'
    InvokeBuild task.

    .EXAMPLE
    $testParams = _GetDotNetTestParamsForVsTest
#>
function _GetDotNetTestParamsForMtp {
    [CmdletBinding()]
    param ()

    $dotnetTestArgs = @(
        "--solution", $SolutionToBuild
    )

    $DotNetTestLoggers | ForEach-Object {
        if ($_ -match "^trx") {
            $dotnetTestArgs += "--report-trx"
            # Parse TRX logger parameters
            $trxParams = @{}
            if ($_ -match "^trx;(.*)$") {
                $paramString = $matches[1]
                $paramString -split ';' | ForEach-Object {
                    if ($_ -match "^([^=]+)=(.*)$") {
                        $key = $matches[1]
                        $value = $matches[2]
                        $trxParams[$key] = $value
                    }
                }
            }
            if ($trxParams.ContainsKey("LogFilePrefix")) {
                $dotnetTestArgs += "--report-trx-filename", "$($trxParams["LogFilePrefix"]).trx"
            }
            $unhandledTrxParams = $trxParams.Keys | Where-Object { $_ -ne "LogFilePrefix" }
            if ($unhandledTrxParams.Count -gt 0) {
                Write-Warning "The following TRX logger parameters are not supported and will be ignored when using Microsoft Testing Platform: $($unhandledTrxParams -join ', ')"
            }
        }
        # NOTE:
        #   Consider other report extensions we should support here and whether we can retain the
        #   ability to use them at runtime, without requiring test projects to explicitly reference
        #   them (as we are able to do when using the VSTest platform by simply bundling a DLL)
    }

    $dotnetTestArgs += $_fileLoggerProps

    return $dotnetTestArgs
}