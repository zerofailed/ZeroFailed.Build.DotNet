# <copyright file="test.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Testing Options

# Synopsis: When true, the .NET test functionality will be skipped.
$SkipDotNetTests ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_SKIP_TESTS $false))

# Synopsis: Allows arbitrary arguments to be passed to 'dotnet test'.
$AdditionalTestArgs ??= @()

# Synopsis: Optional path to a dotnet-coverage settings file. When set, it will be passed to 'dotnet-coverage collect' via '-s'.
$DotNetCoverageSettingsFile ??= ""

# Synopsis: Optionally specify the target framework moniker to use when running tests.
$TargetFrameworkMoniker ??= ""

# Synopsis: The directory where 'dotnet test' result (.trx) files are written. When empty (the default), each test project writes to its own 'TestResults' folder next to its build output. Set to a path (relative paths are resolved against the repo root) to collect every project's results in a single shared directory.
$DotNetTestResultsDir ??= property ZF_BUILD_DOTNET_TEST_RESULTS_DIR ""
if ($DotNetTestResultsDir -and -not [IO.Path]::IsPathRooted($DotNetTestResultsDir)) {
    $DotNetTestResultsDir = Join-Path $here $DotNetTestResultsDir
}

# Synopsis: Sets the default 'logger' configuration passed to 'dotnet test'.
$DotNetTestLoggers ??= @(
    "console;verbosity=$LogLevel"
    "trx;LogFilePrefix=test-results"
)

# Synopsis: When true, the CI/CD-specific loggers will not be used (e.g. Azure DevOps, GitHub Actions)
$DisableCicdServerLogger ??= $false

# Synopsis: The path to the MSBuild log file produced when running tests via 'dotnet test'. Defaults to "dotnet-test.log".
$DotNetTestLogFile ??= "dotnet-test.log"

# Synopsis: The file logger properties passed to 'dotnet test' when using the VSTest platform. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetTestLogFile>". Supports lazy evaluation.
$DotNetTestFileLoggerProps_VSTest ??= { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetTestLogFile" }

# Synopsis: The diagnostic logging arguments passed to 'dotnet test' when using the Microsoft Testing Platform. Defaults to enabling the MTP diagnostic file logger, with a verbosity derived from 'DotNetFileLoggerVerbosity' and the '.diag' files written to the repo root. Supports lazy evaluation.
$DotNetTestFileLoggerProps_MTP ??= {
    @(
        '--diagnostic'
        '--diagnostic-verbosity'
        $(switch ($DotNetFileLoggerVerbosity) {
            'quiet' { 'Critical' }
            'minimal' { 'Error' }
            'normal' { 'Warning' }
            'detailed' { 'Information' }
            'diagnostic' { 'Trace' }
            default {
                Write-Host -f Yellow "Unexpected DotNetFileLoggerVerbosity value '$DotNetFileLoggerVerbosity'. Defaulting to 'Warning'."
                'Warning'
            }
        })
        # NOTE: No log file prefix is specified. The option was renamed in MTP 2.0 ('--diagnostic-output-fileprefix'
        #       became '--diagnostic-file-prefix') and each version rejects the other's spelling with exit code 5,
        #       which 'dotnet test' reports as "Zero tests ran". Omitting it works with both MTP 1.x and 2.x hosts,
        #       and MTP's default naming (e.g. '<asm>_<tfm>_<arch>_<timestamp>.diag' on 2.x) already yields a
        #       distinct file per test project.
        '--diagnostic-output-directory'
        $here
    )
}

# Synopsis: Allow the file logger properties used when running tests via 'dotnet test' to be customised. Defaults to 'DotNetTestFileLoggerProps_VSTest' or 'DotNetTestFileLoggerProps_MTP', depending on the test platform detected. Supports lazy evaluation.
$DotNetTestFileLoggerProps ??= {
    if ($isMtp) {
        Resolve-Value $DotNetTestFileLoggerProps_MTP
    }
    else {
        Resolve-Value $DotNetTestFileLoggerProps_VSTest
    }
}