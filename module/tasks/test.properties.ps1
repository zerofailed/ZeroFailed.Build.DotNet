# <copyright file="test.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Testing Options

# Synopsis: When true, the .NET test functionality will be skipped.
$SkipDotNetTests ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_SKIP_TESTS $false))

# Synopsis: Allows arbitrary arguments to be passed to 'dotnet test'.
$AdditionalTestArgs ??= @()

# Synopsis: Optionally specify the target framework moniker to use when running tests.
$TargetFrameworkMoniker ??= ""

# Synopsis: Sets the default 'logger' configuration passed to 'dotnet test'.
$DotNetTestLoggers ??= @(
    "console;verbosity=$LogLevel"
    "trx;LogFilePrefix=test-results"
)

# Synopsis: When true, the CI/CD-specific loggers will not be used (e.g. Azure DevOps, GitHub Actions)
$DisableCicdServerLogger ??= $false

# Synopsis: The path to the MSBuild log file produced when running tests via 'dotnet test'. Defaults to "dotnet-test.log".
$DotNetTestLogFile ??= "dotnet-test.log"

$DotNetTestFileLoggerProps_VSTest ??= "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetTestLogFile"
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
        '--diagnostic-output-fileprefix'
        'dotnet-test'
        '--diagnostic-output-directory'
        $here
    )
}
# Synopsis: Allow the file logger properties used when running tests via 'dotnet test' to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetTestLogFile>". Supports lazy evaluation.
$DotNetTestFileLoggerProps ??= {
    if ($isMtp) {
        Resolve-Value $DotNetTestFileLoggerProps_MTP
    }
    else {
        Resolve-Value $DotNetTestFileLoggerProps_VSTest
    }
}