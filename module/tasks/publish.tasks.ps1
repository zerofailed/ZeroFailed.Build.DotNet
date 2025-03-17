# <copyright file="publish.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

. $PSScriptRoot/publish.properties.ps1

# Synopsis: Publish any built NuGet packages
task PublishNuGetPackages `
    -If {!$SkipNuGetPackages -and $SolutionToBuild -and $NugetPackageNamesToPublishGlob} `
    -After PublishCore `
    Version,EnsurePackagesDir,{

    # Support for lazy evaluation of the glob used to select NuGet packages to publish
    $evaluatedNugetPackagesToPublishGlob = Resolve-Value $NugetPackageNamesToPublishGlob
    Write-Verbose "EvaluatedNugetPackagesToPublishGlob: $evaluatedNugetPackagesToPublishGlob"
    $nugetPackagesToPublish = Get-ChildItem -Path $PackagesDir -Filter $evaluatedNugetPackagesToPublishGlob
    Write-Verbose "NugetPackagesToPublish: $nugetPackagesToPublish"

    # Derive the NuGet API key to use - this also makes it easier to mask later on
    # NOTE: Where NuGet auth has been setup beforehand (e.g. via a SOURCE), an API key still needs to be specified but it can be any value
    $nugetApiKey = $env:NUGET_API_KEY ? $env:NUGET_API_KEY : "no-key"
    if (([uri]$NugetPublishSource).scheme -ne 'file' -and $nugetApiKey -eq "no-key") {
        Write-Warning "No value was found in the 'NUGET_API_KEY' environment variable, publishing may fail unless an explicit NuGet 'source' has been pre-configured."
    }

    # Setup the 'dotnet nuget push' command-line parameters that will be the same for each package
    $nugetPushArgs = @(
        "-s"
        $NugetPublishSource
        "--api-key"
        $nugetApiKey
    )

    if ($NugetPublishSkipDuplicates) {
        $nugetPushArgs += @(
            "--skip-duplicate"
        )
    }

    # Ensure that the path exists when using a file-system based NuGet source
    if ((Test-Path $NugetPublishSource -IsValid) -and !(Test-Path $NugetPublishSource)) {
        Write-Build White "Creating NuGet publish source directory: $NugetPublishSource"
        New-Item -ItemType Directory $NugetPublishSource | Out-Null
    }
    if ($NugetPublishSymbolSource -and (Test-Path $NugetPublishSymbolSource -IsValid) -and !(Test-Path $NugetPublishSymbolSource)) {
        Write-Build White "Creating NuGet publish symbol source directory: $NugetPublishSymbolSource"
        New-Item -ItemType Directory $NugetPublishSymbolSource | Out-Null
    }

    # Remove the existing log, since we append to it for each project being packaged via a NuSpec file
    Get-Item $DotNetPackageNuSpecLogFile -ErrorAction Ignore | Remove-Item -Force

    try {
        foreach ($nugetPackage in $nugetPackagesToPublish) {

            Write-Build Green "Publishing package: $nugetPackage"
            # Ensure any NuGet API key is masked in the debug logging
            Write-Verbose ("dotnet nuget push $nugetPackage $nugetPushArgs".Replace($nugetApiKey, "*****"))
            exec {
                & dotnet nuget push $nugetPackage $nugetPushArgs
            }
        }
    }
    finally {
        if ((Test-Path $DotNetPackageNuSpecLogFile) -and $IsAzureDevOps) {
            Write-Host "##vso[artifact.upload artifactname=logs]$((Resolve-Path $DotNetPackageNuSpecLogFile).Path)"
        }
    }
}
