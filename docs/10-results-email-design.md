# Internal processing-results e-mail

**Design and local rendering artifacts only. Unverified; not tenant-tested.
Disabled until the independent control plane exists and bank Compliance/DPO
approve the content, routing, confidentiality controls and retention.**
Nothing here sends mail, provisions lists or changes V2 enablement.

## Intended experience and artifacts

Send one internal summary per **completed case processing attempt**, including
an attempt stopped by a business hold or technical failure. A completion is not
case closure or customer approval. A later authorized resume has a new durable
run ID/generation and may send its own summary; replay of the same run must not.
Do not mail per uploaded file, per specialist, on each case edit or only after
the happy path. Financial-crime escalations still follow their separate urgent
restricted process; this summary is not that process.

| Artifact | Purpose |
| --- | --- |
| [Projection schema](../notifications/results-email.schema.json) | Strict allowlist; no recipients, attachments or free-text findings. |
| [HTML template](../notifications/results-email.html) | Case/customer, overall outcome, completion time/revision/run, each document and safe reason, secured case link. Text labels do not rely on color. |
| [Local renderer](../notifications/ResultsEmail.psm1) | Schema/semantic checks and HTML encoding; no mail sender or deployed flow. |
| [Success preview](../notifications/examples/success.html) / [payload](../notifications/examples/success.json) | Synthetic target-state validation-passed draft, not an actual execution. |
| [Failure preview](../notifications/examples/failure.html) / [payload](../notifications/examples/failure.json) | Synthetic mixed document failure, technical failure, unevaluated document and neutral restricted hold. |
| [Local checks](../scripts/Test-ResultsEmail.ps1) | Positive/negative contract, correlation-shape, rendering and preview freshness checks. |

The subject is fixed text plus a validated canonical ID:
**Onboarding processing results - case {caseId}**. Do not put customer name,
document type, outcomes, urgency, risk or screening terms in subject/preheader.
Use the same neutral subject for every outcome.

## Source mapping: do not infer success from a draft

Use the case/event/revision/generation/subject correlation from the
[V2 orchestration result](../orchestrator/v2/orchestration-result.schema.json),
stage identities/statuses from the
[specialist result](../specialists/contracts/specialist-result.schema.json),
and durable rows from the
[case/stage design](../sharepoint/case-management.design.json).
This is a **separate notification projection**, not a new specialist result or
an extension of V1 `PendingIntegration`.

**Missing prerequisite:** current specialist contracts do not contain a
per-document validation verdict, and orchestration results deliberately have
no success status. `draft_prepared`, `DraftRecorded`, `review_required`, absence
of issues, or extracted unverified claims cannot establish a pass. Do not
change those contracts to manufacture success for an e-mail.

The future deterministic control plane must implement a bank-approved
completion snapshot containing the exact case/event/generation/revisions,
run ID, terminal disposition, actual required-stage and required-evidence
coverage, approved rule/provider execution references, a complete document
inventory and controlled per-document verdicts/reasons. It must preserve every
upstream hold/error. Require validated immutable source references for every
positive verdict, with actual configured checks complete for all required
documents/subjects/stages. No provider binding or uncertain/missing execution
means **not validated**, hold or technical failure, never a pass.
Model outputs are inputs to review, not authority to populate positive verdicts.
This producer and its coverage checks are not implemented here.

| Projection field | Authoritative source and transformation |
| --- | --- |
| `caseId`, `caseRevision`, `eventId`, `generation`, `subjectSetVersion`, `runId` | Frozen authorized completion context; exact-match against the ledger, case reservation, stage rows and snapshots. No cross-case joins or latest-row substitution. |
| `customerName` | Single authorized customer display name from the protected subject snapshot; never filename/OCR/model text. Name is the only customer display data in mail. No birth date, address, ID/registration/account numbers or contact details. If unavailable/ambiguous, quarantine notification and alert operations without a fabricated name. |
| `completedAt` | Control-plane UTC finalization time, not trigger or e-mail time. |
| `caseUrl` | Resolve actual configured tenant/site/list and case item ID after authorization. Build a normal HTTPS case view URL; no sharing token, evidence URL, temporary access grant or arbitrary uploaded URL. Recheck recipient access separately. |
| `documents` | Every in-scope document version in the completed run, plus known missing required slots. Assign `DOC-001`-style run-local references; persist their versioned mapping to actual evidence IDs or missing slots in the secured case. Use the existing document-type enum and fixed display labels, never original filenames or sensitive free-text titles. |
| Document status/reason | Bank-approved deterministic checks mapped to the finite schema codes. Failed validation gets a specific safe reason; not-run, configuration gap and processing error remain distinct. Unknown/sensitive reasons stop broad export or use neutral restricted review; never copy raw exception, extraction, agent prose or screening payload. |
| `runReasons`, `restrictedReview` | Union of controlled safe flags across all stages, including non-document holds. Detailed reasons and all screening/suspicion material remain restricted. |
| `outcome` | Apply the precedence below; a document pass does not erase a run-level hold. |
| `humanDecision` | Always `not_made_by_automation`. Final decisions stay in a separate human workflow. |

Overall precedence (apply schema **and explicit semantic conditions**):

1. Any technical error, failed/uncertain stage, invalid response or reconciliation
   requirement -> `technical_failure` and `technical_error`.
2. Otherwise any restricted hold -> `requires_restricted_review`.
3. Otherwise any failed/not-validated document, configuration gap, evidence gap
   or unresolved business/processing gate -> `business_hold`.
4. Only with complete positive check evidence and no preceding condition ->
   `validation_passed_draft`; all documents passed, no run reasons, no restricted flag.

When technical and restricted conditions coexist, retain both flags but display
the technical overall outcome. For **all** screening hits, suspicion and
restricted findings, show only **"Requires restricted review"** and the case
link. No hit type, source/provider, subject, list, score, raw code or narrative
may appear in e-mail, subject, outbox error text or broadly visible logs.
The same neutral signal is used for other restricted matters; do not identify
the financial-crime stage. Document reasons shown beside other documents must
be independently safe and unrelated to the restricted finding. If even the
document type would disclose it, use `other_supporting` and an opaque reference.

An unbound/unauthorized intake (`waiting_for_case`, `case_review_required`) is
not an authorized case run: never guess case/customer or mail the proposed
case owner. Keep its failure visible in the restricted operations incident
process. `waiting_for_case_busy` is a scheduling hold without a case reservation,
not completion of a processing attempt.

## Proposed durable records (manual additions, not provisioned)

Do not overload `CaseState`, `LatestAssessmentRef` or a stage's `DraftRecorded`
to mean run completion. A stage update alone cannot prove all work is finished.
The existing provisioning script does **not** create the following lists.
All lists: bank-managed restricted ACLs, external sharing and attachments off,
version history on, monitored retention approved by DPO, exact-ETag conditional
writes and enforced unique indexed keys. Store snapshots in the restricted
immutable evidence boundary, not list notes or agent conversation.

| Proposed list | Fields / invariant |
| --- | --- |
| `OnboardingProcessingRuns` | `CompletionKey` (unique Text, <=255), `CaseId` (indexed Text), `CaseRevision`, `EventId`, `Generation`, `SubjectSetVersion`, `RunId`, `State` (`Processing`, `Finalized`), `CompletionSnapshotRef`, `CompletedAt`. Controlled writer only. Completion key = canonical case ID + `:r` + revision + `:` + stable processing run ID (not the notification flow run ID). Maximum 149 characters under this schema. |
| `OnboardingResultNotifications` | `NotificationKey` (same enforced unique key), `CompletionKey`, `CaseId`, `SnapshotRef`, `RoutingConfigVersion`, `RecipientScopeRef`, `State` (`Prepared`, `Dispatching`, `Sent`, `Blocked`, `NeedsReconciliation`), `OwnerRunId` (notification worker), `AttemptedAt`, `AcceptedAt`, `SafeErrorCode`. No customer name, raw HTML, recipient addresses or sensitive reasons in list columns. `Sent` means connector acceptance, not delivery/read. |

Finalize from **both** success and failure/timeout paths, including business
holds without downstream dispatch. Seal a technical-failure snapshot when
assessment stages fail; do not require a risk-stage result to report failure.
`Finalized` requires a durable, immutable snapshot and stopped/drained writers;
no stage may still mutate that attempt. Uncertain stage outcomes remain
explicitly uncertain in the technical-failure snapshot, not resolved as passes.
Conditional case-lock release must be confirmed or its failure included as
reconciliation-required. Failure to persist/finalize is a failed control-plane
run with an operations alert; do not send a guessed summary.

Cross-list writes are not atomic. A completion recovery job compares finalized
run rows with outbox keys and creates missing rows by the same unique key.
It must also alert on unfinalized/stale runs, failed finalizers and old
Prepared/Dispatching/Blocked/NeedsReconciliation rows. It never silently
manufactures completion, steals ownership or auto-resends uncertain mail.
Retention must preserve keys while replay/redelivery is possible.

## Power Automate authoring recipe (disabled design)

This is a manual recipe, **not an importable solution or a replacement for the
missing control plane**. Do not wire a model directly to Outlook.

1. Create a solution-aware disabled notification flow with bank-owned
   SharePoint and Office 365 Outlook connection references. Configure
   `ResultsEmailEnabled=false`, configured tenant/site/list identities,
   sender/shared mailbox, approved routing version, internal recipient group
   identities and access scopes as bank-managed environment configuration.
   No sample address is a real destination. Require Compliance/DPO approval,
   DLP, run-history restrictions, secure inputs/outputs through the entire
   sensitive action chain, and reviewed Exchange transport/retention rules.
2. Select SharePoint **When an item is created or modified** on
   `OnboardingProcessingRuns`, not the intake file library or every stage row.
   Use trigger conditions for enabled + `State=Finalized`; reread the actual
   run and snapshot after the trigger. Conditions are an efficiency filter,
   not a security or duplicate-delivery control. Finalization must occur after
   snapshot persistence, so early stage/case changes do not send anything.
   A flow listening to case/stage records may only wake a completion check:
   it must resolve a durable finalized run before creating a notification.
3. Reauthorize the case and completion snapshot through configured bindings.
   Verify all correlation fields and exact stage/evidence/subject coverage.
   A later case revision must never replace this immutable run's results; the
   e-mail displays the completed revision/time. Verify retained snapshot and
   current access entitlement before sending an older completed run.
4. Resolve recipients **only from bank-managed configuration** for that case
   scope (for example an internal KYC team distribution group or monitored
   shared mailbox). A sender shared mailbox and recipient mailbox are separate
   settings. Never take To/Cc/Bcc/Reply-To from a customer, upload, model or
   arbitrary typed flow input. `HumanReviewOwner` is not automatically a valid
   recipient; it may be used only after approved internal identity/scope checks.
   Empty, unresolved, external, guest or unauthorized routing -> `Blocked`
   and a restricted operations alert, no send. No fallback to the customer,
   maker, all staff or an unapproved default.
5. Before each send, resolve and validate distribution-group membership
   (including nested/dynamic groups), internal-only identities, case access
   and disabled external forwarding/delegation rules. An internal-looking
   domain is insufficient. Prefer a bank-governed per-scope mailbox/group
   with enforced membership controls. If the tenant cannot enforce recipient
   and forwarding policy, **do not activate**. Mail is a new copy outside the
   case ACL; the secured link alone does not protect the name/results in mail.
6. Produce the allowlisted projection and validate with **Parse JSON plus
   explicit Conditions** for all schema/semantic/coverage checks. Power
   Automate keyword support is not proved by local `Test-Json`. Validate
   real calendar timestamps, unique document references, reason/status
   pairing, all upstream errors, precedence and exact authorized link.
   Unsupported keywords require equivalent deterministic validation, not
   relaxed constraints. Build serialized objects, never JSON by interpolation.
   Apply an explicit complete-inventory check; >100 documents, overlong name,
   unsupported types/reasons or missing data are `Blocked`, not truncated,
   omitted, defaulted to pass or split into multiple "completion" messages.
7. Freeze a minimal projection snapshot, then **Create item** in
   `OnboardingResultNotifications` with its unique `NotificationKey`,
   `State=Prepared`, snapshot and routing references. Retry policy **None**.
   A confirmed unique owned row is required. Duplicate create -> read the
   existing row; `Sent` never sends again, `Dispatching`/uncertain outcome
   requires reconciliation, and only the recorded owner may continue.
   An ambiguous create is not proof of ownership. Resolve the persisted row
   first; never send on a timeout or just because `Get items` returned empty.
8. Recheck enabled status and routing authority; read exact ETag and
   compare-and-set owned `Prepared` -> `Dispatching` with attempt time and
   current validated routing version before invoking Outlook.
   Use [the existing conditional update recipe](../sharepoint/conditional-update.http)
   with the actual outbox list entity type. A `412` loses the claim; a timeout
   is uncertain. Neither may send optimistically. Trigger concurrency=1 is
   not a substitute for this durable claim.
9. Render the template using fixed labels and **HTML-encode every variable
   and attribute value**; generate document rows only from validated enums.
   Do not assume Create HTML Table or string concatenation sanitizes input.
   The local renderer is the reference behavior, not a Power Automate action:
   implement/test equivalent encoding and token replacement in an approved
   deterministic adapter or reviewed flow actions. Never allow model-authored
   HTML, scripts, remote images, document links, attachments or arbitrary CSS.
   Construct the subject from fixed text and validated CaseId only.
10. Use Office 365 Outlook **Send an email (V2)**, or **Send an email from a
    shared mailbox (V2)** with a bank-approved mailbox address and verified
    mailbox send permissions. To = validated configured internal destination,
    Body = rendered HTML (HTML/code view), Subject = fixed subject above.
    Cc/Bcc empty; attachments empty; no customer Reply-To or read receipts.
    Apply bank-reviewed sensitivity/transport controls where supported and
    tested; merely labeling text "internal" is not enforcement.
    Set action retry policy **None**; do not wrap send in a retry loop or
    automatically resubmit failed flow runs.
11. Confirmed connector success -> exact-ETag owned transition to `Sent` with
    `AcceptedAt`. Office 365 Outlook's V2 send action does not supply a message
    ID; do not invent one. Track the stable case/revision/run correlation and
    notification key in the restricted journal. Acceptance is not delivery.
12. Configure failure Scopes with Run after **failed/timed out** for every
    persistence/validation/render/send path; false Conditions route explicitly
    to failure/blocked handling, never an empty success branch. An attempt
    that might have reached Outlook, or success followed by a failed `Sent`
    write, is `NeedsReconciliation`. End technical failures as failed even if
    error logging fails. Pre-send validation/permission failures are `Blocked`
    with a safe code and operational alert; the case assessment is unchanged.

### Once-per-run intent, not an exactly-once delivery promise

SharePoint and Outlook do not share a transaction or an e-mail idempotency
token. Unique keys and the conditional dispatch claim prevent normal replay/
concurrency duplicates; retry=None cannot guarantee the connector/Exchange
never duplicates an accepted request. A timeout may already have sent mail.
Never automatically retry a `Dispatching` or `NeedsReconciliation` row,
delete its key, create a new worker key or resend the processing run to bypass
it. An authorized operator checks flow history and mailbox/Exchange evidence.
If acceptance is confirmed, mark `Sent`; if nonacceptance is proven, record
the decision and allow a controlled new owner on the **same key**. If uncertain,
hold and use the restricted operations channel. This trades an automatic
retry for human recovery; strict guaranteed exactly-once delivery is **not**
implemented or claimed. Monitor bounces/nondelivery separately.

## Local checks and mandatory tenant acceptance

Run from the repository root with PowerShell 7.4+, no packages:

```powershell
pwsh -NoProfile -File .\scripts\Test-ResultsEmail.ps1
# After intentional template/copy changes, regenerate and review both previews:
pwsh -NoProfile -File .\scripts\Test-ResultsEmail.ps1 -UpdatePreviews
```

The local module validates the projected shape and HTML safety only. It cannot
prove source authenticity, coverage, mailbox entitlement, schema enforcement
in Power Automate, connector behavior or successful tenant delivery.
Synthetic success is a target state, not evidence that checks ran.

Before any activation, bank engineering and Compliance/DPO must witness:

- Completed positive run -> one readable draft-pass message, all documents and
  correct customer/case; final human decision remains unset.
- Document expiry/unreadability/missing evidence -> specific safe reason on
  the right document; not-run documents visible; no success claim.
- Configuration/ownership/evidence holds and restricted-only holds -> business
  or neutral restricted outcome, never approval; no restricted details anywhere
  in mail or broadly visible history. Technical + restricted flags both survive.
- Provider timeout, invalid response, stale/cross-case reference, incomplete
  inventory, unknown reason, over-limit payload and failed finalization -> no
  fabricated pass; failed/blocked notification and monitored operations path.
- Concurrent/replayed run and case/stage edits -> one durable key and no
  repeat dispatch. Separate authorized generations -> distinct summaries.
  Finalized run with missing outbox -> recovery creates only the same key.
- Crash before send, timeout during send, success then failed `Sent` write,
  failure to record an error and failed lock release -> visible recovery,
  no blind retry or swallowed technical failure.
- HTML metacharacters, hostile filenames/prose/URLs, wrong customer, external/
  nested-group recipient, forwarding, disabled feature, changed membership,
  access revoked and missing reviewer -> no disclosure or fallback routing.
- Secured case link prompts bank sign-in and denies unauthorized users; old
  revision mapping works without granting new access. Outlook desktop/web/mobile
  readability, shared mailbox permissions, sent-item behavior, bounce monitoring,
  secure run history, retention and transport controls are tenant-tested.

## Microsoft references

Consulted via Microsoft Learn MCP on 2026-11-20; tenant behavior remains unverified:

- [Office 365 Outlook connector](https://learn.microsoft.com/en-us/connectors/office365/):
  V2 send actions, HTML body, shared mailbox permissions, no returned message
  ID and documented retry/duplicate-mail considerations.
- [Common e-mail scenarios](https://learn.microsoft.com/en-us/power-automate/email-top-scenarios):
  shared mailbox sending and HTML summary patterns.
- [SharePoint connector](https://learn.microsoft.com/en-us/connectors/sharepointonline/):
  item-created-or-modified trigger; modifications can retrigger flows.
- [Trigger conditions](https://learn.microsoft.com/en-us/power-automate/customize-triggers):
  filter irrelevant executions, not a durable idempotency mechanism.
