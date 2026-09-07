# <copyright file="_GetDotNetTestParamsForVsTest.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    # sut
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')

    function Get-ArgValue {
        param ([string[]] $Arguments, [string] $Flag)
        $index = [array]::IndexOf($Arguments, $Flag)
        if ($index -ge 0 -and $index -lt ($Arguments.Count - 1)) { $Arguments[$index + 1] } else { $null }
    }

    $script:SolutionToBuild = "C:\code\MySolution.sln"
    $script:DotNetTestLoggers = @("console;verbosity=minimal", "trx;LogFilePrefix=test-results")
    $script:_fileLoggerProps = $null
}

Describe '_GetDotNetTestParamsForVsTest' {

    Context 'With no results directory configured' {

        BeforeAll { $script:DotNetTestResultsDir = "" }

        It 'passes each logger through verbatim' {
            _GetDotNetTestParamsForVsTest | Should -Contain 'trx;LogFilePrefix=test-results'
        }

        It 'does not emit --results-directory' {
            _GetDotNetTestParamsForVsTest | Should -Not -Contain '--results-directory'
        }
    }

    Context 'With a results directory configured' {

        BeforeAll { $script:DotNetTestResultsDir = "C:\build\_testResults" }

        AfterAll { $script:DotNetTestResultsDir = "" }

        It 'directs all projects to the shared results directory' {
            Get-ArgValue (_GetDotNetTestParamsForVsTest) '--results-directory' | Should -Be 'C:\build\_testResults'
        }
    }
}
