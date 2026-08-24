# <copyright file="report.properties.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    $propertiesPath = $PSCommandPath.Replace('.Tests.ps1','.ps1')

    # Each case must be evaluated in a fresh scope, because the properties file uses '??=' and
    # would therefore skip any value already present.
    function Get-ReportProperty {
        param (
            [string] $Name,
            [object] $IsGitHubActions,
            [hashtable] $EnvironmentVariables = @{}
        )

        $originalEnv = @{}
        foreach ($key in $EnvironmentVariables.Keys) {
            $originalEnv[$key] = [Environment]::GetEnvironmentVariable($key)
            [Environment]::SetEnvironmentVariable($key, $EnvironmentVariables[$key])
        }
        try {
            & {
                param($path, $ghActions, $propertyName)

                # Stand-in for the InvokeBuild 'property' command, which only exists during a build
                function property {
                    param($Name, $Default)
                    $value = [Environment]::GetEnvironmentVariable($Name)
                    if ($value) { $value } else { $Default }
                }

                $IsGitHubActions = $ghActions
                . $path
                Get-Variable -Name $propertyName -ValueOnly
            } $propertiesPath $IsGitHubActions $Name
        }
        finally {
            foreach ($key in $originalEnv.Keys) {
                [Environment]::SetEnvironmentVariable($key, $originalEnv[$key])
            }
        }
    }
}

Describe 'report.properties' {

    Context 'UseGitHubFlavour' {

        It 'should always be defined as a boolean, never left null' {
            $result = Get-ReportProperty -Name UseGitHubFlavour `
                                         -IsGitHubActions $null `
                                         -EnvironmentVariables @{ GITHUB_ACTIONS = $null; ZF_BUILD_DOTNET_USE_GITHUB_FLAVOUR = $null }
            $result | Should -BeOfType [bool]
            $result | Should -BeFalse
        }

        It 'should be true when running on GitHub Actions' {
            Get-ReportProperty -Name UseGitHubFlavour `
                               -IsGitHubActions $true `
                               -EnvironmentVariables @{ ZF_BUILD_DOTNET_USE_GITHUB_FLAVOUR = $null } |
                Should -BeTrue
        }

        It 'should be false when running elsewhere' {
            Get-ReportProperty -Name UseGitHubFlavour `
                               -IsGitHubActions $false `
                               -EnvironmentVariables @{ GITHUB_ACTIONS = $null; ZF_BUILD_DOTNET_USE_GITHUB_FLAVOUR = $null } |
                Should -BeFalse
        }

        It 'should fall back to the GITHUB_ACTIONS environment variable' {
            Get-ReportProperty -Name UseGitHubFlavour `
                               -IsGitHubActions $null `
                               -EnvironmentVariables @{ GITHUB_ACTIONS = 'true'; ZF_BUILD_DOTNET_USE_GITHUB_FLAVOUR = $null } |
                Should -BeTrue
        }

        It 'should be overridable via ZF_BUILD_DOTNET_USE_GITHUB_FLAVOUR' {
            Get-ReportProperty -Name UseGitHubFlavour `
                               -IsGitHubActions $true `
                               -EnvironmentVariables @{ ZF_BUILD_DOTNET_USE_GITHUB_FLAVOUR = 'false' } |
                Should -BeFalse
        }
    }
}
