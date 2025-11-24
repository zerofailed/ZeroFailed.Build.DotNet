function _getDotNetTestParamsForVsTest {
    $dotnetTestArgs = @(
        $SolutionToBuild
        "--verbosity", $LogLevel
    )

    $DotNetTestLoggers | ForEach-Object {
        $dotnetTestArgs += @("--logger", $_)
    }

    $dotnetTestArgs += "--test-adapter-path", (Join-Path $moduleDir "bin")
    $dotnetTestArgs += ($_fileLoggerProps ? $_fileLoggerProps : "/fl")

    return $dotnetTestArgs
}