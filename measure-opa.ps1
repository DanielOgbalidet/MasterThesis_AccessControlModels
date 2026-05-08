param(
    [string]$User = "anne",
    [string]$Action = "write",
    [string]$Resource = "doc1",
    [string]$Model = "rbac",
    [string]$Level = "level1",
    [string]$Time = "",
    [string]$Location = "",
    [string]$OpaUrl = "http://localhost:8181/v1/data/authz/allow?metrics=true",
    [int]$Iterations = 30
)

function Get-Percentile {
    param(
        [double[]]$Values,
        [double]$Percentile
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return $null
    }

    $sorted = $Values | Sort-Object
    $index = [math]::Ceiling(($Percentile / 100.0) * $sorted.Count) - 1
    if ($index -lt 0) { $index = 0 }
    if ($index -ge $sorted.Count) { $index = $sorted.Count - 1 }
    return $sorted[$index]
}

function Get-Median {
    param([double[]]$Values)

    if (-not $Values -or $Values.Count -eq 0) {
        return $null
    }

    $sorted = $Values | Sort-Object
    $count = $sorted.Count

    if ($count % 2 -eq 1) {
        return $sorted[[int]($count / 2)]
    } else {
        $mid1 = $sorted[($count / 2) - 1]
        $mid2 = $sorted[$count / 2]
        return ($mid1 + $mid2) / 2.0
    }
}

function NsToMs {
    param([double]$Ns)
    return $Ns / 1000000.0
}

$inputObject = @{
    user = $User
    action = $Action
    resource = $Resource
    model = $Model
    level = $Level
}

if ($Time -ne "") {
    $inputObject.time = $Time
}

if ($Location -ne "") {
    $inputObject.location = $Location
}

$bodyObject = @{
    input = $inputObject
}

$bodyJson = $bodyObject | ConvertTo-Json -Depth 5

$queryEvalNs = @()
$inputParseNs = @()
$serverHandlerNs = @()
$results = @()

Write-Host "Running $Iterations OPA measurements for:"
Write-Host "  user     = $User"
Write-Host "  action   = $Action"
Write-Host "  resource = $Resource"
Write-Host "  url      = $OpaUrl"
Write-Host ""

for ($i = 1; $i -le $Iterations; $i++) {
    try {
        $response = Invoke-RestMethod `
            -Method Post `
            -Uri $OpaUrl `
            -ContentType "application/json" `
            -Body $bodyJson

        $metrics = $response.metrics
        $result = $response.result

        if ($null -ne $metrics.timer_rego_query_eval_ns) {
            $queryEvalNs += [double]$metrics.timer_rego_query_eval_ns
        }

        if ($null -ne $metrics.timer_rego_input_parse_ns) {
            $inputParseNs += [double]$metrics.timer_rego_input_parse_ns
        }

        if ($null -ne $metrics.timer_server_handler_ns) {
            $serverHandlerNs += [double]$metrics.timer_server_handler_ns
        }

        $results += $result

        Write-Host ("[{0}/{1}] result={2} eval={3:N3} ms parse={4:N3} ms handler={5:N3} ms" -f `
            $i,
            $Iterations,
            $result,
            (NsToMs([double]$metrics.timer_rego_query_eval_ns)),
            (NsToMs([double]$metrics.timer_rego_input_parse_ns)),
            (NsToMs([double]$metrics.timer_server_handler_ns))
        )
    }
    catch {
        Write-Warning "Request $i failed: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "========== SUMMARY =========="

if ($queryEvalNs.Count -gt 0) {
    $avgEval = ($queryEvalNs | Measure-Object -Average).Average
    $medEval = Get-Median -Values $queryEvalNs
    $p95Eval = Get-Percentile -Values $queryEvalNs -Percentile 95

    Write-Host ("Policy evaluation time (timer_rego_query_eval_ns):")
    Write-Host ("  avg    = {0:N3} ms" -f (NsToMs $avgEval))
    Write-Host ("  median = {0:N3} ms" -f (NsToMs $medEval))
    Write-Host ("  p95    = {0:N3} ms" -f (NsToMs $p95Eval))
}

if ($inputParseNs.Count -gt 0) {
    $avgParse = ($inputParseNs | Measure-Object -Average).Average
    Write-Host ("Input parse time (timer_rego_input_parse_ns):")
    Write-Host ("  avg    = {0:N3} ms" -f (NsToMs $avgParse))
}

if ($serverHandlerNs.Count -gt 0) {
    $avgHandler = ($serverHandlerNs | Measure-Object -Average).Average
    $medHandler = Get-Median -Values $serverHandlerNs
    $p95Handler = Get-Percentile -Values $serverHandlerNs -Percentile 95

    Write-Host ("OPA handler time (timer_server_handler_ns):")
    Write-Host ("  avg    = {0:N3} ms" -f (NsToMs $avgHandler))
    Write-Host ("  median = {0:N3} ms" -f (NsToMs $medHandler))
    Write-Host ("  p95    = {0:N3} ms" -f (NsToMs $p95Handler))
}

$trueCount = ($results | Where-Object { $_ -eq $true }).Count
$falseCount = ($results | Where-Object { $_ -eq $false }).Count

Write-Host ("Decision results:")
Write-Host ("  allow = $trueCount")
Write-Host ("  deny  = $falseCount")
Write-Host ("  model    = $Model")
Write-Host ("  level    = $Level")