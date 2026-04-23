# <copyright file="report.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

. $PSScriptRoot/report.properties.ps1


# These tasks should always run even if the build has failed, if the failure was caused by
# not all tests passing, then any configured test reporting is still required.
# Setup an OnExitAction that runs a nested build that calls the TestReport tasks.
$_generateTestReports = {
    Invoke-Build -File "$PSScriptRoot/report.tasks.ps1" -Task TestReport
}
Register-OnExitAction -Action $_generateTestReports

# Synopsis: Generates additional test reports using 'dotnet-reportgenerator-globaltool'.
task GenerateTestReport -If {$GenerateTestReport} {
        
    Write-Build White "Generating additional test reports: $TestReportTypes"
    _GenerateTestReport `
        -ReportTypes $TestReportTypes `
        -OutputPath $CoverageDir `
        -IncludeAssemblyFilter $IncludeAssembliesInCodeCoverage `
        -ExcludeAssemblyFilter $ExcludeAssembliesInCodeCoverage
}

# Synopsis: Generates a Markdown code coverage summary report.
task GenerateMarkdownCodeCoverageSummary -If {$GenerateMarkdownCodeCoverageSummary} {
    Write-Build White "Generating Markdown code coverage summary"

    # Use the ReportGenerator tool to produce a Markdown summary of the code coverage
    $markdownReportType = $UseGitHubFlavour ? "MarkdownSummaryGitHub" : "MarkdownSummary"
    $markdownReportFilename = $UseGitHubFlavour ? "SummaryGithub.md" : "Summary.md"
    _GenerateTestReport `
        -ReportTypes $markdownReportType `
        -OutputPath $CoverageDir `
        -IncludeAssemblyFilter $IncludeAssembliesInCodeCoverage `
        -ExcludeAssemblyFilter $ExcludeAssembliesInCodeCoverage

    # Update the title so we can distinguish between reports across multiple test runs,
    # when they are published to GitHub as PR comments.
    $generatedReportPath = Join-Path $CoverageDir $markdownReportFilename
    if (Test-Path $generatedReportPath) {
        $generatedContent = Get-Content -Raw -Path $generatedReportPath
        $testRunOs = if ($IsLinux) { "Linux" } elseif ($IsMacOS) { "MacOS" } else { "Windows" }
        $tfmLabel = $TargetFrameworkMoniker ? $TargetFrameworkMoniker : "No TFM"
        $reportTitle = "# Code Coverage Summary Report - $testRunOs ($tfmLabel)"
        $retitledReport = $generatedContent -replace "^# Summary", $reportTitle
        
        Write-Build White "Updating generated code coverage report with title: $reportTitle"
        Set-Content -Path $generatedReportPath -Value $retitledReport -Encoding UTF8
    }
}

# Synopsis: Generates test coverage reports after .NET tests have been run.
task TestReport -If {!$SkipTestReport} `
    -Jobs GenerateTestReport,
            GenerateMarkdownCodeCoverageSummary\
