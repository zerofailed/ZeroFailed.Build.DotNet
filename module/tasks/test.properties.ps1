# <copyright file="test.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Testing & Coverage Options

# Synopsis: When true, the .NET test functionality will be skipped.
$SkipDotNetTests = $false

# Synopsos: The wildcard expression used to find the Cobertura XML files produced by the test runner. Defaults to "coverage.*cobertura.xml".
$CodeCoverageFilenameGlob = "coverage.*cobertura.xml"   # ensure we can find TFM-specific coverage files (e.g. coverage.net8.0.cobertura.xml)

# Synopsis: Allows arbitrary arguments to be passed to 'dotnet test'.
$AdditionalTestArgs = @()

# Synopsis: Optionally specify the target framework moniker to use when running tests.
$TargetFrameworkMoniker = ""

# Synopsis: An optional wildcard expression filter for assemblies that should be included in the code coverage report. Defaults to no filter.
$IncludeAssembliesInCodeCoverage = ""                # used by 'dotnet-reportgeneator' global tool

# Synopsis: An optional wildcard expression filter for assemblies that should be excluded from the code coverage report. Defaults to no filter.
$ExcludeAssembliesInCodeCoverage = ""                # used by 'dotnet-reportgeneator' global tool

# Synopsis: When true, runs the 'dotnet-reportgenerator-globaltool' to generate an XML test report. Defaults to true.
$GenerateTestReport = $true

# Synopsis: When true, runs the 'CodeCoverageSummary' global tool to generate a Markdown code coverage summary. Defaults to true.
$GenerateMarkdownCodeCoverageSummary = $true

# Synopsis: Allows the version of the 'dotnet-reportgenerator-globaltool' to be customised. Defaults to "5.3.8".
$ReportGeneratorToolVersion = "5.3.8"

# Synopsis: Allows the type of reports produced by the 'dotnet-reportgenerator-globaltool' to be customised. Defaults to "HtmlInline".
$TestReportTypes ??= "HtmlInline"

# Synopsis: Sets the default '--logger' configuration passed to 'dotnet test'.
$DotNetTestLoggers = @(
    "console;verbosity=$LogLevel"
    "trx;LogFilePrefix=test-results"
)

# Synopsis: When true, the CI/CD-specific loggers will not be used (e.g. Azure DevOps, GitHub Actions)
$DisableCicdServerLogger = $false

# Synopsis: The path to the MSBuild log file produced when running tests via 'dotnet test'. Defaults to "dotnet-test.log".
$DotNetTestLogFile = "dotnet-test.log"

# Synopsis: Allow the file logger properties used when running tests via 'dotnet test' to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetTestLogFile>". Supports lazy evaluation.
$DotNetTestFileLoggerProps = "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetTestLogFile"
