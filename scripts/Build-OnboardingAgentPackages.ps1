#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $OutputDirectory,
    [string] $Pac = 'pac',
    [switch] $PrepareOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot

function Read-SourceJson([string] $Path) {
    Get-Content -LiteralPath (Join-Path $root $Path) -Raw | ConvertFrom-Json -AsHashtable
}

function Invoke-Pac {
    & $pacCommand @args | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "PAC $($args[0]) $($args[1]) failed (exit $LASTEXITCODE)." }
}

function Set-ScaffoldValue([string] $Text, [string] $Line, [string] $Replacement) {
    $pattern = [regex]::new('(?m)^' + [regex]::Escape($Line) + '$')
    if ($pattern.Matches($Text).Count -ne 1) { throw "Unexpected PAC scaffold: expected '$Line' once." }
    $pattern.Replace($Text, [System.Text.RegularExpressions.MatchEvaluator] { param($match) $Replacement }, 1)
}

function Read-ArchiveEntry([IO.Compression.ZipArchive] $Archive, [string] $Name) {
    $item = $Archive.GetEntry($Name)
    if ($null -eq $item) { throw "Solution ZIP is missing $Name." }
    $reader = [IO.StreamReader]::new($item.Open())
    try { $reader.ReadToEnd() } finally { $reader.Dispose() }
}

$components = Read-SourceJson 'deployment\components.json'
$specialists = Read-SourceJson 'specialists\agents.json'
$knowledge = Read-SourceJson 'knowledge\knowledge-manifest.json'
$v1 = Read-SourceJson 'orchestrator\config.example.json'
$v2 = Read-SourceJson 'orchestrator\v2\config.example.json'
if ($components.productionEnabled -ne $false -or $v2.enabled -ne $false -or
    $knowledge.productionEnabled -ne $false -or $knowledge.approvalStatus -ne 'not_approved' -or
    $knowledge.sharedSources.Count -ne 0 -or @($components.flows | Where-Object { $_.enabled -ne $false }).Count) {
    throw 'This build only supports the disabled development configuration with unbound knowledge.'
}

$roles = @('orchestrator') + @($specialists.agents.role)
if ($roles.Count -ne 6 -or ($roles | Sort-Object -Unique).Count -ne 6 -or
    $components.agents.Count -ne 6 -or ($components.agents.schemaName | Sort-Object -Unique).Count -ne 6 -or
    ($components.agents.solutionName | Sort-Object -Unique).Count -ne 6 -or
    (Compare-Object $roles $components.agents.role -CaseSensitive) -or
    (Compare-Object $specialists.agents.role @($knowledge.agents.Keys) -CaseSensitive)) {
    throw 'Expected one orchestrator, five distinct specialists and a matching knowledge inventory.'
}

$envVariables = [ordered]@{}
foreach ($source in @($v1.environmentVariables, $v2.environmentVariables, $components.additionalTextEnvironmentVariables)) {
    foreach ($key in $source.Keys) {
        if ($envVariables.Contains($key)) { throw "Duplicate environment variable $key." }
        $envVariables[$key] = $null
    }
}

$orchestrator = (Get-Content -LiteralPath (Join-Path $root 'orchestrator\agent-instructions.md') -Raw).Trim()
$common = (Get-Content -LiteralPath (Join-Path $root 'specialists\common-instructions.md') -Raw).Trim()
$common = $common -replace '(?m)^Authoring:[^\r\n]*\r?\n[^\r\n]*\r?\n[^\r\n]*\r?\n\r?\n', ''
$agents = foreach ($component in $components.agents) {
    $role = $component.role
    if ($role -cnotmatch '^[a-z]+(-[a-z]+)*$' -or
        $component.schemaName -cnotmatch '^onb_[A-Za-z0-9]+$' -or
        $component.solutionName -cnotmatch '^[A-Za-z][A-Za-z0-9]+$') {
        throw "Invalid package identifier for $role."
    }
    if ($role -ceq 'orchestrator') {
        $displayName = $component.displayName
        $instructions = $orchestrator
        $agentVariable = 'onb_AgentId'
        $sources = @()
    } else {
        $definition = $specialists.agents | Where-Object { $_.role -ceq $role }
        $displayName = $definition.displayName
        $instructions = $common + "`n`n" + (Get-Content -LiteralPath (Join-Path $root "specialists\$($definition.instructions)") -Raw).Trim()
        $agentVariable = $definition.agentIdVariable
        $sources = @($knowledge.agents[$role])
        if ($sources.Count -eq 0 -or (Compare-Object $sources @($definition.referenceSources | ForEach-Object { Split-Path $_ -Leaf }) -CaseSensitive)) {
            throw "Knowledge inventories disagree for $role."
        }
        foreach ($source in $sources) {
            if ($source -cnotmatch '^[A-Za-z0-9-]+\.md$' -or $source -in $knowledge.administrativeOnly -or
                -not (Test-Path -LiteralPath (Join-Path $root "knowledge\$source") -PathType Leaf)) {
                throw "Invalid knowledge source $source for $role."
            }
        }
    }
    if (-not $envVariables.Contains($agentVariable) -or [string]::IsNullOrWhiteSpace($instructions) -or
        [string]::IsNullOrWhiteSpace($displayName)) {
        throw "Missing agent inputs for $role."
    }
    [pscustomobject]@{
        Manifest = [ordered]@{
            role = $role
            displayName = $displayName
            schemaName = $component.schemaName
            solutionName = $component.solutionName
            instructionsFile = "authoring/$role.md"
            agentIdVariable = $agentVariable
            unboundKnowledge = $sources
        }
        Instructions = $instructions
    }
}

$output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw 'OutputDirectory must be a new path; no files are overwritten.' }
if (-not $PrepareOnly) {
    $pacCommand = (Get-Command $Pac -CommandType Application -ErrorAction Stop).Source
    $help = & $pacCommand copilot help | Out-String
    if ($LASTEXITCODE -ne 0 -or $help -notmatch '\binit\b' -or $help -notmatch '\bpack\b') {
        throw 'Install a Power Platform CLI version exposing pac copilot init and pack.'
    }
}
[void] [IO.Directory]::CreateDirectory((Join-Path $output 'authoring'))
$manifest = [ordered]@{
    artifactKind = 'onboarding-build-inventory-not-a-solution'
    releaseSolution = $components.releaseSolution
    productionEnabled = $false
    agents = @($agents.Manifest)
    unboundTextEnvironmentVariables = $envVariables
    unboundConnectionReferenceRoles = $components.connectionReferenceRoles
    flowsToAuthorInTenant = $components.flows
}
foreach ($agent in $agents) {
    Set-Content -LiteralPath (Join-Path $output $agent.Manifest.instructionsFile) -Value $agent.Instructions -Encoding utf8 -NoNewline
}
$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $output 'component-inventory.json') -Encoding utf8
if ($PrepareOnly) {
    Write-Output "Prepared six agent instruction files and the unbound inventory in $output. No solution ZIPs were built."
    return
}

foreach ($agent in $agents) {
    $entry = $agent.Manifest
    $workspace = Join-Path $output "workspaces\$($entry.role)"
    $zipDirectory = Join-Path $output "packages\$($entry.role)"
    [void] [IO.Directory]::CreateDirectory($workspace)
    [void] [IO.Directory]::CreateDirectory($zipDirectory)
    $placeholder = 'ONBOARDING_INSTRUCTIONS_REPLACE_ME'
    Invoke-Pac copilot init --name $entry.displayName --publisher-prefix $components.publisherPrefix `
        --schema-name $entry.schemaName --project-dir $workspace --authoring-mode classic --template minimal --instructions $placeholder

    # PAC's Windows argument parser cannot reliably pass multiline YAML content.
    $agentFile = Join-Path $workspace 'agent.mcs.yml'
    $yaml = (Get-Content -LiteralPath $agentFile -Raw) -replace '\r\n', "`n"
    $instructionBlock = ($agent.Instructions -split '\r?\n' | ForEach-Object { if ($_ -ne '') { "  $_" } else { '' } }) -join "`n"
    $yaml = Set-ScaffoldValue $yaml "instructions: $placeholder" "instructions: |-`n$instructionBlock"
    $yaml = Set-ScaffoldValue $yaml '  webBrowsing: true' '  webBrowsing: false'
    Set-Content -LiteralPath $agentFile -Value $yaml -Encoding utf8 -NoNewline
    $settingsFile = Join-Path $workspace 'settings.mcs.yml'
    $yaml = (Get-Content -LiteralPath $settingsFile -Raw) -replace '\r\n', "`n"
    foreach ($setting in '    useModelKnowledge', '    isFileAnalysisEnabled', '  isAgentConnectable') {
        $yaml = Set-ScaffoldValue $yaml "${setting}: true" "${setting}: false"
    }
    Set-Content -LiteralPath $settingsFile -Value $yaml -Encoding utf8 -NoNewline
    Invoke-Pac copilot pack --publisher-prefix $components.publisherPrefix --project-dir $workspace `
        --solution-name $entry.solutionName --output-path $zipDirectory
    $zip = @(Get-ChildItem -LiteralPath $zipDirectory -Filter '*.zip' -File)
    if ($zip.Count -ne 1) { throw "PAC did not write exactly one solution ZIP for $($entry.role)." }
    $archive = [IO.Compression.ZipFile]::OpenRead($zip[0].FullName)
    try {
        foreach ($required in 'solution.xml', 'customizations.xml', '[Content_Types].xml') {
            if ($null -eq $archive.GetEntry($required)) { throw "Solution ZIP for $($entry.role) is missing $required." }
        }
        [xml] $solution = Read-ArchiveEntry $archive 'solution.xml'
        if ($solution.ImportExportXml.SolutionManifest.UniqueName -cne $entry.solutionName) {
            throw "Unexpected solution unique name in package for $($entry.role)."
        }
        $schema = $entry.schemaName
        $gpt = (Read-ArchiveEntry $archive "botcomponents/$schema.gpt.default/data") -replace '\r\n', "`n"
        $configuration = (Read-ArchiveEntry $archive "bots/$schema/configuration.json") | ConvertFrom-Json
        if (-not $gpt.Contains("instructions: |-`n$instructionBlock`ngptCapabilities:") -or
            $gpt -cnotmatch '(?m)^  webBrowsing: false$' -or
            $configuration.isAgentConnectable -ne $false -or
            $configuration.aISettings.useModelKnowledge -ne $false -or
            $configuration.aISettings.isFileAnalysisEnabled -ne $false) {
            throw "Packaged instructions or capability restrictions differ from the build inputs for $($entry.role)."
        }
    } finally { $archive.Dispose() }
}
Write-Output "Built six agent-only solution ZIPs in $output. Tenant import has not been tested."
