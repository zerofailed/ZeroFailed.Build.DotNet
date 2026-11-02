# <copyright file="_GetNuGetTrustedPublishingApiKey.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    # sut
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')

    $script:originalRequestUrl = $env:ACTIONS_ID_TOKEN_REQUEST_URL
    $script:originalRequestToken = $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN
}

AfterAll {
    $env:ACTIONS_ID_TOKEN_REQUEST_URL = $script:originalRequestUrl
    $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN = $script:originalRequestToken
}

Describe '_GetNuGetTrustedPublishingApiKey' {

    BeforeEach {
        $env:ACTIONS_ID_TOKEN_REQUEST_URL = 'https://token.actions.example/request?api-version=2.0'
        $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN = 'request-token'

        Mock Write-Host {}
        Mock Invoke-RestMethod { [pscustomobject]@{ value = 'oidc-token' } } -ParameterFilter { $Method -ne 'Post' }
        Mock Invoke-RestMethod { [pscustomobject]@{ apiKey = 'temp-api-key' } } -ParameterFilter { $Method -eq 'Post' }
    }

    Context 'Validation' {

        It 'throws when no username is specified' {
            { _GetNuGetTrustedPublishingApiKey -Username '' } | Should -Throw '*requires a NuGet.org username*'
        }

        It 'throws when the GitHub Actions OIDC request URL is not available' {
            $env:ACTIONS_ID_TOKEN_REQUEST_URL = $null
            { _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot' } | Should -Throw "*'id-token: write'*"
        }

        It 'throws when the GitHub Actions OIDC request token is not available' {
            $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN = $null
            { _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot' } | Should -Throw "*'id-token: write'*"
        }

        It 'does not call any endpoints when validation fails' {
            { _GetNuGetTrustedPublishingApiKey -Username '' } | Should -Throw
            Should -Invoke Invoke-RestMethod -Times 0 -Exactly
        }
    }

    Context 'Successful token exchange' {

        BeforeEach {
            $script:result = _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot'
        }

        It 'requests the OIDC token with the URL-encoded default audience' {
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -ne 'Post' -and
                $Uri -eq 'https://token.actions.example/request?api-version=2.0&audience=https%3A%2F%2Fwww.nuget.org'
            }
        }

        It 'authenticates the OIDC request with the GitHub Actions request token' {
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -ne 'Post' -and $Headers.Authorization -eq 'Bearer request-token'
            }
        }

        It 'posts the OIDC token to the default NuGet.org token endpoint' {
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Post' -and
                $Uri -eq 'https://www.nuget.org/api/v2/token' -and
                $Headers.Authorization -eq 'Bearer oidc-token' -and
                $ContentType -eq 'application/json'
            }
        }

        It 'sends the username and ApiKey token type in the request body' {
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Post' -and
                ($Body | ConvertFrom-Json).username -eq 'contoso-bot' -and
                ($Body | ConvertFrom-Json).tokenType -eq 'ApiKey'
            }
        }

        It 'returns the temporary API key' {
            $script:result | Should -Be 'temp-api-key'
        }

        It 'masks the temporary API key in the GitHub Actions logs' {
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq '::add-mask::temp-api-key' }
        }
    }

    Context 'Custom endpoint and audience' {

        It 'uses the specified token endpoint and audience' {
            _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot' -TokenEndpoint 'https://int.nugettest.org/api/v2/token' -Audience 'https://int.nugettest.org'

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -ne 'Post' -and $Uri -like '*&audience=https%3A%2F%2Fint.nugettest.org'
            }
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Post' -and $Uri -eq 'https://int.nugettest.org/api/v2/token'
            }
        }
    }

    Context 'Failures' {

        It 'throws when the OIDC response does not contain a token' {
            Mock Invoke-RestMethod { [pscustomobject]@{} } -ParameterFilter { $Method -ne 'Post' }
            { _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot' } | Should -Throw '*did not contain a token*'
        }

        It 'surfaces the error details when the token exchange fails' {
            Mock Invoke-RestMethod { throw 'No matching trust policy' } -ParameterFilter { $Method -eq 'Post' }
            { _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot' } | Should -Throw "*token exchange failed*contoso-bot*No matching trust policy*"
        }

        It 'throws when the token exchange response does not contain an API key' {
            Mock Invoke-RestMethod { [pscustomobject]@{} } -ParameterFilter { $Method -eq 'Post' }
            { _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot' } | Should -Throw '*did not return an API key*'
        }

        It 'does not mask anything when the token exchange fails' {
            Mock Invoke-RestMethod { throw 'boom' } -ParameterFilter { $Method -eq 'Post' }
            { _GetNuGetTrustedPublishingApiKey -Username 'contoso-bot' } | Should -Throw
            Should -Invoke Write-Host -Times 0 -Exactly
        }
    }
}
