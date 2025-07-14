# <copyright file="analysis.properties.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

# Synopsis: The version of the Covenant .NET global tool to install
$covenantVersion = "0.20.0"

# Synopsis: When true, an SPDX-formatted SBOM will be generated from the Covenant report 
$CovenantIncludeSpdxReport = $true

# Synopsis: When true, an CycloneDx-formatted SBOM will be generated from the Covenant report
$CovenantIncludeCycloneDxReport = $false

# Synopsis: A hashtable of additional metadata to be included in the Covenant report
$CovenantMetadata = @{
    git_repo = $(if (Get-Command "gh" -CommandType Application -ErrorAction Ignore) {
        try {
            $ghRepo = & gh repo view --json nameWithOwner
            $ghRepo | ConvertFrom-Json | Select-Object -ExpandProperty nameWithOwner
        }
        catch {
            ""
        }
    })
    git_branch = ((Get-Command "git" -CommandType Application -ErrorAction Ignore) ? (& git branch --show-current) : "")
    git_sha = ((Get-Command "git" -CommandType Application -ErrorAction Ignore) ? (& git rev-parse HEAD) : "")
}