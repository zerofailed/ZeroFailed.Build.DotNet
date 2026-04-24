# <copyright file="report.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

. $PSScriptRoot/report.properties.ps1

# Synopsis: Configures the core set of reportgenerator command-line arguments
task PrepareTestReportParameters {
    # Handle the legacy format for the assembly filter properties, where they were passed
    # as a single string, with the user having to handle the formatting when specifying
    # multiple filters (e.g. 'MyAssembly*;+MyOtherAssembly')
    if ($IncludeAssembliesInCodeCoverage -imatch ';') {
        $IncludeAssembliesInCodeCoverage = $IncludeAssembliesInCodeCoverage -split ';' | ForEach-Object { $_.TrimStart('+') }
        Write-Build Yellow "Migrated legacy IncludeAssembliesInCodeCoverage: $IncludeAssembliesInCodeCoverage"
    }
    if ($ExcludeAssembliesInCodeCoverage -imatch ';') {
        $ExcludeAssembliesInCodeCoverage = $ExcludeAssembliesInCodeCoverage -split ';' | ForEach-Object { $_.TrimStart('-') }
        Write-Build Yellow "Migrated legacy ExcludeAssembliesInCodeCoverage: $ExcludeAssembliesInCodeCoverage"
    }

    $script:ReportGeneratorSplat = @{
        BasePath = $SourcesDir
        OutputPath = $CoverageDir
        IncludeAssemblyFilters = $IncludeAssembliesInCodeCoverage
        ExcludeAssemblyFilters = $ExcludeAssembliesInCodeCoverage
        IncludeFileFilters = $IncludeFilesInCodeCoverage
        ExcludeFileFilters = $ExcludeFilesInCodeCoverage
        AdditionalArgs = $ReportGeneratorAdditionalArgs
    }
}

# Synopsis: Generates additional test reports using 'dotnet-reportgenerator-globaltool'.
task GenerateTestReport -If {$GenerateTestReport} PrepareTestReportParameters,{
    Write-Build White "Generating additional test reports: $TestReportTypes"
    _GenerateTestReport @ReportGeneratorSplat -ReportTypes $TestReportTypes
}

# Synopsis: Generates a Markdown code coverage summary report.
task GenerateMarkdownCodeCoverageSummary -If {$GenerateMarkdownCodeCoverageSummary} PrepareTestReportParameters,{
    Write-Build White "Generating Markdown code coverage summary"

    # Use the ReportGenerator tool to produce a Markdown summary of the code coverage
    $markdownReportType = $UseGitHubFlavour ? "MarkdownSummaryGitHub" : "MarkdownSummary"
    $markdownReportFilename = $UseGitHubFlavour ? "SummaryGithub.md" : "Summary.md"

    _GenerateTestReport @ReportGeneratorSplat -ReportTypes $markdownReportType

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

# Synopsis: Handles the scenario where the generated .trx result file would be too large to parse by certain XML libraries.
task StripOutputFromLargeTrxFiles -If {$StripOutputFromLargeTrxFiles} {
    # TRX files from large test suites can exceed parsing limits for certain XML libraries, including those used by
    # test result publishers for CI/CD platforms (.e.g The 'publish-unit-test-result-action' GitHub Action).
    # Additionally, such large files can be susceptible to corruption if the test runner terminates unexpectedly.

    Write-Build White "Searching for TRX files to truncate: $TestResultTrxFilesGlob"
    Get-ChildItem -Path $SourcesDir -Filter $TestResultTrxFilesGlob -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {
            $file = $_
            $sizeMB = [math]::Round($_.Length / 1MB, 1)
            if ($sizeMB -lt 5) {
                Write-Verbose "StripOutputFromLargeTrxFiles: $($file.Name) ($sizeMB MB) — small, skipping"
                return
            }
            Write-Build White "StripOutputFromLargeTrxFiles: processing $($file.FullName) ($sizeMB MB)"
            try {
                $tempPath = "$($file.FullName).stripped"
                $inOutput = $false
                $linesStripped = 0
                $reader = [System.IO.StreamReader]::new($file.FullName)
                $writer = [System.IO.StreamWriter]::new($tempPath)
                try {
                    while ($null -ne ($line = $reader.ReadLine())) {
                        # Handle single-line <Output>...</Output>
                        if (-not $inOutput -and $line -match '<Output>' -and $line -match '</Output>') {
                            # Strip the Output block but keep surrounding content on the same line
                            $stripped = $line -replace '<Output>.*?</Output>', ''
                            if ($stripped.Trim()) {
                                $writer.WriteLine($stripped)
                            }
                            $linesStripped++
                            continue
                        }
                        # Multi-line: entering <Output> block
                        if (-not $inOutput -and $line -match '<Output>') {
                            $inOutput = $true
                            $linesStripped++
                            continue
                        }
                        # Multi-line: exiting </Output> block
                        if ($inOutput -and $line -match '</Output>') {
                            $inOutput = $false
                            $linesStripped++
                            continue
                        }
                        # Inside multi-line Output block: skip
                        if ($inOutput) {
                            $linesStripped++
                            continue
                        }
                        $writer.WriteLine($line)
                    }
                }
                finally {
                    $reader.Close()
                    $writer.Close()
                }

                if ($linesStripped -gt 0) {
                    Move-Item -Path $tempPath -Destination $file.FullName -Force
                    $newSizeMB = [math]::Round((Get-Item $file.FullName).Length / 1MB, 1)
                    Write-Build White "  Stripped output: $sizeMB MB -> $newSizeMB MB"
                }
                else {
                    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                    Write-Build White "  No Output blocks found"
                }
            }
            catch {
                Write-Build Yellow "  Error processing TRX: $file"
                Remove-Item "$($file.FullName).stripped" -Force -ErrorAction SilentlyContinue
            }
        }
}

# Synopsis: Handles the scenario where the generated code coverage markdown file would be too big for a GitHub PR comment.
task TruncateOversizedCoverageReport -If {$TruncateOversizedCoverageReport -and $GenerateMarkdownCodeCoverageSummary} {
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

# Synopsis: Generates test coverage reports after tests have been run.
task TestReport -If {!$SkipTestReport} `
    -Jobs GenerateTestReport,
            GenerateMarkdownCodeCoverageSummary,
            StripOutputFromLargeTrxFiles,
            TruncateOversizedCoverageReport
