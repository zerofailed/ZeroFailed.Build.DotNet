# <copyright file="report.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Code Coverage Reporting Options

# Synopsis: When true, test reporting will be skipped.
$SkipTestReport ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_SKIP_TEST_REPORT $false))

# Synopsis: The wildcard expression used to find the Cobertura XML files produced by the test runner. Defaults to "coverage.*cobertura.xml".
$CodeCoverageFilenameGlob ??= property ZF_BUILD_DOTNET_COVERAGE_FILES_GLOB "coverage.*cobertura.xml"   # ensure we can find TFM-specific coverage files (e.g. coverage.net8.0.cobertura.xml)

# Synopsis: When true, runs the 'dotnet-reportgenerator-globaltool' to generate an XML test report. Defaults to true.
$GenerateTestReport ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_GENERATE_TEST_REPORT $true))

# Synopsis: When true, runs the 'dotnet-reportgenerator-globaltool' to generate a Markdown code coverage summary. Defaults to true.
$GenerateMarkdownCodeCoverageSummary ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_GENERATE_MARKDOWN_COVERAGE_REPORT $true))

# Synopsis: Allows the version of the 'dotnet-reportgenerator-globaltool' to be customised. Defaults to "5.3.8".
$ReportGeneratorToolVersion ??= "5.3.8"

# Synopsis: Allows the type of reports produced by the 'dotnet-reportgenerator-globaltool' to be customised. Defaults to "HtmlInline".
$TestReportTypes ??= property ZF_BUILD_DOTNET_TEST_REPORT_TYPES "HtmlInline"

# Synopsis: When true, TRX test results files will have 'Output' elements stripped to reduce their size. Useful when large files are too big to be parsed by XML libraries used by other CI/CD tools. Defaults to false.
$StripOutputFromLargeTrxFiles ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_STRIP_LARGE_TRX_FILES $false))

# Synopsis: The wildcard expression used to find TRX test results files to be stripped. Defaults to 'test-results_*.trx'.
$TestResultTrxFilesGlob ??= property ZF_BUILD_DOTNET_TRX_FILES_GLOB "test-results_*.trx"

# Synopsis: When true, Markdown code coverage reports larger than 'TruncateOversizedCoverageReportThreshold' will be truncated. Useful when the Markdown is uploaded to systems that impose size limits (e.g. GitHub PR comments). Defaults to false.
$TruncateOversizedCoverageReport ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_TRUNCATE_LARGE_COVERAGE_MARKDOWN $false))

# Synopsis: The threshold for Markdown code coverage reports (as a character count), above which it will be truncated. Defaults to 60000 characters.
$TruncateOversizedCoverageReportThreshold ??= 60000