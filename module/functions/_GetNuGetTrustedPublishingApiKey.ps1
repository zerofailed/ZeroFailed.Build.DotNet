# <copyright file="_GetNuGetTrustedPublishingApiKey.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
    .SYNOPSIS
    Obtains a short-lived NuGet API key via NuGet.org Trusted Publishing.

    .DESCRIPTION
    Requests a GitHub Actions OIDC token for the specified audience and exchanges it at the NuGet.org token
    endpoint for a temporary API key (valid for 1 hour). The returned key is registered with GitHub Actions
    as a secret mask so that it is redacted from any subsequent log output.

    The GitHub Actions job must have the 'id-token: write' permission, and a matching Trusted Publishing
    policy must be configured on NuGet.org. Each OIDC token can only be exchanged once, so this should be
    called shortly before publishing.

    .PARAMETER Username
    The NuGet.org username (profile name, not email address) that owns the Trusted Publishing policy.

    .PARAMETER TokenEndpoint
    The NuGet.org token exchange endpoint.

    .PARAMETER Audience
    The audience to request for the GitHub Actions OIDC token.

    .EXAMPLE
    $apiKey = _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot'
#>
function _GetNuGetTrustedPublishingApiKey {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Username,

        [Parameter()]
        [string] $TokenEndpoint = 'https://www.nuget.org/api/v2/token',

        [Parameter()]
        [string] $Audience = 'https://www.nuget.org'
    )

    if ([string]::IsNullOrWhiteSpace($Username)) {
        throw "NuGet Trusted Publishing requires a NuGet.org username - set the 'ZF_BUILD_DOTNET_NUGET_TRUSTED_PUBLISHING_USER' environment variable or the 'NugetTrustedPublishingUsername' property."
    }
    if (!$env:ACTIONS_ID_TOKEN_REQUEST_URL -or !$env:ACTIONS_ID_TOKEN_REQUEST_TOKEN) {
        throw "Unable to request an OIDC token for NuGet Trusted Publishing - either this is not running in GitHub Actions or the job does not have the 'id-token: write' permission."
    }

    # Request an OIDC token from GitHub Actions for the NuGet.org audience
    $oidcRequestUri = "{0}&audience={1}" -f $env:ACTIONS_ID_TOKEN_REQUEST_URL, [uri]::EscapeDataString($Audience)
    try {
        $oidcResponse = Invoke-RestMethod -Uri $oidcRequestUri `
                                          -Headers @{ Authorization = "Bearer $($env:ACTIONS_ID_TOKEN_REQUEST_TOKEN)" }
    }
    catch {
        throw "Failed to obtain a GitHub Actions OIDC token for NuGet Trusted Publishing: $($_.Exception.Message)"
    }
    $oidcToken = $oidcResponse.value
    if (!$oidcToken) {
        throw "Failed to obtain a GitHub Actions OIDC token for NuGet Trusted Publishing: the response did not contain a token."
    }

    # Exchange the OIDC token for a short-lived NuGet API key
    $body = @{
        username = $Username
        tokenType = 'ApiKey'
    } | ConvertTo-Json -Compress
    try {
        $tokenResponse = Invoke-RestMethod -Method Post `
                                           -Uri $TokenEndpoint `
                                           -ContentType 'application/json' `
                                           -Headers @{ Authorization = "Bearer $oidcToken" } `
                                           -Body $body
    }
    catch {
        # NuGet.org returns details of policy mismatches in the response body, so surface it
        $statusCode = $_.Exception.Response ? [int]$_.Exception.Response.StatusCode : 'n/a'
        $details = $_.ErrorDetails.Message ? $_.ErrorDetails.Message : $_.Exception.Message
        throw "NuGet Trusted Publishing token exchange failed (HTTP $statusCode) for user '$Username' at '$TokenEndpoint': $details"
    }
    $apiKey = $tokenResponse.apiKey
    if (!$apiKey) {
        throw "NuGet Trusted Publishing token exchange did not return an API key."
    }

    # Ensure the temporary API key is redacted from the GitHub Actions logs
    Write-Host "::add-mask::$apiKey"

    return $apiKey
}
