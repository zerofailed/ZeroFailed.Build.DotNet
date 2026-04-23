# <copyright file="publish.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Synopsis: Sets the NuGet source to publish to. Defaults to a file-system based feed located in a directory named '_local-nuget-feed' located alongside the build script.
$NugetPublishSource ??= property ZF_BUILD_DOTNET_NUGET_PUBLISH_SOURCE "$here/_local-nuget-feed"

# Synopsis: Allows the target NuGet symbol source to be customised. Defaults to an empty string, which means that symbols will use the same source as the packages.
$NugetPublishSymbolSource ??= property ZF_BUILD_DOTNET_NUGET_PUBLISH_SYMBOL_SOURCE ''

# Synopsis: When true, the NuGet publisher will skip publishing packages that already exist in the target feed. Defaults to 'true'.
$NugetPublishSkipDuplicates ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_SKIP_PUBLISH_NUGET_DUPLICATES $true))

# Synopsis: Sets the glob pattern used to select which NuGet packages will be published. Defaults to publishing all NuGet packages it finds with the current version number. Supports lazy evaluation.
$NugetPackageNamesToPublishGlob ??= { "*.$(($script:GitVersion).SemVer).nupkg" }
