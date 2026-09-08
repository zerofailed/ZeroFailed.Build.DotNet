# <copyright file="test.properties.Tests.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

BeforeAll {
    $propertiesPath = $PSCommandPath.Replace('.Tests.ps1','.ps1')

    # Returns the argument immediately following the named flag (or $null if absent).
    function Get-ArgValue {
        param ([string[]] $Arguments, [string] $Flag)
        $index = [array]::IndexOf($Arguments, $Flag)
        if ($index -ge 0 -and $index -lt ($Arguments.Count - 1)) { $Arguments[$index + 1] } else { $null }
    }

    # Each case must be evaluated in a fresh scope, because the properties file uses '??=' and
    # would therefore skip any value already present.
    function Get-TestFileLoggerProps {
        param (
            [bool] $IsMtp,
            [string] $FileLoggerVerbosity = 'normal'
        )

        & {
            param($path, $mtp, $verbosity)

            # Stand-in for the InvokeBuild 'property' command, which only exists during a build
            function property {
                param($Name, $Default)
                $value = [Environment]::GetEnvironmentVariable($Name)
                if ($value) { $value } else { $Default }
            }

            # Stand-in for the ZeroFailed.DevOps.Common 'Resolve-Value' function
            function Resolve-Value {
                param($Value)
                if ($Value -is [scriptblock]) { $Value.Invoke() } else { $Value }
            }

            # Stand-ins for the variables that the build process and other properties files provide
            $here = 'C:\code'
            $LogLevel = 'minimal'
            $DotNetFileLoggerVerbosity = $verbosity
            $isMtp = $mtp

            . $path
            [string[]](Resolve-Value $DotNetTestFileLoggerProps)
        } $propertiesPath $IsMtp $FileLoggerVerbosity
    }
}

Describe 'test.properties' {

    Context 'DotNetTestFileLoggerProps when using the Microsoft Testing Platform' {

        BeforeAll {
            $props = Get-TestFileLoggerProps -IsMtp $true
        }

        It 'enables the diagnostic file logger' {
            $props | Should -Contain '--diagnostic'
        }

        It 'maps the default file logger verbosity to the equivalent MTP verbosity' {
            Get-ArgValue $props '--diagnostic-verbosity' | Should -Be 'Warning'
        }

        It 'writes the diagnostic log to the repo root' {
            Get-ArgValue $props '--diagnostic-output-directory' | Should -Be 'C:\code'
        }

        It 'does not pass --diagnostic-output-fileprefix, which was removed in MTP 2.0' {
            $props | Should -Not -Contain '--diagnostic-output-fileprefix'
        }

        It 'does not pass --diagnostic-file-prefix, which is not recognised by MTP 1.x' {
            $props | Should -Not -Contain '--diagnostic-file-prefix'
        }

        It 'only uses options that are available in both MTP 1.x and 2.x' {
            $props | Where-Object { $_ -like '--*' } |
                Should -BeIn @('--diagnostic', '--diagnostic-verbosity', '--diagnostic-output-directory')
        }
    }

    Context 'DotNetTestFileLoggerProps verbosity mapping for the Microsoft Testing Platform' -ForEach @(
        @{ Verbosity = 'quiet';      Expected = 'Critical' }
        @{ Verbosity = 'minimal';    Expected = 'Error' }
        @{ Verbosity = 'normal';     Expected = 'Warning' }
        @{ Verbosity = 'detailed';   Expected = 'Information' }
        @{ Verbosity = 'diagnostic'; Expected = 'Trace' }
    ) {

        It 'maps DotNetFileLoggerVerbosity <Verbosity> to <Expected>' {
            $props = Get-TestFileLoggerProps -IsMtp $true -FileLoggerVerbosity $Verbosity
            Get-ArgValue $props '--diagnostic-verbosity' | Should -Be $Expected
        }
    }

    Context 'DotNetTestFileLoggerProps when using VSTest' {

        It 'uses the MSBuild file logger' {
            Get-TestFileLoggerProps -IsMtp $false | Should -Be '/flp:verbosity=normal;logfile=dotnet-test.log'
        }
    }
}
