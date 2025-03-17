# <copyright file="_GenerateTestReport.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<# 
    .SYNOPSIS
    Generates a test report using the dotnet-reportgenerator global tool.

    .DESCRIPTION
    The _GenerateTestReport cmdlet uses the dotnet-reportgenerator tool to generate a code coverage report 
    from Cobertura XML files. It searches for code coverage data in the source directory and, if found, 
    generates the report in the specified output directory.

    .PARAMETER ReportTypes
    Specifies the type of reports to generate. Defaults to the variable $TestReportTypes.

    .PARAMETER OutputPath
    Specifies the path where the generated report will be saved. Defaults to the variable $CoverageDir.

    .EXAMPLE
    _GenerateTestReport -ReportTypes "Html" -OutputPath "C:\CoverageReports"
    Generates an HTML test coverage report in the specified directory.
#>
function _GenerateTestReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $ReportTypes,

        [Parameter(Mandatory)]
        [string] $OutputPath,

        [Parameter()]
        [string] $IncludeAssemblyFilter = "",

        [Parameter()]
        [string] $ExcludeAssemblyFilter = ""        
    )
    Install-DotNetTool -Name "dotnet-reportgenerator-globaltool" -Version $ReportGeneratorToolVersion

    $testReportGlob = "$SourcesDir/**/**/$CodeCoverageFilenameGlob"

    if (!(Get-ChildItem -Path $SourceDir -Filter $CodeCoverageFilenameGlob -Recurse)) {
        Write-Warning "No code coverage reports found for the file pattern '$testReportGlob' - skipping test report"
    }
    else {
        $reportGeneratorArgs = @(
            "-reports:$testReportGlob",
            "-targetdir:$OutputPath",
            "-reporttypes:$ReportTypes"
        )

        if ($IncludeAssemblyFilter -or $ExcludeAssemblyFilter) {
            $filters = @()
            if ($IncludeAssemblyFilter) {
                $filters += "+$IncludeAssemblyFilter"
            }
            if ($ExcludeAssemblyFilter) {
                $filters += "-$ExcludeAssemblyFilter"
            }
            $reportGeneratorArgs += "-assemblyfilters:{0}" -f ($filters -join ";")
        }

        Write-Verbose "CmdLine: reportgenerator $reportGeneratorArgs" -Verbose
        exec {
            & reportgenerator @reportGeneratorArgs
        }
    }
}