# <copyright file="package.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

. $PSScriptRoot/package.properties.ps1

# Template project file used when building .nuspec files with no associated project
$templateProjectForNuSpecBuild = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <NuspecFile>{0}</NuspecFile>
    <NuspecProperties></NuspecProperties>
    <NuspecBasePath></NuspecBasePath>
    <NoBuild>true</NoBuild>
    <GeneratePackageOnBuild>true</GeneratePackageOnBuild>
    <SkipCompilerExecution>true</SkipCompilerExecution>
    <CopyBuildOutputToOutputDirectory>false</CopyBuildOutputToOutputDirectory>
    <NoWarn>NU5110;NU5111</NoWarn>
  </PropertyGroup>
</Project>
"@

# Synopsis: Build the NuGet packages configured in the .NET solution
task BuildNuGetPackages -If {!$SkipNuGetPackages -and $SolutionToBuild} -After PackageCore Version,EnsurePackagesDir,{
    exec {
        try {
            # Evaluate the file logger properties so we can pass them to 'dotnet pack'
            $_fileLoggerProps = Resolve-Value $DotNetPackageFileLoggerProps

            # Change use of '--output' - ref: https://github.com/dotnet/sdk/issues/30624#issuecomment-1432118204
            dotnet pack $SolutionToBuild `
                        --configuration $Configuration `
                        --no-build `
                        --no-restore `
                        /p:PackageOutputPath="$PackagesDir" `
                        /p:EndjinRepositoryUrl="$BuildRepositoryUri" `
                        /p:PackageVersion="$(($script:GitVersion).SemVer)" `
                        --verbosity $LogLevel `
                        $($_fileLoggerProps ? $_fileLoggerProps : "/fl")
        }
        finally {
            if ((Test-Path $DotNetPackageLogFile) -and $IsAzureDevOps) {
                Write-Host "##vso[artifact.upload artifactname=logs]$((Resolve-Path $DotNetPackageLogFile).Path)"
            }
        }
    }
}

# Synopsis: Build publish packages for projects specified in 'ProjectsToPublish'
task BuildProjectPublishPackages -If {!$SkipProjectPublishPackages -and $ProjectsToPublish} -After PackageCore Version,EnsurePackagesDir,{
    # Remove the existing log, since we append to it for each project being published
    Get-Item $DotNetPublishLogFile -ErrorAction Ignore | Remove-Item -Force

    # Check each entry to see whether it is using the older or newer configuration style
    $projectPublishingTasks = $ProjectsToPublish | % {
        if ($_ -is [Hashtable]) {
            # New style config: just use whatever has been specified
            $_
        }
        else {
            # Old style config: generate a configuration that will mimic the previous behaviour
            @{ Project = $_; RuntimeIdentifiers = @('NOT_SPECIFIED'); SelfContained = $false; Trimmed = $false; ReadyToRun = $false }
        }
    }

    try {
        # Evaluate the file logger properties so we can pass them to 'dotnet publish'
        $_fileLoggerProps = Resolve-Value $DotNetPublishFileLoggerProps

        foreach ($task in $projectPublishingTasks) {

            foreach ($runtime in $task.RuntimeIdentifiers) {

                $optionalCmdArgs = @()
                if ($task.ContainsKey("Trimmed") -and $task.Trimmed -eq $true) { $optionalCmdArgs += "-p:PublishTrimmed=true" }
                if ($task.ContainsKey("ReadyToRun") -and $task.ReadyToRun -eq $true) { $optionalCmdArgs += "-p:PublishReadyToRun=true" }
                if ($task.ContainsKey("SingleFile") -and $task.SingleFile -eq $true) { $optionalCmdArgs += "-p:PublishSingleFile=true" }

                if ($runtime -eq "NOT_SPECIFIED") {
                    # If no runtime is specified then we can skip the build
                    $optionalCmdArgs += "--no-build"
                }
                else {
                    # Specify the required runtime
                    $optionalCmdArgs += "--runtime",$runtime
                    # When specifying a runtime, you need to explicitly flag it as self-contained or not
                    $optionalCmdArgs += (($task.ContainsKey("SelfContained") -and $task.SelfContained -eq $true) ? "--self-contained" : "--no-self-contained")
                }

                Write-Build Green "Publishing Project: $($task.Project) [$($runtime)] [SelfContained=$($task.SelfContained)] [SingleFile=$($task.SingleFile)] [Trimmed=$($task.Trimmed)] [ReadyToRun=$($task.ReadyToRun)]"
                $packageOutputDir = Join-Path $PackagesDir $(Split-Path -LeafBase $task.Project) ($runtime -eq "NOT_SPECIFIED" ? "" : $runtime)
                exec {
                    # Change use of '--output' - ref: https://github.com/dotnet/sdk/issues/30624#issuecomment-1432118204
                    dotnet publish $task.Project `
                                --nologo `
                                --configuration $Configuration `
                                --no-restore `
                                /p:PublishDir="$packageOutputDir" `
                                /p:EndjinRepositoryUrl="$BuildRepositoryUri" `
                                /p:PackageVersion="$(($script:GitVersion).SemVer)" `
                                --verbosity $LogLevel `
                                @optionalCmdArgs `
                                $($_fileLoggerProps ? $_fileLoggerProps : "/fl")
                }
            }
        }
    }
    finally {
        if ((Test-Path $DotNetPublishLogFile) -and $IsAzureDevOps) {
            Write-Host "##vso[artifact.upload artifactname=logs]$((Resolve-Path $DotNetPublishLogFile).Path)"
        }
    }
}

# Synopsis: Build NuGet packages for the .nuspec files specified in 'NuspecFilesToPackage'
task BuildNuSpecPackages -If {!$SkipNuspecPackages -and $NuspecFilesToPackage} -After PackageCore Version,EnsurePackagesDir,{

    # Evaluate the file logger properties so we can pass them to 'dotnet pack'
    $_fileLoggerProps = Resolve-Value $DotNetPackageNuSpecFileLoggerProps
    
    foreach ($nuspec in $NuSpecFilesToPackage) {

        # Assumes a convention that the .nuspec file is alongside the .csproj file with a matching name
        $nuspecFilePath = [IO.Path]::IsPathRooted($nuspec) ? $nuspec : (Join-Path $here $nuspec)
        $projectFilePath = $nuspecFilePath.Replace(".nuspec", ".csproj")

        $generatedTempProjectFile = $false
        if (!(Test-Path $projectFilePath)) {
            Write-Build White "Generating temporary project file for NuSpec: $nuspecFilePath"
            Set-Content -Path $projectFilePath -Value ($templateProjectForNuSpecBuild -f (Split-Path -Leaf $nuspec))
            $generatedTempProjectFile = $true
        }

        Write-Build Green "Packaging NuSpec: $nuspecFilePath [Project=$projectFilePath]"

        $packArgs = @(
            "--nologo"
            $projectFilePath
            "--configuration"
            $Configuration
            # ref: https://github.com/dotnet/sdk/issues/30624#issuecomment-1432118204
            "-p:PackageOutputPath=$PackagesDir"
            # this property needs to be overridden as its default value should be 'false', to ensure that the project
            # is not built by the 'PublishNuGetPackages' task.
            "-p:IsPackable=true"
            "-p:NuspecFile=$nuspecFilePath"
            "-p:NuspecProperties=version=`"$(($script:GitVersion).SemVer)`""
            "--verbosity"
            $LogLevel
            $($_fileLoggerProps ? $_fileLoggerProps : "/fl")
        )

        # When building a .nuspec file using the temporary generated project file, we need to ensure that
        # the project is restored & built, as it won't have been done by the earlier tasks.
        if (!$generatedTempProjectFile) {
            $packArgs += "--no-build"
            $packArgs += "--no-restore"
        }

        Write-Verbose "dotnet pack $packArgs"
        exec {
            & dotnet pack $packArgs
        }

        if ($generatedTempProjectFile) {
            Write-Build White "Removing temporary project file"
            Remove-Item -Path $projectFilePath
        }
    }
}
