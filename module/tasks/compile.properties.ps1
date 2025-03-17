# <copyright file="compile.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Synopsis: When true, the .NET build functionality will be skipped.
$SkipBuildSolution = $false

# Synopsis: The path to the Visual Studio solution file to build.
$SolutionToBuild = $null

# Synopsis: An array of project folders to be removed when cleaning the solution. Defaults to "bin", "obj", "TestResults", "_codeCoverage", "_packages".
$FoldersToClean = @("bin", "obj", "TestResults", "_codeCoverage", "_packages")

# Logging properties

# Synopsis: Sets ths MSBuild console logging verbosity level. Valid values are "quiet", "minimal", "normal", "detailed", and "diagnostic". Defaults to "minimal".
$LogLevel ??= "minimal"

# Synopsis: Sets ths MSBuild file logging verbosity level. Valid values are "quiet", "minimal", "normal", "detailed", and "diagnostic". Defaults to "normal".
$DotNetFileLoggerVerbosity ??= "normal"

# Synopsis: The path to the MSBuild log file produced by 'dotnet build'. Defaults to "dotnet-build.log".
$DotNetCompileLogFile = "dotnet-build.log"

# TODO: Support a dedicated log directory
# Synopsis: Allow the file logger properties used by 'dotnet build' to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetCompileLogFile>". Supports lazy evaluation.
$DotNetCompileFileLoggerProps = { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetCompileLogFile" }

# TODO - Optional properties
# /p:EndjinRepositoryUrl="$BuildRepositoryUri" `