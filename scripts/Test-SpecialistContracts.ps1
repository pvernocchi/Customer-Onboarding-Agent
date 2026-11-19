#Requires -Version 7.4
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$guidPattern = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
$eventPattern = "^sp-created:v1:(?:${guidPattern}:){3}[1-9][0-9]{0,9}$"
$manifest = Get-Content (Join-Path $root 'specialists\agents.json') -Raw | ConvertFrom-Json -AsHashtable
$knowledge = Get-Content (Join-Path $root 'knowledge\knowledge-manifest.json') -Raw | ConvertFrom-Json -AsHashtable

function Assert-Check([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Copy-Value($Value) {
    return $Value | ConvertTo-Json -Depth 40 | ConvertFrom-Json -AsHashtable
}
function Assert-Schema($Value, [string]$Path) {
    $valid = Test-Json -Json ($Value | ConvertTo-Json -Depth 40 -Compress) `
        -SchemaFile (Join-Path $root $Path) -ErrorAction SilentlyContinue
    Assert-Check $valid "Schema rejected $Path"
}
function Assert-EventId([string]$Id) {
    Assert-Check ($Id -cmatch $eventPattern) 'Invalid canonical event identity'
    Assert-Check ([long]($Id.Split(':')[-1]) -le 2147483647) 'Item ID outside supported range'
}
function Assert-SameSet($Left, $Right, [string]$Message) {
    $leftValues = @($Left | Sort-Object -CaseSensitive)
    $rightValues = @($Right | Sort-Object -CaseSensitive)
    Assert-Check (($leftValues.Count -eq $rightValues.Count) -and
        (($leftValues -join "`0") -ceq ($rightValues -join "`0"))) $Message
}
function Get-OperationKey($Request) {
    return '{0}:g{1}:r{2}:s{3}:{4}:i{5}' -f $Request.eventId,
        $Request.eventGeneration, $Request.caseContext.revision,
        $Request.caseContext.subjectSetVersion, $Request.role, $Request.instructionVersion
}
function Get-Evidence($Request, [string]$Id) {
    $matches = @($Request.evidence | Where-Object { $_.evidenceId -ceq $Id })
    Assert-Check ($matches.Count -eq 1) 'Unknown or duplicate evidence reference'
    return $matches[0]
}
function Assert-Request($Request) {
    Assert-Schema $Request 'specialists\contracts\specialist-request.schema.json'
    Assert-EventId $Request.eventId
    Assert-Check ($Request.operationKey -ceq (Get-OperationKey $Request)) 'Operation correlation mismatch'
    $case = $Request.caseContext
    foreach ($collection in @('subjects', 'evidence')) {
        $field = if ($collection -eq 'subjects') { 'subjectRef' } else { 'evidenceId' }
        $ids = @($Request[$collection] | ForEach-Object { $_[$field] })
        Assert-Check (@($ids | Sort-Object -Unique -CaseSensitive).Count -eq $ids.Count) 'Duplicate scoped reference'
        foreach ($item in $Request[$collection]) {
            Assert-Check ($item.caseId -ceq $case.caseId) 'Cross-case input'
        }
    }
    $customers = @($Request.subjects | Where-Object { $_.roles -ccontains 'customer' })
    $customerKind = if ($case.caseType -eq 'individual') { 'person' } else { 'business' }
    Assert-Check (($customers.Count -eq 1) -and ($customers[0].kind -ceq $customerKind)) 'Authoritative customer subject missing/ambiguous'
    foreach ($subject in $Request.subjects) {
        if ($subject.kind -eq 'business') {
            Assert-Check (@($subject.roles | Where-Object { $_ -notin @('customer', 'ownership_entity') }).Count -eq 0) 'Business cannot be a natural-person role'
        } else {
            Assert-Check ($subject.roles -cnotcontains 'ownership_entity') 'Person cannot be an ownership entity'
        }
    }
    foreach ($item in $Request.evidence) {
        foreach ($subjectRef in $item.subjectRefs) {
            Assert-Check (@($Request.subjects.subjectRef) -ccontains $subjectRef) 'Evidence linked to unknown subject'
        }
        $date = [DateTimeOffset]::MinValue
        Assert-Check ([DateTimeOffset]::TryParse($item.capturedAt,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None, [ref]$date)) 'Impossible evidence timestamp'
        if ($item.sourceKind -eq 'approved_provider') {
            $approved = @('documentExtractor', 'identityProvider', 'businessProvider', 'screeningProvider', 'policyRules') |
                ForEach-Object { $Request.configuration[$_] }
            Assert-Check ($approved -ccontains $item.sourceSystemId) 'Unconfigured provider source'
        }
    }
    foreach ($key in $Request.upstreamOperationKeys) {
        Assert-Check ($key.StartsWith("$($Request.eventId):g$($Request.eventGeneration):", [StringComparison]::Ordinal)) 'Unrelated upstream event/generation'
    }
    $people = @($Request.subjects | Where-Object kind -EQ person | ForEach-Object subjectRef)
    switch ($Request.role) {
        'document-evidence' {
            $source = Get-Evidence $Request $Request.task.documentEvidenceId
            Assert-Check ($source.sourceKind -eq 'uploaded_document') 'Document task requires uploaded-document evidence'
        }
        'natural-person' {
            Assert-SameSet $Request.task.personSubjectRefs $people 'Omitted/extra person in identity task'
        }
        'business' {
            Assert-Check ($Request.task.businessSubjectRef -ceq $customers[0].subjectRef) 'Wrong business customer'
        }
        'financial-crime' {
            Assert-SameSet $Request.task.subjectRefs @($Request.subjects.subjectRef) 'Omitted/extra screening subject'
            $reportPeople = @($Request.task.screeningReports | ForEach-Object subjectRef)
            Assert-Check (@($reportPeople | Sort-Object -Unique -CaseSensitive).Count -eq $reportPeople.Count) 'Duplicate normalized screening report'
            foreach ($report in $Request.task.screeningReports) {
                Assert-Check ($Request.task.subjectRefs -ccontains $report.subjectRef) 'Out-of-scope screening report'
                $source = Get-Evidence $Request $report.evidenceId
                Assert-Check (($source.contentState -eq 'available') -and
                    ($source.sourceKind -eq 'approved_provider') -and
                    ($source.sourceSystemId -ceq $Request.configuration.screeningProvider) -and
                    ($source.subjectRefs -ccontains $report.subjectRef)) 'Invalid screening source/subject'
            }
        }
        'risk-review' {
            if ($null -ne $Request.task.assessmentSnapshotRef) {
                $snapshots = @($Request.evidence | Where-Object {
                    ($_.sourceRecordRef -ceq $Request.task.assessmentSnapshotRef) -and
                    ($_.sourceKind -eq 'prior_stage') -and ($_.contentState -eq 'available')
                })
                Assert-Check ($snapshots.Count -eq 1) 'Missing/ambiguous assessment snapshot'
            }
            foreach ($finding in $Request.task.approvedRuleFindings) {
                Assert-Check (($null -ne $Request.configuration.policyRules) -and
                    ($finding.policyVersion -ceq $Request.configuration.policyVersion)) 'Unconfigured/mismatched policy finding'
                foreach ($id in $finding.evidenceIds) {
                    $source = Get-Evidence $Request $id
                    Assert-Check (($source.contentState -eq 'available') -and
                        ($source.sourceKind -in @('bank_policy', 'approved_provider')) -and
                        ($source.sourceSystemId -ceq $Request.configuration.policyRules)) 'Wrong policy-rule report source'
                }
            }
        }
    }
}
function Assert-Pair($Request, $Result) {
    Assert-Request $Request
    Assert-Schema $Result 'specialists\contracts\specialist-result.schema.json'
    foreach ($field in @('schemaVersion', 'instructionVersion', 'operationKey', 'eventId', 'eventGeneration', 'role')) {
        Assert-Check ($Result[$field] -ceq $Request[$field]) "Result $field mismatch"
    }
    Assert-Check (($Result.caseId -ceq $Request.caseContext.caseId) -and
        ($Result.caseRevision -eq $Request.caseContext.revision) -and
        ($Result.subjectSetVersion -eq $Request.caseContext.subjectSetVersion)) 'Stale or cross-case result'
    foreach ($field in @('policyVersion', 'countryRulesVersion')) {
        Assert-Check ($Result[$field] -ceq $Request.configuration[$field]) 'Result policy-version mismatch'
    }
    foreach ($id in $Result.evidenceUsed) {
        Assert-Check ((Get-Evidence $Request $id).contentState -eq 'available') 'Unavailable evidence used'
    }
    foreach ($citation in $Result.knowledgeReferences) {
        Assert-Check (($knowledge.approvalStatus -eq 'approved') -and $knowledge.productionEnabled -and
            ($citation.packVersion -ceq $Request.configuration.knowledgePackVersion) -and
            ($citation.packVersion -ceq $knowledge.packVersion) -and
            ($knowledge.agents[$Request.role] -ccontains $citation.file)) 'Unapproved/unmapped knowledge citation'
        $text = Get-Content (Join-Path $root "knowledge\$($citation.file)") -Raw
        Assert-Check ($text.Contains($citation.sectionId, [StringComparison]::Ordinal)) 'Invented knowledge section'
    }
    $agent = @($manifest.agents | Where-Object role -EQ $Request.role)[0]
    $missingBinding = $null -eq $Request.configuration[$agent.requiredBinding]
    if ($missingBinding) {
        $issue = @{
            'document-evidence' = 'document_extractor_not_configured'; 'natural-person' = 'identity_provider_not_configured'
            'business' = 'business_provider_not_configured'; 'financial-crime' = 'screening_provider_not_configured'
            'risk-review' = 'policy_rules_not_configured'
        }[$Request.role]
        Assert-Check (($Result.status -eq 'blocked_pending_configuration') -and
            ($Result.issues -ccontains $issue) -and ($Result.evidenceUsed.Count -eq 0)) 'Unconfigured role claimed progress'
    }
    if (($null -eq $Request.configuration.policyVersion) -or ($null -eq $Request.configuration.countryRulesVersion)) {
        Assert-Check ($Result.status -eq 'blocked_pending_configuration') 'Missing policy presented as usable draft'
    }
    switch ($Request.role) {
        'document-evidence' {
            if ($missingBinding) {
                Assert-Check (($Result.payload.documentType -eq 'unclassified') -and
                    ($null -eq $Result.payload.formCode) -and ($Result.payload.extractions.Count -eq 0)) 'Unconfigured extractor invented content'
            }
            foreach ($extraction in $Result.payload.extractions) {
                $source = Get-Evidence $Request $extraction.evidenceId
                Assert-Check (($source.evidenceId -ceq $Request.task.documentEvidenceId) -and
                    ($Result.evidenceUsed -ccontains $source.evidenceId) -and
                    ($source.sourceRecordRef -ceq $extraction.valueRef) -and
                    ($source.locators -ccontains $extraction.locator)) 'Invented extraction value/source/locator reference'
            }
        }
        'natural-person' {
            Assert-SameSet @($Result.payload.personAssessments.subjectRef) $Request.task.personSubjectRefs 'Omitted/extra person assessment'
            foreach ($assessment in $Result.payload.personAssessments) {
                if ($missingBinding) {
                    Assert-Check (($assessment.assessment -eq 'not_assessed') -and ($assessment.providerEvidenceIds.Count -eq 0)) 'Unconfigured identity result'
                }
                foreach ($id in $assessment.providerEvidenceIds) {
                    $source = Get-Evidence $Request $id
                    Assert-Check (($source.sourceKind -eq 'approved_provider') -and
                        ($source.sourceSystemId -ceq $Request.configuration.identityProvider) -and
                        ($source.subjectRefs -ccontains $assessment.subjectRef) -and
                        ($Result.evidenceUsed -ccontains $id)) 'Wrong identity provider evidence'
                }
                if ($assessment.assessment -eq 'provider_report_requires_review') {
                    Assert-Check ($assessment.providerEvidenceIds.Count -gt 0) 'Provider assessment without report'
                }
            }
        }
        'business' {
            Assert-Check ($Result.payload.businessSubjectRef -ceq $Request.task.businessSubjectRef) 'Business assessment mismatch'
            if ($missingBinding) {
                Assert-Check (($Result.payload.registryAssessment -eq 'not_assessed') -and
                    ($Result.payload.ownershipDiscovery -eq 'not_assessed') -and
                    ($Result.payload.relatedPeople.Count -eq 0)) 'Unconfigured business result'
            }
            foreach ($person in $Result.payload.relatedPeople) {
                $sourcePerson = @($Request.subjects | Where-Object { $_.subjectRef -ceq $person.subjectRef })
                Assert-Check (($sourcePerson.Count -eq 1) -and ($sourcePerson[0].kind -eq 'person')) 'Invented business-related person'
                foreach ($id in $person.evidenceIds) {
                    Assert-Check ($Result.evidenceUsed -ccontains $id) 'Unsupported ownership evidence'
                }
            }
            if ($Result.payload.registryAssessment -eq 'provider_report_requires_review') {
                $reports = @($Request.evidence | Where-Object {
                    ($_.sourceKind -eq 'approved_provider') -and
                    ($_.sourceSystemId -ceq $Request.configuration.businessProvider) -and
                    ($_.subjectRefs -ccontains $Request.task.businessSubjectRef) -and
                    ($Result.evidenceUsed -ccontains $_.evidenceId)
                })
                Assert-Check ($reports.Count -gt 0) 'Registry assessment without provider report'
            }
        }
        'financial-crime' {
            Assert-SameSet @($Result.payload.screeningAssessments.subjectRef) $Request.task.subjectRefs 'Omitted/extra screening assessment'
            foreach ($assessment in $Result.payload.screeningAssessments) {
                $reports = @($Request.task.screeningReports | Where-Object { $_.subjectRef -ceq $assessment.subjectRef })
                if ($reports.Count -eq 0) {
                    Assert-Check (($assessment.assessment -eq 'not_screened') -and
                        ($assessment.providerEvidenceIds.Count -eq 0)) 'Invented screening outcome'
                } else {
                    $expected = @{
                        possible_match = 'possible_match'; no_match_reported = 'provider_no_match_requires_review'
                        inconclusive = 'inconclusive'; provider_error = 'provider_error'
                    }[$reports[0].reportState]
                    Assert-Check ($assessment.assessment -ceq $expected) 'Provider screening state downgraded/changed'
                    Assert-SameSet $assessment.providerEvidenceIds @($reports[0].evidenceId) 'Screening report reference mismatch'
                    Assert-Check ($Result.evidenceUsed -ccontains $reports[0].evidenceId) 'Screening evidence omitted'
                    if ($expected -eq 'possible_match') {
                        Assert-Check (($Result.issues -ccontains 'possible_match') -and
                            ($Result.status -in @('requires_human_review', 'error'))) 'Possible hit lost its hold'
                    }
                    if ($expected -eq 'provider_error') {
                        Assert-Check (($Result.status -eq 'error') -and ($Result.issues -ccontains 'provider_error')) 'Provider error hidden'
                    }
                }
            }
        }
        'risk-review' {
            Assert-Check (($Result.payload.ruleFindings | ConvertTo-Json -Depth 20 -Compress) -ceq
                ($Request.task.approvedRuleFindings | ConvertTo-Json -Depth 20 -Compress)) 'Invented/omitted policy findings'
            foreach ($finding in $Result.payload.ruleFindings) {
                foreach ($id in $finding.evidenceIds) {
                    Assert-Check ($Result.evidenceUsed -ccontains $id) 'Policy evidence omitted'
                }
            }
            if ($missingBinding) { Assert-Check ($Result.payload.readiness -eq 'blocked') 'Missing policy not blocked' }
            if ($Result.payload.readiness -eq 'ready_for_human_review') {
                $ruleReports = @($Request.evidence | Where-Object {
                    ($_.contentState -eq 'available') -and
                    ($_.sourceKind -in @('bank_policy', 'approved_provider')) -and
                    ($_.sourceSystemId -ceq $Request.configuration.policyRules) -and
                    ($Result.evidenceUsed -ccontains $_.evidenceId)
                })
                Assert-Check (($null -ne $Request.task.assessmentSnapshotRef) -and
                    ($Request.upstreamOperationKeys.Count -gt 0) -and ($Result.issues.Count -eq 0) -and
                    ($Result.status -eq 'draft_prepared') -and ($ruleReports.Count -gt 0)) 'Risk readiness with missing upstream evidence/gaps or rule report'
            }
        }
    }
}
function Assert-Context($Value) {
    Assert-Schema $Value 'orchestrator\v2\intake-context.schema.json'
    Assert-EventId $Value.eventId
    if ($Value.bindingState -eq 'authorized') {
        Assert-Check ($Value.caseId -ceq $Value.metadataCaseId) 'Metadata and authorized case mismatch'
    }
}
function Assert-Rejected([scriptblock]$Action, [string]$Name) {
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    Assert-Check $rejected "Negative case accepted: $Name"
    $script:negativeCount++
}

$requests = Get-Content (Join-Path $root 'specialists\examples\requests.json') -Raw | ConvertFrom-Json -AsHashtable
$results = Get-Content (Join-Path $root 'specialists\examples\results.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-Check (($requests.Count -eq 5) -and ($results.Count -eq 5)) 'Need one fixture per role'
for ($i = 0; $i -lt $requests.Count; $i++) { Assert-Pair $requests[$i] $results[$i] }
$negativeCount = 0
foreach ($test in @(
    @{ Index = 0; Change = { param($q, $r) $q.evidence[0].caseId = $requests[2].caseContext.caseId }; Name = 'cross-case evidence' },
    @{ Index = 1; Change = { param($q, $r) $q.subjects[0].caseId = $requests[2].caseContext.caseId }; Name = 'cross-case person' },
    @{ Index = 0; Change = { param($q, $r) $q.operationKey += '-retry' }; Name = 'noncanonical operation key' },
    @{ Index = 0; Change = { param($q, $r) $q.evidence[0].capturedAt = '2026-99-99T99:99:99Z' }; Name = 'impossible timestamp' },
    @{ Index = 1; Change = { param($q, $r) $q.caseContext.subjectSetReview = 'required' }; Name = 'unreviewed persons' },
    @{ Index = 3; Change = { param($q, $r) $q.caseContext.ownershipReview = 'required' }; Name = 'business checks before ownership review' },
    @{ Index = 3; Change = { param($q, $r) $q.task.subjectRefs = @($q.task.subjectRefs[0]) }; Name = 'screening omitted related person' },
    @{ Index = 3; Change = { param($q, $r) $r.payload.screeningAssessments = @($r.payload.screeningAssessments[0]) }; Name = 'screening omitted result' },
    @{ Index = 1; Change = { param($q, $r) $r.payload.personAssessments[0].subjectRef = 'another-person' }; Name = 'invented person assessment' },
    @{ Index = 0; Change = { param($q, $r) $r.caseRevision++ }; Name = 'stale case revision' },
    @{ Index = 0; Change = { param($q, $r) $r.policyVersion = 'invented-policy' }; Name = 'policy version changed' },
    @{ Index = 0; Change = { param($q, $r) $r.status = 'draft_prepared' }; Name = 'unconfigured draft success' },
    @{ Index = 0; Change = { param($q, $r) $r.payload.documentType = 'identity_document' }; Name = 'classification without extractor' },
    @{ Index = 0; Change = { param($q, $r) $r.payload.formCode = 'CO-99' }; Name = 'unknown form code' },
    @{ Index = 0; Change = { param($q, $r) $r.evidenceUsed = @($q.evidence[0].evidenceId) }; Name = 'unavailable content used' },
    @{ Index = 0; Change = { param($q, $r) $r.providerExecutions = 'verified' }; Name = 'fabricated provider execution' },
    @{ Index = 4; Change = { param($q, $r) $r.payload.riskRating = 'low' }; Name = 'invented risk rating' },
    @{ Index = 4; Change = { param($q, $r) $r.payload.finalDecision = 'approved' }; Name = 'automated final decision' },
    @{ Index = 4; Change = { param($q, $r) $q.task.assessmentSnapshotRef = 'invented-snapshot' }; Name = 'invented review snapshot' },
    @{ Index = 0; Change = { param($q, $r) $r.knowledgeReferences = @(@{ file='04-required-intake-documents.md'; sectionId='INT-1'; packVersion='0.1.0-draft' }) }; Name = 'unapproved knowledge used as authority' }
)) {
    $q = Copy-Value $requests[$test.Index]
    $r = Copy-Value $results[$test.Index]
    & $test.Change $q $r
    Assert-Rejected { Assert-Pair $q $r } $test.Name
}

# Synthetic normalized possible-hit evidence exercises hold preservation, not a live check.
$q = Copy-Value $requests[3]
$r = Copy-Value $results[3]
$q.configuration.screeningProvider = 'synthetic-screening-provider'
$q.configuration.policyVersion = $r.policyVersion = 'synthetic-policy-1'
$q.configuration.countryRulesVersion = $r.countryRulesVersion = 'synthetic-country-1'
$q.evidence = @(@{
    evidenceId='synthetic-hit'; caseId=$q.caseContext.caseId; sourceKind='approved_provider'
    sourceSystemId='synthetic-screening-provider'; sourceRecordRef='synthetic-report'
    subjectRefs=@('synthetic-person-b')
    sourceVersion='fixture-1'; capturedAt='2026-11-19T22:00:00Z'; contentState='available'
    excerpt='SYNTHETIC contract fixture: possible match. Not a real provider response.'
})
$q.task.screeningReports = @(@{ subjectRef='synthetic-person-b'; evidenceId='synthetic-hit'; reportState='possible_match' })
$r.status = 'requires_human_review'
$r.issues = @('possible_match', 'evidence_missing')
$r.evidenceUsed = @('synthetic-hit')
$r.payload.screeningAssessments[1].assessment = 'possible_match'
$r.payload.screeningAssessments[1].providerEvidenceIds = @('synthetic-hit')
Assert-Pair $q $r
$bad = Copy-Value $r
$bad.payload.screeningAssessments[1].assessment = 'provider_no_match_requires_review'
Assert-Rejected { Assert-Pair $q $bad } 'possible-hit downgrade'
$bad = Copy-Value $r
$bad.issues = @('evidence_missing')
Assert-Rejected { Assert-Pair $q $bad } 'possible-hit hold removed'
$badRequest = Copy-Value $q
$badRequest.evidence[0].subjectRefs = @('synthetic-business-b')
Assert-Rejected { Assert-Pair $badRequest $r } 'report reused for wrong same-case subject'

# A source-located declaration is not identity verification or a compliance outcome.
$q = Copy-Value $requests[0]
$r = Copy-Value $results[0]
$q.configuration.documentExtractor = 'synthetic-extractor'
$q.configuration.policyVersion = $r.policyVersion = 'synthetic-policy-1'
$q.configuration.countryRulesVersion = $r.countryRulesVersion = 'synthetic-country-1'
$q.evidence[0].contentState = 'available'
$q.evidence[0].excerpt = 'SYNTHETIC CO-01 application claim at page1.field1, not verified evidence.'
$q.evidence[0].locators = @('page1.field1')
$r.status = 'draft_prepared'
$r.issues = @()
$r.evidenceUsed = @('synthetic-document-a')
$r.payload.documentType = 'application_form'
$r.payload.formCode = 'CO-01'
$r.payload.extractions = @(@{
    field='other'; valueRef='synthetic-snapshot-a'; evidenceId='synthetic-document-a'
    locator='page1.field1'; assessment='unverified_document_claim'
})
Assert-Pair $q $r
$bad = Copy-Value $r
$bad.payload.extractions[0].valueRef = 'invented-record'
Assert-Rejected { Assert-Pair $q $bad } 'invented extracted-value reference'
$bad = Copy-Value $r
$bad.payload.extractions[0].locator = 'page999.field99'
Assert-Rejected { Assert-Pair $q $bad } 'invented source locator'

$contexts = Get-Content (Join-Path $root 'orchestrator\v2\examples\intake-contexts.json') -Raw | ConvertFrom-Json -AsHashtable
foreach ($context in $contexts) { Assert-Context $context }
Assert-Check (($contexts[0].eventId -ceq $contexts[2].eventId) -and
    ($contexts[2].generation -gt $contexts[0].generation)) 'Late metadata must resume the original event'
$bad = Copy-Value $contexts[0]
$bad.caseId = $requests[0].caseContext.caseId
Assert-Rejected { Assert-Context $bad } 'unbound event assigned case'
$bad = Copy-Value $contexts[2]
$bad.metadataCaseId = $requests[2].caseContext.caseId
Assert-Rejected { Assert-Context $bad } 'authorized metadata mismatch'
$bad = Copy-Value $contexts[2]
$bad.generation = 0
Assert-Rejected { Assert-Context $bad } 'authorized zero generation'
foreach ($value in (Get-Content (Join-Path $root 'orchestrator\v2\examples\orchestration-results.json') -Raw | ConvertFrom-Json -AsHashtable)) {
    Assert-Schema $value 'orchestrator\v2\orchestration-result.schema.json'
    Assert-EventId $value.eventId
}

$routes = Get-Content (Join-Path $root 'orchestrator\v2\routes.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-Check (($routes.business.stage -join ',') -ceq 'document-evidence,business,natural-person,financial-crime,risk-review') 'Business stage ordering changed'
Assert-Check ($routes.business[2].gate -ceq 'reviewed_ownership_and_all_related_people') 'Ownership review gate missing'
foreach ($agent in $manifest.agents) {
    $expected = @($knowledge.agents[$agent.role] | ForEach-Object { "../knowledge/$_" })
    Assert-SameSet $agent.referenceSources $expected 'Agent knowledge source mapping drifted'
    foreach ($path in $agent.referenceSources) {
        Assert-Check (Test-Path -LiteralPath (Join-Path $root "specialists\$path")) 'Missing knowledge file'
    }
}
$intake = Get-Content (Join-Path $root 'knowledge\04-required-intake-documents.md') -Raw
$schema = Get-Content (Join-Path $root 'specialists\contracts\specialist-result.schema.json') -Raw | ConvertFrom-Json -AsHashtable
$types = $schema.allOf[0].then.properties.payload.properties.documentType.enum
foreach ($type in $types) { Assert-Check ($intake.Contains("``$type``")) "INT-1 missing $type" }
Write-Output "PASS: five role pairs, synthetic hit preservation, v2 sidecars/dispositions, mappings/routes and $negativeCount negative cases."
