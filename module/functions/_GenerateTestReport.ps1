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

    .PARAMETER BasePath
    Specifies the base path used when searching for code coverage output that will be used to generate the report.

    .PARAMETER ReportTypes
    Specifies the type of reports to generate. Defaults to the variable $TestReportTypes.

    .PARAMETER OutputPath
    Specifies the path where the generated report will be saved. Defaults to the variable $CoverageDir.

    .PARAMETER IncludeAssemblyFilters
    Specifies one or more assembly name patterns to include in the report.

    .PARAMETER ExcludeAssemblyFilters
    Specifies one or more assembly name patterns to exclude from the report.

    .PARAMETER IncludeFileFilters
    Specifies one or more file path patterns to include in the report.

    .PARAMETER ExcludeFileFilters
    Specifies one or more file path patterns to exclude from the report.

    .PARAMETER AdditionalArgs
    Allows arbitrary command-line arguments to be passed to the reportgenerator tool.

    .EXAMPLE
    _GenerateTestReport -ReportTypes "Html" -OutputPath "C:\CoverageReports"
    Generates an HTML test coverage report in the specified directory.
#>
function _GenerateTestReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $BasePath,

        [Parameter(Mandatory)]
        [string] $ReportTypes,

        [Parameter(Mandatory)]
        [string] $OutputPath,

        [Parameter()]
        [string[]] $IncludeAssemblyFilters = @(),

        [Parameter()]
        [string[]] $ExcludeAssemblyFilters = @(),

        [string[]] $IncludeFileFilters = @(),

        [Parameter()]
        [string[]] $ExcludeFileFilters = @(),

        [Parameter()]
        [string] $AdditionalArgs = ''
    )
    Install-DotNetTool -Name "dotnet-reportgenerator-globaltool" -Version $ReportGeneratorToolVersion

    $testReportGlob = "$BasePath/**/**/$CodeCoverageFilenameGlob"

    if (!(Get-ChildItem -Path $BasePath -Filter $CodeCoverageFilenameGlob -Recurse)) {
        Write-Warning "No code coverage reports found for the file pattern '$testReportGlob' - skipping test report"
    }
    else {
        $reportGeneratorArgs = [List[string]]::new()
        $reportGeneratorArgs.AddRange([string[]]@(
            "-reports:$testReportGlob",
            "-targetdir:$OutputPath",
            "-reporttypes:$ReportTypes"
        ))

        if ($IncludeAssemblyFilters -or $ExcludeAssemblyFilters) {
            $assemblyFilters = @($IncludeAssemblyFilters | ForEach-Object { "+$_" }) +
                               @($ExcludeAssemblyFilters | ForEach-Object { "-$_" })
        
            $reportGeneratorArgs.Add("-assemblyfilters:{0}" -f ($assemblyFilters -join ";"))
        }

        if ($IncludeFileFilters -or $ExcludeFileFilters) {
            $fileFilters = @($IncludeFileFilters | ForEach-Object { "+$_" }) +
                           @($ExcludeFileFilters | ForEach-Object { "-$_" })
        
            $reportGeneratorArgs.Add("-filefilters:{0}" -f ($fileFilters -join ";"))
        }

        if ($AdditionalArgs) {
            $reportGeneratorArgs.Add($AdditionalArgs)
        }

        Write-Verbose "CmdLine: reportgenerator $reportGeneratorArgs" -Verbose
        exec {
            & reportgenerator @reportGeneratorArgs
        }
    }
}