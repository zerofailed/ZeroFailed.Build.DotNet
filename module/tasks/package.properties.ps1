# <copyright file="package.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Synopsis: When true, no project-based NuGet packages will be built, meaning 'dotnet pack' will not be run for them.
$SkipNuGetPackages = $false

# Synopsis: When true, no NuSpec-based NuGet packages will be built, meaning 'dotnet pack' will not be run for them.
$SkipNuspecPackages = $false

# Synopsis: When true, no projects specified in 'ProjectsToPublish' will be published, meaning 'dotnet publish' will not be run for them.
$SkipProjectPublishPackages = $false

# Synopsis: An array containing details of each project that require 'dotnet publish' to be run.
$ProjectsToPublish = @()

# Synopsis: An array containing the path to each '.nuspec' file that require 'dotnet pack' to be run.
$NuSpecFilesToPackage = @()

# Logging options

# Synopsis: The path to the MSBuild log file produced when building project-based NuGet packages. Defaults to "dotnet-package.log".
$DotNetPackageLogFile = "dotnet-package.log"

# Synopsis: Allow the file logger properties used when building project-based NuGet packages to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetPackageLogFile>". Supports lazy evaluation.
$DotNetPackageFileLoggerProps = { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetPackageLogFile" }

# Synopsis: The path to the MSBuild log file produced when building NuSpec-based NuGet packages. Defaults to "dotnet-package.log".
$DotNetPackageNuSpecLogFile = "dotnet-package-nuspec.log"

# Synopsis: Allow the file logger properties used when building NuSpec-based NuGet packages to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetPackageNuSpecLogFile>". Supports lazy evaluation.
$DotNetPackageNuSpecFileLoggerProps = { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetPackageNuSpecLogFile;append" }

# Synopsis: The path to the MSBuild log file produced by 'dotnet publish'. Defaults to "dotnet-publish.log".
$DotNetPublishLogFile = "dotnet-publish.log"

# Synopsis: Allow the file logger properties used by 'dotnet publish' to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetCompileLogFile>". Supports lazy evaluation.
$DotNetPublishFileLoggerProps = { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetPublishLogFile;append" }
