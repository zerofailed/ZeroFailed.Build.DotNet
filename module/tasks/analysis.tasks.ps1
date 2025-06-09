# <copyright file="analysis.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Synopsis: Installs the Covenant .NET global tool
task InstallCovenantTool {
    Install-DotNetTool -Name covenant -Version $covenantVersion
}

# Synopsis: Setup custom SBOM metadata used with Covenant
task PrepareCovenantMetadata {

    $script:covenantMetadataArgs = @()
    foreach ($key in $CovenantMetadata.Keys) {
        # NOTE: No space after the '-m' switch otherwise the metadata key has a leading space in the report
        $script:covenantMetadataArgs += "-m$key=$($CovenantMetadata[$key])"
    }
}

# Synopsis: Generates an SBOM using the Covenant tool
task RunCovenantTool -If { $SolutionToBuild } Version,
                                              InstallCovenantTool,
                                              PrepareCovenantMetadata,{

    $baseOutputName = [IO.Path]::GetFileNameWithoutExtension($SolutionToBuild)
    # Ensure we have a fully-qualified path, as this will be needed when uploading on build server
    $script:covenantJsonOutputFile = Join-Path $here ("/{0}.sbom.json" -f $baseOutputName)
    $script:covenantSpdxOutputFile = Join-Path $here ("/{0}.sbom.spdx.json" -f $baseOutputName)
    $script:covenantCycloneDxOutputFile = Join-Path $here ("/{0}.sbom.cyclonedx.xml" -f $baseOutputName)
    $script:covenantHtmlReportFile = Join-Path $here ("/{0}.sbom.html" -f $baseOutputName)
    Write-Verbose "covenantHtmlReportFile: $covenantHtmlReportFile"

    # Generate SBOM
    exec {
        & dotnet-covenant `
                    generate `
                    $SolutionToBuild `
                    -v $script:GitVersion.SemVer `
                    --output $covenantJsonOutputFile `
                    $covenantMetadataArgs
    }

    # Generate HTML report
    exec {
        & dotnet-covenant `
                    report `
                    $covenantJsonOutputFile `
                    --output $covenantHtmlReportFile

    }
}

# Synopsis: Generate SPDX-formatted report
task GenerateCovenantSpdxReport -If { !$SkipBuildSolution -and $SolutionToBuild -and $CovenantIncludeSpdxReport } RunCovenantTool,{
    exec {
        & dotnet-covenant `
                    convert `
                    spdx `
                    $covenantJsonOutputFile `
                    --output $covenantSpdxOutputFile

    }
    Write-Verbose "covenantSpdxOutputFile: $covenantSpdxOutputFile"
}

# Synopsis: Generate CycloneDX-formatted report
task GenerateCovenantCycloneDxReport -If { !$SkipBuildSolution -and $SolutionToBuild -and $CovenantIncludeCycloneDxReport } RunCovenantTool,{
    exec {
        & dotnet-covenant `
                    convert `
                    cyclonedx `
                    $covenantJsonOutputFile `
                    --output $covenantCycloneDxOutputFile

    }
    Write-Verbose "covenantCycloneDxOutputFile: $covenantCycloneDxOutputFile"
}

# Synopsis: Upload generated Covenant reports as Azure DevOps build artifacts
task PublishCovenantBuildArtefacts -If { $IsAzureDevops } Init,GenerateCovenantSpdxReport,GenerateCovenantCycloneDxReport,{
    Write-Host "##vso[task.setvariable variable=SbomHtmlReportPath;isoutput=true]$covenantHtmlReportFile"
    Write-Host "##vso[artifact.upload artifactname=SBOM]$covenantHtmlReportFile"
    Write-Host "##vso[artifact.upload artifactname=SBOM]$covenantJsonOutputFile"

    if ($CovenantIncludeSpdxReport) {
        Write-Host "##vso[artifact.upload artifactname=SBOM]$covenantSpdxOutputFile"
    }

    if ($CovenantIncludeCycloneDxReport) {
        Write-Host "##vso[artifact.upload artifactname=SBOM]$covenantCycloneDxOutputFile"
    }
}

task RunCovenant -After AnalysisCore `
                 -Jobs RunCovenantTool,
                        GenerateCovenantSpdxReport,
                        GenerateCovenantCycloneDxReport,
                        PublishCovenantBuildArtefacts