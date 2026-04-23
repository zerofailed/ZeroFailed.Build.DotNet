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

# Synopsis: Handles the scenario where the generated .trx result file would be too large to parse by certain XML libraries
task StripOutputFromLargeTrxFiles -If {$StripOutputFromLargeTrxFiles} {
    # TRX files from large test suites can exceed parsing limits for certain XML libraries, including those used by
    # test result publishers for CI/CD platforms (.e.g The 'publish-unit-test-result-action' GitHub Action).
    # Additionally, such large files can be susceptible to corruption if the test runner terminates unexpectedly.

    Write-Build White "Searching for TRX files to truncate: $TestResultTrxFilesGlob"
    Get-ChildItem -Path $SourcesDir -Filter $TestResultTrxFilesGlob -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {
            $file = $_
            $sizeMB = [math]::Round($_.Length / 1MB, 1)
            Write-Build White "StripOutputFromLargeTrxFiles: processing $($file.FullName) ($sizeMB MB)"
            try {
                $content = [System.IO.File]::ReadAllText($file.FullName)
                # Strip all <Output> blocks — covers StdOut, ErrorInfo, StackTrace.
                # The publish action only needs pass/fail/skip status, not output text.
                $stripped = [regex]::Replace(
                    $content,
                    '<Output>.*?</Output>',
                    '',
                    [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($stripped.Length -ne $content.Length) {
                    [System.IO.File]::WriteAllText($file.FullName, $stripped)
                    $newSizeMB = [math]::Round((Get-Item $file.FullName).Length / 1MB, 1)
                    Write-Build White "  Stripped output: $sizeMB MB -> $newSizeMB MB"
                }
                # Validate the TRX file is well-formed XML
                [xml]([System.IO.File]::ReadAllText($file.FullName)) | Out-Null
                Write-Verbose "  XML valid"
            }
            catch {
                Write-Build Yellow "  TRX file is invalid or unprocessable, removing: $file"
                Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
            }
        }
}

# Synopsis: Handles the scenario where the generated code coverage markdown file would be too big for a GitHub PR comment
task TruncateOversizedCoverageReport -If {$TruncateOversizedCoverageReport} {
    # GitHub PR comments have a 65536 character limit. The coverage summary for this
    # solution often exceeds that. Truncate and append a note when too large.
    # The SummaryGithub.md is generated inside RunTestsWithDotNetCoverage (before
    # PostTest), so it exists at this point.
    $summaryPath = Join-Path $CoverageDir "SummaryGithub.md"
    $maxChars = 60000  # leave headroom for sticky-comment wrapper
    if (Test-Path $summaryPath) {
        $content = Get-Content -Raw -Path $summaryPath
        if ($content.Length -gt $maxChars) {
            $originalLen = $content.Length
            $truncated = $content.Substring(0, $maxChars)
            # Cut at last newline to avoid splitting a table row
            $lastNl = $truncated.LastIndexOf("`n")
            if ($lastNl -gt 0) { $truncated = $truncated.Substring(0, $lastNl) }
            $truncated += "`n`n---`n> **Note:** Coverage summary truncated from $originalLen to $($truncated.Length) characters. Full report is in the build artifacts.`n"
            Set-Content -Path $summaryPath -Value $truncated -Encoding UTF8 -NoNewline
            Write-Verbose "TruncateOversizedCoverageReport: truncated $summaryPath from $originalLen to $($truncated.Length) chars"
        }
    }
}

# Synopsis: Generates test coverage reports after .NET tests have been run.
task TestReport -If {!$SkipTestReport} `
    -Jobs GenerateTestReport,
            GenerateMarkdownCodeCoverageSummary,
            StripOutputFromLargeTrxFiles,
            GenerateMarkdownCodeCoverageSummary
