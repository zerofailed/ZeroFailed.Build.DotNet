# ZeroFailed.Build.DotNet - Reference Sheet


<!-- START_GENERATED_HELP -->

## Analysis

This group contains functionality for running analysis tools against .NET projects.  Currently it supports generating a Software Bill of Materials (SBOM) using the [Covenant](https://github.com/patriksvensson/covenant) .NET global tool.

### Properties

| Name                             | Default Value | ENV Override | Description                                                                       |
| -------------------------------- | ------------- | ------------ | --------------------------------------------------------------------------------- |
| `CovenantIncludeCycloneDxReport` | $false        |              | When true, an CycloneDx-formatted SBOM will be generated from the Covenant report |
| `CovenantIncludeSpdxReport`      | $true         |              | When true, an SPDX-formatted SBOM will be generated from the Covenant report      |
| `CovenantMetadata`               | see below     |              | A hashtable of additional metadata to be included in the Covenant report          |
| `covenantVersion`                | "0.20.0"      |              | The version of the Covenant .NET global tool to install                           |

The default Covenant Metadata is attempted to be derived using the `git` & `gh` command-line tools to produce the following:
```
{
    "git_repo": "myOrg/myRepo"
    "git_branch": "<current-branch-name>"
    "git_sha": "<current-commit-ref>"
}
```

Where values cannot be derived (e.g. `gh` cli is unavailable, not a GitHub repo or not a git repo), the following empty metadata will be used instead:
```
{
    "git_repo": ""
    "git_branch": ""
    "git_sha": ""
}
```

### Tasks

| Name                              | Description                                                       |
| --------------------------------- | ----------------------------------------------------------------- |
| `GenerateCovenantCycloneDxReport` | Generate CycloneDX-formatted report                               |
| `GenerateCovenantSpdxReport`      | Generate SPDX-formatted report                                    |
| `InstallCovenantTool`             | Installs the Covenant .NET global tool                            |
| `PrepareCovenantMetadata`         | Setup custom SBOM metadata used with Covenant                     |
| `PublishCovenantBuildArtefacts`   | Upload generated Covenant reports as Azure DevOps build artifacts |
| `RunCovenantTool`                 | Generates an SBOM using the Covenant tool                         |


## Compile

This group contains features associated with compiling a .NET solution.

### Properties

| Name                           | Default Value                                                                 | ENV Override | Description                                                                                                                                                                                  |
| ------------------------------ | ----------------------------------------------------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DotNetCompileFileLoggerProps` | { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetCompileLogFile" } |              | Allow the file logger properties used by 'dotnet build' to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetCompileLogFile>". Supports lazy evaluation. |
| `DotNetCompileLogFile`         | "dotnet-build.log"                                                            |              | The path to the MSBuild log file produced by 'dotnet build'. Defaults to "dotnet-build.log".                                                                                                 |
| `FoldersToClean`               | @("bin", "obj", "TestResults", "_codeCoverage", "_packages")                  |              | An array of project folders to be removed when cleaning the solution. Defaults to "bin", "obj", "TestResults", "_codeCoverage", "_packages".                                                 |
| `SkipBuildSolution`            | $false                                                                        |              | When true, the .NET build functionality will be skipped.                                                                                                                                     |
| `SolutionToBuild`              | $null                                                                         |              | The path to the Visual Studio solution file to build.                                                                                                                                        |

### Tasks

| Name              | Description                    |
| ----------------- | ------------------------------ |
| `BuildSolution`   | Build .NET solution            |
| `CleanSolution`   | Clean .NET solution            |
| `RestorePackages` | Restore .NET Solution Packages |

## Package

The group includes functionality for building different types of .NET packages:

* NuGet Packages (including use of `.nuspec` files)
* Publish packages

### Properties

| Name                                 | Default Value                                                                              | ENV Override | Description                                                                                                                                                                                                                |
| ------------------------------------ | ------------------------------------------------------------------------------------------ | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DotNetPackageFileLoggerProps`       | { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetPackageLogFile" }              |              | Allow the file logger properties used when building project-based NuGet packages to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetPackageLogFile>". Supports lazy evaluation.      |
| `DotNetPackageLogFile`               | "dotnet-package.log"                                                                       |              | The path to the MSBuild log file produced when building project-based NuGet packages. Defaults to "dotnet-package.log".                                                                                                    |
| `DotNetPackageNuSpecFileLoggerProps` | { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetPackageNuSpecLogFile;append" } |              | Allow the file logger properties used when building NuSpec-based NuGet packages to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetPackageNuSpecLogFile>". Supports lazy evaluation. |
| `DotNetPackageNuSpecLogFile`         | "dotnet-package-nuspec.log"                                                                |              | The path to the MSBuild log file produced when building NuSpec-based NuGet packages. Defaults to "dotnet-package.log".                                                                                                     |
| `DotNetPublishFileLoggerProps`       | { "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetPublishLogFile;append" }       |              | Allow the file logger properties used by 'dotnet publish' to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetCompileLogFile>". Supports lazy evaluation.                             |
| `DotNetPublishLogFile`               | "dotnet-publish.log"                                                                       |              | The path to the MSBuild log file produced by 'dotnet publish'. Defaults to "dotnet-publish.log".                                                                                                                           |
| `NuSpecFilesToPackage`               | @()                                                                                        |              | An array containing the path to each '.nuspec' file that requires 'dotnet pack' to be run.                                                                                                                                 |
| `ProjectsToPublish`                  | see below                                                                                  |              | An array containing details of each project that require 'dotnet publish' to be run.                                                                                                                                       |
| `SkipNuGetPackages`                  | $false                                                                                     |              | When true, no project-based NuGet packages will be built, meaning 'dotnet pack' will not be run for them.                                                                                                                  |
| `SkipNuspecPackages`                 | $false                                                                                     |              | When true, no NuSpec-based NuGet packages will be built, meaning 'dotnet pack' will not be run for them.                                                                                                                   |
| `SkipProjectPublishPackages`         | $false                                                                                     |              | When true, no projects specified in 'ProjectsToPublish' will be published, meaning 'dotnet publish' will not be run for them.                                                                                              |


#### ProjectsToPublish

Each entry should either a string with the path to the project or, for more complex scenarios, a hashtable with the following structure:
```
@{
    Project = "<path-to-project-file>"
    RuntimeIdentifiers = @(<list-of-RIDs>)
    SelfContained = <bool>
    Trimmed = <bool>
    ReadyToRun = <bool>
    SingleFile = <bool>
}
```

### Tasks

| Name                          | Description                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------ |
| `BuildNuGetPackages`          | Build the NuGet packages configured in the .NET solution                       |
| `BuildNuSpecPackages`         | Build NuGet packages for the .nuspec files specified in 'NuspecFilesToPackage' |
| `BuildProjectPublishPackages` | Build publish packages for projects specified in 'ProjectsToPublish'           |

## Publish

This group contains features for publishing NuGet packages.

### Properties

| Name                             | Default Value                                | ENV Override | Description                                                                                                                                                                                |
| -------------------------------- | -------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `NugetPackageNamesToPublishGlob` | { "*.$(($script:GitVersion).SemVer).nupkg" } |              | Sets the glob pattern used to select which NuGet packages will be published. Defaults to publishing all NuGet packages it finds with the current version number. Supports lazy evaluation. |
| `NugetPublishSkipDuplicates`     | $true                                        |              | When true, the NuGet publisher will skip publishing packages that already exist in the target feed. Defaults to 'true'.                                                                    |
| `NugetPublishSource`             | "$here/_local-nuget-feed"                    |              | Sets the NuGet source to publish to. Defaults to a file-system based feed located in a directory named '_local-nuget-feed' located alongside the build script.                             |
| `NugetPublishSymbolSource`       | ""                                           |              | Allows the target NuGet symbol source to be customised. Defaults to an empty string, which means that symbols will use the same source as the packages.                                    |

### Tasks

| Name                   | Description                      |
| ---------------------- | -------------------------------- |
| `PublishNuGetPackages` | Publish any built NuGet packages |

## Test

This group contains functionality for running tests, collecting code coverage.

### Properties

| Name                        | Default Value                                                          | ENV Override | Description                                                                                                                                                                                                  |
| --------------------------- | ---------------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `AdditionalTestArgs`        | @()                                                                    |              | Allows arbitrary arguments to be passed to 'dotnet test'.                                                                                                                                                    |
| `DisableCicdServerLogger`   | $false                                                                 |              | When true, the CI/CD-specific loggers will not be used (e.g. Azure DevOps, GitHub Actions)                                                                                                                   |
| `DotNetTestFileLoggerProps` | "/flp:verbosity=$DotNetFileLoggerVerbosity;logfile=$DotNetTestLogFile" |              | Allow the file logger properties used when running tests via 'dotnet test' to be customised. Defaults to "/flp:verbosity=<DotNetFileLoggerVerbosity>;logfile=<DotNetTestLogFile>". Supports lazy evaluation. |
| `DotNetTestLogFile`         | "dotnet-test.log"                                                      |              | The path to the MSBuild log file produced when running tests via 'dotnet test'. Defaults to "dotnet-test.log".                                                                                               |
| `DotNetTestLoggers`         | @("console;verbosity=$LogLevel", "trx;LogFilePrefix=test-results")     |              | Sets the default '--logger' configuration passed to 'dotnet test'.                                                                                                                                           |
| `SkipDotNetTests`           | $false                                                                 |              | When true, the .NET test functionality will be skipped.                                                                                                                                                      |
| `TargetFrameworkMoniker`    | ""                                                                     |              | Optionally specify the target framework moniker to use when running tests.                                                                                                                                   |

### Tasks

| Name                         | Description                                                             |
| ---------------------------- | ----------------------------------------------------------------------- |
| `RunTestsWithDotNetCoverage` | Run .NET solution tests with 'dotnet-coverage' to collect code coverage |

## Report

This group contains functionality for producing test-related reports.

### Properties

| Name                                       | Default Value             | ENV Override                                     | Description                                                                                                                                                                                                                               |
| ------------------------------------------ | ------------------------- | ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CodeCoverageFilenameGlob`                 | "coverage.*cobertura.xml" | ZF_BUILD_DOTNET_COVERAGE_FILES_GLOB              | The wildcard expression used to find the Cobertura XML files produced by the test runner. Defaults to "coverage.*cobertura.xml".                                                                                                          |
| `ExcludeAssembliesInCodeCoverage`          | @()                       |                                                  | An optional wildcard expression filter for assemblies that should be excluded from the code coverage report. Defaults to no filter.                                                                                                       |
| `ExcludeFilesInCodeCoverage`               | @()                       |                                                  | An optional wildcard expression filter for files that should be excluded from the code coverage report. Defaults to no filter.                                                                                                            |
| `GenerateMarkdownCodeCoverageSummary`      | $true                     |                                                  | When true, runs the 'CodeCoverageSummary' global tool to generate a Markdown code coverage summary. Defaults to true.                                                                                                                     |
| `GenerateTestReport`                       | $true                     | ZF_BUILD_DOTNET_GENERATE_TEST_REPORT             | When true, runs the 'dotnet-reportgenerator-globaltool' to generate an XML test report. Defaults to true.                                                                                                                                 |
| `IncludeAssembliesInCodeCoverage`          | @()                       |                                                  | An optional wildcard expression filter for assemblies that should be included in the code coverage report. Defaults to no filter.                                                                                                         |
| `IncludeFilesInCodeCoverage`               | @()                       |                                                  | An optional wildcard expression filter for files that should be included in the code coverage report. Defaults to no filter.                                                                                                              |
| `ReportGeneratorAdditionalArgs`            | ""                        |                                                  | Allows arbitrary arguments to be passed to the reportgenerator tool.                                                                                                                                                                      |
| `ReportGeneratorToolVersion`               | "5.3.8"                   |                                                  | Allows the version of the 'dotnet-reportgenerator-globaltool' to be customised. Defaults to "5.3.8".                                                                                                                                      |
| `SkipTestReport`                           | $false                    | ZF_BUILD_DOTNET_SKIP_TEST_REPORT                 | When true, test reporting will be skipped.                                                                                                                                                                                                |
| `StripOutputFromLargeTrxFiles`             | $false                    | ZF_BUILD_DOTNET_STRIP_LARGE_TRX_FILES            | When true, TRX test results files will have 'Output' elements stripped to reduce their size. Useful when large files are too big to be parsed by XML libraries used by other CI/CD tools. Defaults to false.                              |
| `TestResultTrxFilesGlob`                   | "test-results_*.trx"      | ZF_BUILD_DOTNET_TRX_FILES_GLOB                   | The wildcard expression used to find TRX test results files to be stripped. Defaults to 'test-results_*.trx'.                                                                                                                             |
| `TestReportTypes`                          | "HtmlInline"              | ZF_BUILD_DOTNET_TEST_REPORT_TYPES                | Allows the type of reports produced by the 'dotnet-reportgenerator-globaltool' to be customised. Defaults to "HtmlInline".                                                                                                                |
| `TruncateOversizedCoverageReport`          | $false                    | ZF_BUILD_DOTNET_TRUNCATE_LARGE_COVERAGE_MARKDOWN | When true, Markdown code coverage reports larger than 'TruncateOversizedCoverageReportThreshold' will be truncated. Useful when the Markdown is uploaded to systems that impose size limits (e.g. GitHub PR comments). Defaults to false. |
| `TruncateOversizedCoverageReportThreshold` | 60000                     | ZF_BUILD_DOTNET_TRUNCATE_LARGE_COVERAGE_MARKDOWN | When true, Markdown code coverage reports larger than 'TruncateOversizedCoverageReportThreshold' will be truncated. Useful when the Markdown is uploaded to systems that impose size limits (e.g. GitHub PR comments). Defaults to false. |

### Tasks

| Name                                  | Description                                                                                                     |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `GenerateMarkdownCodeCoverageSummary` | Generates a Markdown code coverage summary report.                                                              |
| `GenerateTestReport`                  | Generates additional test reports using 'dotnet-reportgenerator-globaltool'.                                    |
| `PrepareTestReportParameters`         | Configures the core set of reportgenerator command-line arguments                                               |
| `StripOutputFromLargeTrxFiles`        | Handles the scenario where the generated .trx result file would be too large to parse by certain XML libraries. |
| `TestReport`                          | Generates test coverage reports after tests have been run.                                                      |
| `TruncateOversizedCoverageReport`     | Handles the scenario where the generated code coverage markdown file would be too big for a GitHub PR comment.  |

<!-- END_GENERATED_HELP -->
