#Requires -Version 7.4
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $Apply,
    [object] $Connection,
    [uri] $RestrictedSiteUrl,
    [switch] $ConfirmRestrictedDevelopmentSite
)

$ErrorActionPreference = 'Stop'
$designPath = Join-Path (Split-Path $PSScriptRoot) 'sharepoint\case-management.design.json'
$design = Get-Content -LiteralPath $designPath -Raw | ConvertFrom-Json -AsHashtable
$ledger = [ordered]@{
    EventKey = @{ type = 'Text'; required = $true; unique = $true; indexed = $true }
    State = @{ type = 'Choice'; values = @('Processing', 'PendingIntegration', 'Failed', 'NeedsReconciliation') + $design.intakeLedgerAdditions.additionalStateChoices }
    OwnerRunId = @{ type = 'Text'; required = $true }
    ReceivedAt = @{ type = 'DateTime'; required = $true }
    UpdatedAt = @{ type = 'DateTime'; required = $true }
    EventPayload = @{ type = 'Note' }
    ResultPayload = @{ type = 'Note' }
    ConversationId = @{ type = 'Text' }
    ReviewState = @{ type = 'Choice'; values = @('RequiredNotAssigned', 'UnderReview', 'Resolved') }
    ErrorCode = @{ type = 'Text' }
    ErrorRunId = @{ type = 'Text' }
}
foreach ($key in $design.intakeLedgerAdditions.fields.Keys) {
    $ledger.Add($key, $design.intakeLedgerAdditions.fields[$key])
}
$lists = @(
    @{ title = 'OnboardingIntakeLedger'; template = 'GenericList'; fields = $ledger }
    @{ title = $design.cases.title; template = 'GenericList'; fields = $design.cases.fields }
    @{ title = $design.stageExecutions.title; template = 'GenericList'; fields = $design.stageExecutions.fields }
    @{ title = $design.evidenceLibrary.title; template = 'DocumentLibrary'; fields = $design.evidenceLibrary.fields }
)

function New-FieldXml([string] $Name, [System.Collections.IDictionary] $Definition) {
    $field = [xml] '<Field/>'
    $node = $field.DocumentElement
    $node.SetAttribute('Name', $Name)
    $node.SetAttribute('StaticName', $Name)
    $node.SetAttribute('DisplayName', $Name)
    $node.SetAttribute('Type', $Definition.type)
    foreach ($attribute in @{ required = 'Required'; unique = 'EnforceUniqueValues'; indexed = 'Indexed' }.GetEnumerator()) {
        if ($Definition[$attribute.Key]) { $node.SetAttribute($attribute.Value, 'TRUE') }
    }
    switch ($Definition.type) {
        'Choice' {
            $node.SetAttribute('FillInChoice', 'FALSE')
            $choices = $field.CreateElement('CHOICES')
            foreach ($value in $Definition.values) {
                $choice = $field.CreateElement('CHOICE')
                $choice.InnerText = $value
                [void] $choices.AppendChild($choice)
            }
            [void] $node.AppendChild($choices)
        }
        'DateTime' { $node.SetAttribute('Format', 'DateTime') }
        'Note' { $node.SetAttribute('RichText', 'FALSE') }
        'Number' {
            $node.SetAttribute('Decimals', [string] $Definition.decimals)
            $node.SetAttribute('Min', [string] $Definition.minimum)
        }
        'User' { $node.SetAttribute('UserSelectionMode', 'PeopleOnly') }
        'Text' {}
        default { throw "Unsupported SharePoint field type '$($Definition.type)' on $Name." }
    }
    $node.OuterXml
}

$plan = foreach ($list in $lists) {
    [pscustomobject]@{
        Title = $list.title
        Template = $list.template
        Fields = @($list.fields.GetEnumerator() | ForEach-Object {
            New-FieldXml $_.Key $_.Value
        })
    }
}
if (-not $Apply) {
    $plan
    return
}
if (-not $Connection -or -not $RestrictedSiteUrl.IsAbsoluteUri -or $RestrictedSiteUrl.Scheme -ne 'https' -or
    -not $ConfirmRestrictedDevelopmentSite) {
    throw 'Apply requires an authenticated PnP connection, explicit HTTPS site URL, and confirmation that this is a restricted development site.'
}
Import-Module PnP.PowerShell -ErrorAction Stop
$web = Get-PnPWeb -Includes Url -Connection $Connection
if ($web.Url.TrimEnd('/') -cne $RestrictedSiteUrl.AbsoluteUri.TrimEnd('/')) {
    throw 'The authenticated SharePoint web does not match the explicitly selected site URL.'
}
$existing = @(Get-PnPList -Connection $Connection)
foreach ($list in $plan) {
    if ($existing.Title -contains $list.Title -or @($existing | Where-Object { $_.RootFolder.Name -eq $list.Title }).Count) {
        throw "The list or library '$($list.Title)' already exists; use the reviewed migration procedure, not this new-site script."
    }
}
if (-not $PSCmdlet.ShouldProcess($web.Url, 'Create four onboarding lists/libraries with versioning')) { return }
foreach ($list in $plan) {
    $created = New-PnPList -Title $list.Title -Template $list.Template -EnableVersioning -Connection $Connection
    if ($list.Template -eq 'GenericList') {
        Set-PnPList -Identity $created.Id -EnableAttachments:$false -Connection $Connection | Out-Null
    }
    foreach ($field in $list.Fields) {
        Add-PnPFieldFromXml -List $created.Id -FieldXml $field -Connection $Connection | Out-Null
    }
    [pscustomobject]@{ Title = $list.Title; Id = $created.Id }
}
