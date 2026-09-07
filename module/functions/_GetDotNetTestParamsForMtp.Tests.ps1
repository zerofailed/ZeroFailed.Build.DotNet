# <copyright file="_GetDotNetTestParamsForMtp.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    # sut
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')

    # Returns the argument immediately following the named flag (or $null if absent).
    function Get-ArgValue {
        param ([string[]] $Arguments, [string] $Flag)
        $index = [array]::IndexOf($Arguments, $Flag)
        if ($index -ge 0 -and $index -lt ($Arguments.Count - 1)) { $Arguments[$index + 1] } else { $null }
    }

    $script:SolutionToBuild = "C:\code\MySolution.sln"
    $script:DotNetTestResultsDir = ""
    $script:_fileLoggerProps = $null
}

Describe '_GetDotNetTestParamsForMtp' {

    Context 'With the default logger configuration' {

        BeforeAll {
            $script:DotNetTestLoggers = @(
                "console;verbosity=minimal"
                "trx;LogFilePrefix=test-results"
            )
            $script:DotNetTestResultsDir = ""
        }

        It 'passes the solution via --solution' {
            Get-ArgValue (_GetDotNetTestParamsForMtp) '--solution' | Should -Be 'C:\code\MySolution.sln'
        }

        It 'requests a TRX report' {
            _GetDotNetTestParamsForMtp | Should -Contain '--report-trx'
        }

        It 'generates a per-project unique TRX filename using MTP placeholders' {
            Get-ArgValue (_GetDotNetTestParamsForMtp) '--report-trx-filename' | Should -Be 'test-results_{asm}_{tfm}_{arch}.trx'
        }

        It 'matches the default test-results_*.trx discovery glob' {
            Get-ArgValue (_GetDotNetTestParamsForMtp) '--report-trx-filename' | Should -BeLike 'test-results_*.trx'
        }

        It 'does not emit --results-directory when none is configured' {
            _GetDotNetTestParamsForMtp | Should -Not -Contain '--results-directory'
        }

        It 'does not translate the console logger into an argument' {
            _GetDotNetTestParamsForMtp | Should -Not -Contain '--report-console'
        }
    }

    Context 'With a custom LogFilePrefix' {

        BeforeAll { $script:DotNetTestLoggers = @("trx;LogFilePrefix=my-results") }

        It 'uses the configured prefix in the TRX filename' {
            Get-ArgValue (_GetDotNetTestParamsForMtp) '--report-trx-filename' | Should -Be 'my-results_{asm}_{tfm}_{arch}.trx'
        }
    }

    Context 'With no LogFilePrefix or LogFileName' {

        BeforeAll { $script:DotNetTestLoggers = @("trx") }

        It 'falls back to the test-results prefix' {
            Get-ArgValue (_GetDotNetTestParamsForMtp) '--report-trx-filename' | Should -Be 'test-results_{asm}_{tfm}_{arch}.trx'
        }
    }

    Context 'With an explicit LogFileName' {

        BeforeAll { $script:DotNetTestLoggers = @("trx;LogFileName=results.trx") }

        It 'honours the requested filename verbatim' {
            Get-ArgValue (_GetDotNetTestParamsForMtp) '--report-trx-filename' | Should -Be 'results.trx'
        }
    }

    Context 'With a results directory configured' {

        BeforeAll {
            $script:DotNetTestLoggers = @("trx;LogFilePrefix=test-results")
            $script:DotNetTestResultsDir = "C:\build\_testResults"
        }

        AfterAll { $script:DotNetTestResultsDir = "" }

        It 'directs all projects to the shared results directory' {
            Get-ArgValue (_GetDotNetTestParamsForMtp) '--results-directory' | Should -Be 'C:\build\_testResults'
        }
    }

    Context 'With only an unrecognised logger' {

        BeforeAll { $script:DotNetTestLoggers = @("html") }

        It 'does not request a TRX report' {
            _GetDotNetTestParamsForMtp | Should -Not -Contain '--report-trx'
        }
    }
}
