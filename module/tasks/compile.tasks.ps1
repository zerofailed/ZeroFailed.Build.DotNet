# <copyright file="compile.tasks.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

. $PSScriptRoot/compile.properties.ps1

# Synopsis: Clean .NET solution
task CleanSolution -If {$CleanBuild -and $SolutionToBuild} -Before BuildCore {
    exec { 
        dotnet clean $SolutionToBuild `
                     --configuration $Configuration `
                     --verbosity $LogLevel
    }

    # Delete output folders
    Write-Build White "Deleting output folders..."
    $FoldersToClean | ForEach-Object {
        Get-ChildItem -Path (Split-Path -Parent $SolutionToBuild) `
                      -Filter $_ `
                      -Recurse `
            | Where-Object { $_.PSIsContainer }
    } | Remove-Item -Recurse -Force
}

# Synopsis: Build .NET solution
task BuildSolution -If {!$SkipBuildSolution -and $SolutionToBuild} -After BuildCore Version,RestorePackages,{

    # enable deferred evaluation of the file logger properties
    $_fileLoggerProps = Resolve-Value $DotNetCompileFileLoggerProps
    try {
        exec {
            dotnet build $SolutionToBuild `
                        --no-restore `
                        --configuration $Configuration `
                        /p:Version="$(($script:GitVersion).SemVer)" `
                        --verbosity $LogLevel `
                        $($_fileLoggerProps ? $_fileLoggerProps : "/fl")
        }
    }
    finally {
        if ((Test-Path $DotNetCompileLogFile) -and $IsAzureDevOps) {
            Write-Host "##vso[artifact.upload artifactname=logs]$((Resolve-Path $DotNetCompileLogFile).Path)"
        }
    }
}

# Synopsis: Restore .NET Solution Packages
task RestorePackages -If {$SolutionToBuild} {
    exec { 
        dotnet restore $SolutionToBuild `
                       --verbosity $LogLevel
    }
}