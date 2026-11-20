#Requires -Version 7.4
$ErrorActionPreference = 'Stop'

function Assert-ResultsEmail {
    param(
        [Parameter(Mandatory)][hashtable]$Payload,
        [Parameter(Mandatory)][string]$AuthorizedCaseUrl
    )
    $valid = Test-Json -Json ($Payload | ConvertTo-Json -Depth 20 -Compress) `
        -SchemaFile (Join-Path $PSScriptRoot 'results-email.schema.json') -ErrorAction SilentlyContinue
    if (-not $valid) { throw 'Results email schema rejected the projection.' }

    $uri = $null
    if (-not [Uri]::TryCreate($AuthorizedCaseUrl, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -cne 'https' -or $uri.UserInfo -or $uri.Fragment -or
        $Payload.caseUrl -cne $AuthorizedCaseUrl) {
        throw 'Case link does not match the independently authorized HTTPS case URL.'
    }
    $date = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParseExact($Payload.completedAt, "yyyy-MM-dd'T'HH:mm:ss'Z'",
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$date)) {
        throw 'Completion timestamp is not an actual UTC calendar timestamp.'
    }
    $guid = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
    if ($Payload.eventId -cnotmatch "^sp-created:v1:(?:${guid}:){3}[1-9][0-9]{0,9}$" -or
        [long]($Payload.eventId.Split(':')[-1]) -gt 2147483647) {
        throw 'Invalid canonical intake event identity.'
    }
    $refs = @($Payload.documents | ForEach-Object documentRef)
    if (@($refs | Sort-Object -Unique -CaseSensitive).Count -ne $refs.Count) {
        throw 'Duplicate run-local document reference.'
    }
    $technical = ($Payload.runReasons -ccontains 'technical_error') -or
        (@($Payload.documents | Where-Object status -CEQ technical_failure).Count -gt 0)
    $restricted = ($Payload.runReasons -ccontains 'restricted_review') -or
        (@($Payload.documents | Where-Object status -CEQ requires_restricted_review).Count -gt 0)
    if ($restricted -ne $Payload.restrictedReview) {
        throw 'Restricted-review flag does not preserve the neutral hold.'
    }
    $hold = ($Payload.runReasons.Count -gt 0) -or
        (@($Payload.documents | Where-Object status -CNE validation_passed_draft).Count -gt 0)
    $expected = if ($technical) { 'technical_failure' }
        elseif ($restricted) { 'requires_restricted_review' }
        elseif ($hold) { 'business_hold' }
        else { 'validation_passed_draft' }
    if ($Payload.outcome -cne $expected) {
        throw 'Overall outcome does not preserve technical failures and business/restricted holds.'
    }
}

function ConvertTo-ResultsEmailHtml {
    param(
        [Parameter(Mandatory)][hashtable]$Payload,
        [Parameter(Mandatory)][string]$AuthorizedCaseUrl
    )
    Assert-ResultsEmail -Payload $Payload -AuthorizedCaseUrl $AuthorizedCaseUrl
    $statuses = @{
        validation_passed_draft = 'Validation passed - draft'
        failed_validation = 'Document validation failed - business hold'
        not_validated = 'Not validated - business hold'
        technical_failure = 'Technical failure - not a pass'
        requires_restricted_review = 'Requires restricted review'
        business_hold = 'Business hold - human action required'
    }
    $reasons = @{
        none = 'Configured document checks passed; human review still required.'
        document_unreadable = 'Document could not be read; obtain a legible replacement.'
        required_information_missing = 'Required information is missing; review the secured case.'
        document_out_of_date = 'Document is outside the accepted validity period; obtain current evidence.'
        conflicting_information = 'Information conflicts with other evidence; review the secured case.'
        not_evaluated = 'Not evaluated because processing stopped before this check.'
        configuration_unavailable = 'Required configuration is unavailable; checks were not performed.'
        processing_error = 'Processing could not complete; operations must investigate in the secured case.'
        restricted_review = 'Requires restricted review; see the secured case.'
        evidence_required = 'Additional evidence or correction is required.'
        configuration_required = 'Required configuration must be approved before processing can continue.'
        human_review_required = 'Human review is required before processing can continue.'
        technical_error = 'A technical failure prevented completion of one or more checks.'
    }
    $types = @{
        identity_document = 'Identity document'; residence_permit = 'Residence permit'
        proof_of_address = 'Proof of address'; application_form = 'Application form'
        tax_self_certification = 'Tax self-certification'; source_of_funds_evidence = 'Source of funds evidence'
        source_of_wealth_evidence = 'Source of wealth evidence'; register_extract = 'Register extract'
        certificate_of_incorporation = 'Certificate of incorporation'; articles_of_association = 'Articles of association'
        shareholder_register = 'Shareholder register'; ownership_chart = 'Ownership chart'
        ubo_declaration = 'UBO declaration'; board_resolution = 'Board resolution'
        power_of_attorney = 'Power of attorney'; trust_deed = 'Trust deed'
        financial_statements = 'Financial statements'; licence_or_authorisation = 'Licence or authorisation'
        bank_reference = 'Bank reference'; other_supporting = 'Supporting document'; unclassified = 'Unclassified document'
    }
    $rows = foreach ($document in $Payload.documents) {
        $label = [System.Net.WebUtility]::HtmlEncode("$($document.documentRef) - $($types[$document.documentType])")
        $status = [System.Net.WebUtility]::HtmlEncode($statuses[$document.status])
        $reason = [System.Net.WebUtility]::HtmlEncode($reasons[$document.reasonCode])
        "<tr><td>$label</td><td>$status</td><td>$reason</td></tr>"
    }
    $summary = if ($Payload.runReasons.Count) {
        ($Payload.runReasons | ForEach-Object { $reasons[$_] }) -join ' '
    } else { 'All required configured checks passed for this run; draft ready for human review.' }
    $restrictedText = if ($Payload.restrictedReview) {
        'Requires restricted review. Details are available only to authorized reviewers in the secured case.'
    } else { 'Final review and any onboarding decision remain with authorized bank staff.' }
    $tokens = @{
        caseId = $Payload.caseId; customerName = $Payload.customerName
        outcome = $statuses[$Payload.outcome]; completedAt = $Payload.completedAt
        runId = $Payload.runId; caseRevision = [string]$Payload.caseRevision
        runReasons = $summary; restrictedReview = $restrictedText; caseUrl = $Payload.caseUrl
    }
    $template = Get-Content (Join-Path $PSScriptRoot 'results-email.html') -Raw
    return [regex]::Replace($template, '\{\{([A-Za-z]+)\}\}', {
        param($match)
        $key = $match.Groups[1].Value
        if ($key -ceq 'documentRows') { return $rows -join "`n" }
        if (-not $tokens.ContainsKey($key)) { throw "Unknown template token: $key" }
        return [System.Net.WebUtility]::HtmlEncode([string]$tokens[$key])
    })
}

Export-ModuleMember -Function Assert-ResultsEmail, ConvertTo-ResultsEmailHtml
