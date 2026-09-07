# <copyright file="_GetDotNetTestParamsForMtp.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
    .SYNOPSIS
    Generates the command-line arguments required for using 'dotnet test' with the Microsoft Testing Platform.

    .DESCRIPTION
    Generates the command-line arguments required for using 'dotnet test' with the Microsoft Testing Platform.
    Directly consumes script-scoped variables expected to be available via the 'RunTestsWithDotNetCoverage'
    InvokeBuild task ($script:SolutionToBuild, $script:DotNetTestLoggers, $script:DotNetTestResultsDir,
    $script:_fileLoggerProps).

    The TRX report filename is generated with the MTP filename placeholders '{asm}_{tfm}_{arch}' appended to
    the configured 'LogFilePrefix' (default 'test-results'), so that each test project in a solution produces
    a distinct file and results are never overwritten - regardless of whether the results directory is shared
    or per-project. When $script:DotNetTestResultsDir is set, '--results-directory' is emitted so all projects
    write to that single location; when it is empty, no '--results-directory' is passed and each project uses
    its own 'TestResults' folder next to its build output (the MTP default).

    .EXAMPLE
    $testParams = _GetDotNetTestParamsForMtp
#>
function _GetDotNetTestParamsForMtp {
    [CmdletBinding()]
    param ()

    $dotnetTestArgs = @(
        "--solution", $script:SolutionToBuild
    )

    $script:DotNetTestLoggers |
        Where-Object { $_ } |
        ForEach-Object {
            if ($_ -match "^trx") {
                $dotnetTestArgs += "--report-trx"
                # Parse existing TRX logger configuration parameters
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
                if ($trxParams.ContainsKey("LogFileName")) {
                    # An explicit filename was requested - honour it verbatim. Note that when running a
                    # multi-project solution this will cause every project to write to the same file.
                    $dotnetTestArgs += "--report-trx-filename", $trxParams["LogFileName"]
                }
                else {
                    # Append the MTP filename placeholders so that each test project in the solution
                    # produces a distinct file (matching the 'test-results_*.trx' discovery glob), rather
                    # than every project overwriting a single 'test-results.trx'.
                    $trxFilePrefix = $trxParams.ContainsKey("LogFilePrefix") ? $trxParams["LogFilePrefix"] : "test-results"
                    $dotnetTestArgs += "--report-trx-filename", "$($trxFilePrefix)_{asm}_{tfm}_{arch}.trx"
                }
                $unhandledTrxParams = $trxParams.Keys | Where-Object { $_ -notin @("LogFilePrefix", "LogFileName") }
                if ($unhandledTrxParams.Count -gt 0) {
                    Write-Host -f Yellow "The following TRX logger parameters are not supported and will be ignored when using Microsoft Testing Platform: $($unhandledTrxParams -join ', ')"
                }
            }
            elseif ($_ -match "^console") {
                # The Microsoft Testing Platform renders console output natively; there is no equivalent
                # logger argument to translate, so this entry is simply ignored.
                Write-Verbose "Ignoring '$_' logger - console output is handled natively by the Microsoft Testing Platform"
            }
            else {
                Write-Host -f Yellow "Skipping unknown MTP logger '$_'"
            }
            # NOTE:
            #   Consider other report extensions we should support here and whether we can retain the
            #   ability to use them at runtime, without requiring test projects to explicitly reference
            #   them (as we are able to do when using the VSTest platform by simply bundling a DLL)
    }

    # When a results directory is configured, direct all test projects' output there; otherwise leave
    # it unset so each project writes to its own 'TestResults' folder next to its build output.
    if ($script:DotNetTestResultsDir) {
        $dotnetTestArgs += "--results-directory", $script:DotNetTestResultsDir
    }

    if ($null -ne $script:_fileLoggerProps -and $script:_fileLoggerProps) {
        $dotnetTestArgs += $script:_fileLoggerProps
    }

    return $dotnetTestArgs
}