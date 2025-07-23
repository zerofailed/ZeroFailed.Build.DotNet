# <copyright file="test.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

. $PSScriptRoot/test.properties.ps1

# Synopsis: Run .NET solution tests with 'dotnet-coverage' to collect code coverage
task RunTestsWithDotNetCoverage -If {$SolutionToBuild} {
    # Setup the appropriate CI/CD platform test logger, unless explicitly disabled
    if (!$DisableCicdServerLogger) {
        if ($script:IsAzureDevOps) {
            Write-Build Green "Configuring Azure Pipelines test logger"
            $script:DotNetTestLoggers += "AzurePipelines"
        }
        elseif ($script:IsGitHubActions) {
            Write-Build Green "Configuring GitHub Actions test logger"
            $script:DotNetTestLoggers += "GitHubActions"
        }    
    }

    # Evaluate the file logger properties so we can pass them to 'dotnet test'
    $_fileLoggerProps = Resolve-Value $DotNetTestFileLoggerProps

    # Use InvokeBuild's built-in $Task variable to know where this file is installed and use it to 
    # derive where the root of the module must be.  This method will work when this module has
    # been directly imported as well as when it is used as a ZeroFailed extension.
    $moduleDir = Split-Path -Parent (Split-Path -Parent $Task.InvocationInfo.ScriptName)
    Write-Verbose "ModuleDir: $moduleDir"

    # Setup the arguments we need to pass to 'dotnet test'
    $dotnetTestArgs = @(
        "--configuration", $Configuration
        "--no-build"
        "--no-restore"
        "--verbosity", $LogLevel
        "--test-adapter-path", (Join-Path $moduleDir "bin")
        ($_fileLoggerProps ? $_fileLoggerProps : "/fl")
    )

    # Configure any test loggers that have been specified
    $DotNetTestLoggers | ForEach-Object {
        $dotnetTestArgs += @("--logger", $_)
    }

    $coverageOutput = "coverage{0}.cobertura.xml" -f ($TargetFrameworkMoniker ? ".$TargetFrameworkMoniker" : "")
    if ($TargetFrameworkMoniker) {
        $dotnetTestArgs += @("--framework", $TargetFrameworkMoniker)
    }
    Remove-Item $coverageOutput -ErrorAction Ignore -Force
    $dotnetCoverageArgs = @(
        "collect"
        "-o", $coverageOutput
        "-f", "cobertura"
    )

    # Ensure the dotnet-coverage global tool is installed, as we need it to collect the code coverage data
    Install-DotNetTool -Name "dotnet-coverage" -Global

    # Add any custom test arguments that have been specified
    if ($AdditionalTestArgs) {
        $dotnetTestArgs += $AdditionalTestArgs
    }

    $dotnetCoverageArgs += @(
        "dotnet"
        "test"
    )
    Write-Verbose "CmdLine: $dotnetCoverageArgs $SolutionToBuild $dotnetTestArgs" -Verbose
    try {
        exec { 
            & dotnet-coverage @dotnetCoverageArgs $SolutionToBuild @dotnetTestArgs
        }

        # Only generate code coverage reports if the tests passed
        if (!$SkipTestReport -and (Test-Path $coverageOutput)) {
            if ($GenerateTestReport) {
                Write-Build White "Generating additional test reports: $TestReportTypes"
                _GenerateTestReport `
                    -ReportTypes $TestReportTypes `
                    -OutputPath $CoverageDir `
                    -IncludeAssemblyFilter $IncludeAssembliesInCodeCoverage `
                    -ExcludeAssemblyFilter $ExcludeAssembliesInCodeCoverage
            }
            if ($GenerateMarkdownCodeCoverageSummary) {
                Write-Build White "Generating Markdown code coverage summary"
                _GenerateCodeCoverageMarkdownReport `
                    -UseGitHubFlavour $IsGitHubActions `
                    -TargetFrameworkMoniker $TargetFrameworkMoniker `
                    -OutputPath $CoverageDir `
                    -IncludeAssemblyFilter $IncludeAssembliesInCodeCoverage `
                    -ExcludeAssemblyFilter $ExcludeAssembliesInCodeCoverage
            }
        }
    }
    finally {
        if ((Test-Path $DotNetTestLogFile) -and $IsAzureDevOps) {
            Write-Host "##vso[artifact.upload artifactname=logs]$((Resolve-Path $DotNetTestLogFile).Path)"
        }
    }
}

task RunDotNetTests `
        -If {!$SkipTest -and !$SkipDotNetTests} `
        -After TestCore `
        RunTestsWithDotNetCoverage
