# <copyright file="_GenerateCodeCoverageMarkdownReport.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>


<#
.SYNOPSIS
  Generates a Markdown code coverage report from Cobertura XML files.

.DESCRIPTION
  Uses the ReportGenerator tool (via _GenerateTestReport) to produce a Markdown summary of code coverage.
  Updates the report title with the operating system and target framework for distinction between multiple
  test runs.

.PARAMETER UseGitHubFlavour
  A boolean value indicating if the GitHub-flavoured report should be used.
  If true, generates a GitHub Actions specific Markdown report.

.PARAMETER TargetFrameworkMoniker
  The target framework identifier for the test run.
  If not provided, defaults to 'No TFM' in the report title.

.PARAMETER CoverageDir
  The directory where the code coverage report is generated.

.EXAMPLE
  _GenerateCodeCoverageMarkdownReport -UseGitHubFlavour $true -TargetFrameworkMoniker ".NET 6.0" -CoverageDir "C:\Coverage"
  Generates a Markdown code coverage report with GitHub-specific formatting.
#>
function _GenerateCodeCoverageMarkdownReport {
    param(
        [Parameter()]
        [bool]$UseGitHubFlavour,

        [Parameter()]
        [string]$TargetFrameworkMoniker,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter()]
        [string] $IncludeAssemblyFilter = "",

        [Parameter()]
        [string] $ExcludeAssemblyFilter = ""   
    )
    # Use the ReportGenerator tool to produce a Markdown summary of the code coverage
    $markdownReportType = $UseGitHubFlavour ? "MarkdownSummaryGitHub" : "MarkdownSummary"
    $markdownReportFilename = $UseGitHubFlavour ? "SummaryGithub.md" : "Summary.md"
    _GenerateTestReport `
        -ReportTypes $markdownReportType `
        -OutputPath $OutputPath `
        -IncludeAssemblyFilter $IncludeAssembliesInCodeCoverage `
        -ExcludeAssemblyFilter $ExcludeAssembliesInCodeCoverage

    # Update the title so we can distinguish between reports across multiple test runs,
    # when they are published to GitHub as PR comments.
    $generatedReportPath = Join-Path -Resolve $CoverageDir $markdownReportFilename
    $generatedContent = Get-Content -Raw -Path $generatedReportPath
    $testRunOs = if ($IsLinux) { "Linux" } elseif ($IsMacOS) { "MacOS" } else { "Windows" }
    $tfmLabel = $TargetFrameworkMoniker ? $TargetFrameworkMoniker : "No TFM"
    $reportTitle = "# Code Coverage Summary Report - $testRunOs ($tfmLabel)"
    $retitledReport = $generatedContent -replace "^# Summary", $reportTitle
    
    Write-Build White "Updating generated code coverage report with title: $reportTitle"
    Set-Content -Path $generatedReportPath -Value $retitledReport -Encoding UTF8
}