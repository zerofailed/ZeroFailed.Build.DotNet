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

# Synopsis: When true, a short-lived NuGet API key is obtained via NuGet.org Trusted Publishing (GitHub Actions OIDC), instead of using the 'NUGET_API_KEY' environment variable. Requires the GitHub Actions job to have the 'id-token: write' permission. Defaults to 'false'.
$NugetPublishUseTrustedPublishing ??= [Convert]::ToBoolean((property ZF_BUILD_DOTNET_NUGET_USE_TRUSTED_PUBLISHING $false))

# Synopsis: The NuGet.org username (profile name, not email address) that owns the Trusted Publishing policy. Required when 'NugetPublishUseTrustedPublishing' is enabled.
$NugetTrustedPublishingUsername ??= property ZF_BUILD_DOTNET_NUGET_TRUSTED_PUBLISHING_USER ''

# Synopsis: The NuGet.org endpoint used to exchange an OIDC token for a short-lived API key. Defaults to 'https://www.nuget.org/api/v2/token'.
$NugetTrustedPublishingTokenEndpoint ??= property ZF_BUILD_DOTNET_NUGET_TRUSTED_PUBLISHING_TOKEN_ENDPOINT 'https://www.nuget.org/api/v2/token'

# Synopsis: The audience requested for the GitHub Actions OIDC token used with NuGet.org Trusted Publishing. Defaults to 'https://www.nuget.org'.
$NugetTrustedPublishingAudience ??= property ZF_BUILD_DOTNET_NUGET_TRUSTED_PUBLISHING_AUDIENCE 'https://www.nuget.org'
