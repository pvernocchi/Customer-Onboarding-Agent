#Requires -Version 7.4
param([switch]$UpdatePreviews)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'notifications\ResultsEmail.psm1') -Force
$jsonOptions = @{ AsHashtable = $true }
if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
    $jsonOptions.DateKind = 'String'
}

function Assert-Check([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Copy-Value($Value) {
    return $Value | ConvertTo-Json -Depth 20 | ConvertFrom-Json @jsonOptions
}
function Assert-Rejected([scriptblock]$Action, [string]$Message) {
    $rejected = $false
    try { & $Action | Out-Null } catch { $rejected = $true }
    Assert-Check $rejected $Message
}

$examples = Join-Path $root 'notifications\examples'
$success = Get-Content (Join-Path $examples 'success.json') -Raw | ConvertFrom-Json @jsonOptions
$failure = Get-Content (Join-Path $examples 'failure.json') -Raw | ConvertFrom-Json @jsonOptions
# Independently configured synthetic URLs, not taken from the payload being checked.
$successUrl = 'https://bank.example.invalid/sites/onboarding/Lists/OnboardingCases/DispForm.aspx?ID=42'
$failureUrl = 'https://bank.example.invalid/sites/onboarding/Lists/OnboardingCases/DispForm.aspx?ID=43'
foreach ($name in @('success', 'failure')) {
    $payload = if ($name -eq 'success') { $success } else { $failure }
    $url = if ($name -eq 'success') { $successUrl } else { $failureUrl }
    $html = ConvertTo-ResultsEmailHtml -Payload $payload -AuthorizedCaseUrl $url
    $previewPath = Join-Path $examples "$name.html"
    if ($UpdatePreviews) { [IO.File]::WriteAllText($previewPath, $html.Replace("`r`n", "`n")) }
    $preview = (Get-Content $previewPath -Raw).Replace("`r`n", "`n")
    Assert-Check ($preview -ceq $html.Replace("`r`n", "`n")) "Stale $name preview; regenerate with -UpdatePreviews."
    Assert-Check ($html.Contains($payload.caseId) -and $html.Contains($payload.customerName)) 'Missing case/customer.'
    Assert-Check ([regex]::Matches($html, '<tr><td>DOC-').Count -eq $payload.documents.Count) 'Missing document row.'
    foreach ($document in $payload.documents) {
        Assert-Check ($html.Contains($document.documentRef)) 'Document reference lost.'
    }
    Assert-Check ($html.Contains('not customer approval') -and $html.Contains('bank sign-in')) 'Missing decision/access boundary.'
    Assert-Check ($html -notmatch '<script|<img|<iframe|<form') 'Active or remote content in email.'
}
Assert-Check ((Get-Content (Join-Path $examples 'failure.html') -Raw).Contains(
    'Document is outside the accepted validity period')) 'Failed-document reason missing.'

$hold = Copy-Value $success
$hold.documents[1].status = 'failed_validation'
$hold.documents[1].reasonCode = 'document_unreadable'
$hold.outcome = 'business_hold'
$hold.runReasons = @('evidence_required')
Assert-ResultsEmail $hold $successUrl
$restricted = Copy-Value $success
$restricted.outcome = 'requires_restricted_review'
$restricted.restrictedReview = $true
$restricted.runReasons = @('restricted_review')
$restrictedHtml = ConvertTo-ResultsEmailHtml $restricted $successUrl
Assert-Check ($restrictedHtml.Contains('Requires restricted review')) 'Neutral restricted hold missing.'
foreach ($word in @('possible_match', 'sanctions', 'suspicion', 'PEP', 'screeningAssessments')) {
    Assert-Check (-not $restrictedHtml.Contains($word)) 'Restricted detail leaked to email.'
}

$invalid = Copy-Value $failure
$invalid.outcome = 'validation_passed_draft'
Assert-Rejected { Assert-ResultsEmail $invalid $failureUrl } 'Technical failure accepted as pass.'
$invalid = Copy-Value $failure
$invalid.outcome = 'business_hold'
$invalid.restrictedReview = $false
$invalid.runReasons = @('evidence_required')
Assert-Rejected { Assert-ResultsEmail $invalid $failureUrl } 'Document-level technical/restricted hold erased.'
$invalid = Copy-Value $success
$invalid.outcome = 'technical_failure'
$invalid.runReasons = @('human_review_required')
Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } 'Technical failure without technical reason accepted.'
$invalid = Copy-Value $hold
$invalid.documents[1].reasonCode = 'none'
Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } 'Failed document without reason accepted.'
$invalid = Copy-Value $success
$invalid.documents[1].documentRef = $invalid.documents[0].documentRef
Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } 'Duplicate document reference accepted.'
$invalid = Copy-Value $success
$invalid.completedAt = '2026-02-30T07:00:00Z'
Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } 'Impossible timestamp accepted.'
$invalid = Copy-Value $success
$invalid.eventId = 'unbound-case-event'
Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } 'Uncorrelated event identity accepted.'
$invalid = Copy-Value $success
$invalid.caseUrl = 'https://external.example.invalid/collect'
Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } 'Untrusted case link accepted.'
Assert-Rejected { Assert-ResultsEmail $success $failureUrl } 'Cross-case authorized URL accepted.'
$invalid = Copy-Value $success
$invalid.customerName = "Synthetic`r`nBcc: external@example.invalid"
Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } 'Control characters accepted.'
foreach ($property in @('recipients', 'screeningAssessments', 'identityNumber', 'attachments')) {
    $invalid = Copy-Value $success
    $invalid[$property] = 'must-not-be-exported'
    Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } "Unexpected $property accepted."
}
$invalid = Copy-Value $restricted
$invalid.documents[0].status = 'requires_restricted_review'
$invalid.documents[0].reasonCode = 'possible_match'
Assert-Rejected { Assert-ResultsEmail $invalid $successUrl } 'Sensitive reason accepted.'

$escaped = Copy-Value $success
$escaped.customerName = '<script>alert("synthetic")</script> & {{outcome}}'
$escapedHtml = ConvertTo-ResultsEmailHtml $escaped $successUrl
Assert-Check ($escapedHtml.Contains('&lt;script&gt;') -and $escapedHtml.Contains('&amp; {{outcome}}') -and
    -not $escapedHtml.Contains('<script>')) 'HTML or recursive template injection.'
$schema = Get-Content (Join-Path $root 'notifications\results-email.schema.json') -Raw | ConvertFrom-Json -AsHashtable
$specialist = Get-Content (Join-Path $root 'specialists\contracts\specialist-result.schema.json') -Raw | ConvertFrom-Json -AsHashtable
$documentTypes = $specialist.allOf[0].then.properties.payload.properties.documentType.enum
Assert-Check (($schema.properties.documents.items.properties.documentType.enum -join '|') -ceq
    ($documentTypes -join '|')) 'Document types drifted from specialist contract.'
Write-Output 'Results email schema, fail-closed projection, HTML safety and synthetic previews passed (local only).'
