# <copyright file="report.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Code Coverage Reporting Options

# Synopsis: When true, test reporting will be skipped.
$SkipTestReport = $false

# Synopsis: The wildcard expression used to find the Cobertura XML files produced by the test runner. Defaults to "coverage.*cobertura.xml".
$CodeCoverageFilenameGlob = "coverage.*cobertura.xml"   # ensure we can find TFM-specific coverage files (e.g. coverage.net8.0.cobertura.xml)

# Synopsis: When true, runs the 'dotnet-reportgenerator-globaltool' to generate an XML test report. Defaults to true.
$GenerateTestReport = $true

# Synopsis: When true, runs the 'dotnet-reportgenerator-globaltool' to generate a Markdown code coverage summary. Defaults to true.
$GenerateMarkdownCodeCoverageSummary = $true

# Synopsis: Allows the version of the 'dotnet-reportgenerator-globaltool' to be customised. Defaults to "5.3.8".
$ReportGeneratorToolVersion = "5.3.8"

# Synopsis: Allows the type of reports produced by the 'dotnet-reportgenerator-globaltool' to be customised. Defaults to "HtmlInline".
$TestReportTypes ??= "HtmlInline"
