# <copyright file="test.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

. $PSScriptRoot/test.properties.ps1

# Synopsis: Run .NET solution tests with 'dotnet-coverage' to collect code coverage
task RunTestsWithDotNetCoverage -If {$SolutionToBuild} {

    # Detect Microsoft Testing Platform (MTP) usage
    $isMtp = $false
    try {
        # Rather than re-implement all the detection logic ourselves with respect to
        # locating a valid global.json etc., we simply rely on 'dotnet test' to do 
        # this for us.  When detecting a solution or project using the old testing
        # platform it outputs a different message to reflect how it will interpret
        # any command-line parameters passed to it.
        $helpOutput = & dotnet test $SolutionToBuild --help 2>&1 | Out-String
        if ($helpOutput -match "\.NET Test Command for Microsoft\.Testing\.Platform") {
            $isMtp = $true
            Write-Build White "Microsoft Testing Platform detected."
        }
        else {
            Write-Build White "VSTest detected."
        }
    }
    catch {
        Write-Build Yellow "Failed to detect testing platform via help command: $($_.Exception.Message)`nAssuming VSTest."
    }

    # Deferred evaluation of logger defaults, since these depend on which test platform is being used
    $_resolvedLoggers = Resolve-Value $DotNetTestLoggers

    # Setup the appropriate CI/CD platform test logger, unless explicitly disabled (or using MTP)
    if (!$isMtp -and !$DisableCicdServerLogger) {
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
    )

    if ($isMtp) {
        $dotnetTestArgs += _GetDotNetTestParamsForMtp
    }
    else {
        $dotnetTestArgs += _GetDotNetTestParamsForVsTest
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

    Write-Verbose "CmdLine: $dotnetCoverageArgs $dotnetTestArgs" -Verbose
    try {
        exec { 
            & dotnet-coverage @dotnetCoverageArgs @dotnetTestArgs
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
