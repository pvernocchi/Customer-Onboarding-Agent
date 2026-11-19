# V2 deterministic orchestration flow source

**Manual designer instructions, not executable/importable workflow JSON.**
Use with [setup](../../docs/03-specialist-setup.md), the adjacent route/schema/config
files and [SharePoint design](../../sharepoint/case-management.design.json).
All conditional writes below use the exact-ETag REST recipe. No model enforces
authorization, owns locks, chooses a provider or writes case state.

## 1. Capture and preserve an event

Retain SharePoint **When a file is created (properties only)** for the configured
site/library, optional Folder empty, and the v1 metadata normalization,
folder/input validation and enforced-unique EventKey claim. Do not use a
deprecated folder trigger or created-or-modified substitute. Leave v1
EventPayload immutable. No content is read at trigger time.

Create new rows with ContractVersion=2.0, EventGeneration=0, State=V2Processing,
original OwnerRunId and ActiveResumeRunId=own run. A duplicate key never creates
another event or dispatch. Follow
v1 ambiguous-Create resolution and explicit failure reporting. V2 uses
BindingSnapshotRef and V2ResultSnapshotRef, not the v1 ResultPayload column.

Read current file **properties**, CaseId internal column and actual item/file
version/ETag through the configured library connection. Build the v2 sidecar as
an object. Empty/missing CaseId -> WaitingForCase; malformed GUID, overlong
metadata, unknown/closed case or failed scope check -> CaseReviewRequired.
Oversized metadata is invalid: do not truncate it into a plausible case ID.
Record a sanitized issue, no authorized caseId, and no agent/provider dispatch.
Persist the pending disposition and conditionally release only the owned
ActiveResumeRunId; never treat it as completed onboarding. For metadata beyond
the sidecar's size limit, store metadataCaseId=null plus an invalid-metadata issue;
preserve the unmodified value only in the restricted audit boundary if lawful.
Reads/writes that fail technically use Failed/NeedsReconciliation and a failed
run, not a benign missing-case fallback.

## 2. Authorize the link before content or provider access

1. Accept only canonical GUID CaseId candidates. Query the configured
   OnboardingCases list by its unique CaseId, Top Count 2; exactly one nonclosed
   row is required. Do not use a customer-supplied list/site/URL.
2. Compare IntakeTenantId/SiteId/LibraryId against configured file source
   identities. Confirm the file's actual bank-managed parent-folder UniqueId
   equals the case's IntakeFolderUniqueId, and the file inherits the approved
   folder ACL without a unique unauthorized permission override. Resolve
   actual permission state, not just a path string or metadata scope flag.
   The initial design admits direct children only; nested folders or moved
   files are held until an explicitly approved ancestry/ACL design exists.
3. Validate the authenticated upload/operator access context against the
   bank-managed case scope and ACL provisioning records. The connection
   owner's ability to read a case is not proof the submitter is entitled.
   Customer uploads require the selected tenant's reviewed sharing/identity
   model. Until that is supplied, use bank-controlled synthetic uploads only.
4. Validate that the file's bound case has not changed on replay/resume.
   Once BoundCaseId is set, any different candidate is a hold requiring a
   separate authorized correction process, never an automatic rebind.
5. Snapshot the authoritative CaseType, CaseRevision, scope, countries, subject
   snapshot/version/review, ownership review and approved policy versions.
   Lowercase Individual/Business into the contract's enum explicitly.
   Do not populate types/people/versions from a filename or model response.

Store any unvalidated metadata only within the restricted operations boundary.
Do not disclose whether another scope's case exists. Folder ACL inspection,
authenticated-actor resolution and scope authorization must be verified with
the tenant's supported connectors/REST and permission model before activation;
if unavailable, case authorization remains pending and nothing is dispatched.

## 3. Resume existing pending work, never create a second event

Create a separate restricted instant flow using **For a selected item** on the
intake ledger. The SharePoint menu exposes such flows only in the default
environment; in another environment use the authorized Power Automate run
surface and verify its supported authenticated-invoker context instead.
Require explicit run-only operator permissions **and** case-scope authorization.
Do not trust a typed operator email, a request body flag or the maker's broad
connection as the caller's authority. If invoker identity cannot be verified,
do not enable resume.

Accept an existing ledger item ID and a ResumeReason, not arbitrary event JSON,
case IDs, provider endpoints or payload overrides. Reread the durable row,
validate its stored v1 event and sidecar, and reread the actual file properties.
Metadata changed after creation is handled only here, not by resubmitting a
new creation event. Preserve the old sidecar/evidence history.

Eligible holds: WaitingForCase, CaseReviewRequired, WaitingForCaseBusy, V2Blocked
or V2ReviewRequired, plus explicitly enrolled legacy PendingIntegration.
Failed, NeedsReconciliation, active Processing/V2Processing or uncertain stage
dispatches require an authorized reconciliation decision first. Inspect stage
history before a new generation; never use resume as a blind retry button.

Compare-and-set the ledger's eligible state, empty ActiveResumeRunId and
expected generation using its exact ETag; set ActiveResumeRunId=own run and
State=V2Processing. Only a confirmed conditional write may proceed. Two resumes
reading the same version cannot both win. Preserve original OwnerRunId.
Any 412 -> stop/revalidate; timeout -> reconciliation, not optimistic dispatch.
Set the new generation and binding under the owned row after authorization,
before the case reservation below; generation starts at 1 for the first
authorized attempt. The creation flow uses its initial owned reservation for
the same protocol. A confirmed case-busy hold records waiting_for_case_busy
with no stage keys. A later authorized resume may advance the generation only
after confirming no dispatch occurred; it does not pretend the busy attempt ran.

## 4. Reserve the case and freeze a snapshot

Read the case ETag, revision and lock fields. Only a nonclosed, scope-valid case
with empty ActiveRunId is eligible. MERGE ActiveRunId/ActiveEventKey using that
exact ETag. Other files in the same case must wait in WaitingForCaseBusy, while
different case rows may proceed concurrently. Do not use trigger concurrency=1
as a substitute for this case-level gate.

If case reservation fails definitively, conditionally release only the owned
ledger resume reservation into WaitingForCaseBusy or failure as appropriate.
If any reservation has an ambiguous outcome, stop for reconciliation. There
is no cross-list transaction; stale reservations can remain and are monitored.
Never auto-steal a lock based on elapsed time. The operator must stop/drain
active runs and reconcile them before releasing stale owners.

All authoritative case/subject/policy edits use the same controlled writer:
no edit while ActiveRunId is nonempty, and exact-ETag updates. Increment
CaseRevision for evidence-set, subject, scope, country or policy changes;
increment SubjectSetVersion when the accepted subject set changes. No
unconditioned customer/staff updates are allowed as a competing writer.

Capture immutable authorized evidence versions only now, using approved
file-security/extraction and provider adapters. Record the actual captured
version/time; late capture does not prove these were the bytes at creation.
Bind CaseId and source version into each evidence record. Reread file metadata/
case state before dispatch; changes invalidate the snapshot and require review.

## 5. Stage requests, provider boundaries and route gates

Construct specialist requests using the shared v2 schema. Apply schema AND
explicit Conditions for every constraint; validate actual calendar timestamps,
unique subject/evidence IDs, exact case matches, required role/kind coverage,
operation-key correlation and source approval. Verify Power Automate's JSON
Schema keyword behavior in the tenant; local Test-Json is not a platform proof.
Opaque references resolve only through configured restricted storage, not URLs.

The deterministic stage key is:

```text
<unchanged-event-key>:g<generation>:r<case-revision>:s<subject-set-version>:<role>:i2.0.0
```

Use positive decimal integers without leading zeroes, subject version 0 only
where no reviewed set yet exists. Validate the key fits the 255-character unique
column. Serialize objects; never interpolate untrusted text into JSON or OData.
The generation is a recorded operator-authorized attempt, not a random retry ID.

Before any external provider call, require a bank-approved connector binding,
its lawful data/source/jurisdiction coverage, policy versions, authenticated
authorization and required evidence. Never read an endpoint from customer data,
model output or knowledge. Providers may support idempotency/reference tokens;
use the stage key where documented by that provider. No unsupported provider
API, response or exactly-once guarantee is supplied by this repository.
Unconfigured adapters do not execute: journal the blocked disposition with no
fabricated provider response. Preserve provider call references and versions.
Timeouts/errors cannot be converted into "no match" or "verified".

The routes are strictly sequential:

| Path | Order / enforced gate |
| --- | --- |
| Individual | document-evidence -> reviewed in-scope person set -> natural-person -> all-subject financial-crime -> risk-review |
| Business | document-evidence -> business registry/ownership/authority discovery -> **human-reconciled ownership and subject set** -> natural-person for all related people -> financial-crime for business and every relevant person -> risk-review |

An unreviewed/incomplete business ownership graph **stops** the person/screening
path. It does not merely become a note after those checks. The registry adapter
normalizes candidate people into protected case-scoped references; the business
agent proposes relationships among them; only a human accepts the authoritative
subject set. Individual representatives also need scoped reviewed identities.
Do not silently remove unresolved people to make the workflow proceed.

Screening task.subjectRefs must equal the complete reviewed in-scope set, with
both the business and relevant people. The controlled provider adapter emits
task.screeningReports per subject with exact evidence/version references and
normalized reportState. Validate these against the actual immutable reports.
The result cannot omit a subject or change possible_match to no-match.

PolicyRules is an approved deterministic rule flow/provider, not this model.
It populates task.approvedRuleFindings only from a real versioned report; risk
outputs must preserve that entire list and all upstream gaps/holds. Policy,
country rules and knowledge versions are distinct. With upstream blocks, the
flow may record a **blocked** review snapshot without calling missing stages.
No stage is marked complete because its draft instructions exist.

## 6. Dispatch and validate a specialist draft

Set Retry policy=None on mutating SharePoint/HTTP actions, provider actions and
agent dispatches; ambiguous writes use reconciliation, not blind action retry.
Create an immutable request snapshot, then a stage-journal row with unique
OperationKey, scoped case/event/generation/revisions, OwnerRunId, request ref
and State=Dispatching. Retry policy=None. Confirm a unique owned claim before
any provider/agent dispatch in that stage; duplicate/ambiguous claims do not
reexecute. A provider outcome and the agent's interpretation are separate
records. Provider work happens through the approved flow adapters, never model
tools. Update the owned snapshot/journal references after provider normalization
before the agent invocation; retain the initial request/call intent for audit.

Invoke Execute Agent and wait with Retry policy=None and a fresh conversation.
Parse the single response directly; require correct version, role, event ID,
operation key, generation, case ID/revision, subject version and policy versions.
Require every evidence/subject/value reference to exist in the authorized
snapshot and every relied-on source to be available and approved for its role.
valueRef must equal the cited sourceRecordRef; the separate locator must appear
in evidence.locators emitted by the approved extractor for that snapshot, not
be a model-created record/location. Every provider evidence item also carries
subjectRefs; require that the assessed person/business appears there, not only
that a report belongs to the same case. Bind the normalized task.screeningReports
mapping to the actual subject(s) in the immutable provider report. The flow
validates these wrappers; customer text cannot set them.

Provider-report assessments require real matching-provider evidence. No
configured binding means blocked_pending_configuration with no extracted or
verified findings. Screening output must preserve the normalized source report
states; possible matches preserve requires_human_review/possible_match, errors
preserve error/provider_error. Never accept invented "clear", "approved",
"verified", completed onboarding, or omitted subjects. Knowledge citations are
separate from evidence and cannot establish a provider result.

Persist a validated immutable result and conditionally mark the owned stage
DraftRecorded, Blocked or Failed; ambiguity -> NeedsReconciliation. A draft is
not verification approval. Before aggregate writes, reread case/file/policy/
subject versions and case lock ownership. Reject stale or cross-case results.
Keep run histories and sensitive stage/evidence details restricted.

## 7. Aggregate, release and recover

Power Automate, not a model, writes the v2 orchestration-result object. Union
all known errors, missing-config gaps and holds from authoritative snapshots;
never let a risk summary erase them. StageOperationKeys names only actual
claimed journal rows. Persist V2ResultSnapshotRef with State=V2Blocked or
V2ReviewRequired. Closed/approved/rejected are not automatic transitions.
Keep detailed screening/suspicion information in its restricted compliance
boundary; expose neutral hold codes/references to broader operations.

Conditionally clear only this run's case/event reservations using fresh ETags
after verifying ownership. Preserve original event/operation/result history.
Any technical failure runs the failure Scope (failed/timed-out Run after),
attempts a conditional Failed/NeedsReconciliation write with sanitized ErrorCode,
and ends **Terminate Failed** even if logging fails. A false Condition must
explicitly route into this failure path. Do not hide persistence errors.

There is no atomic transaction across list rows, evidence writes, providers and
agent messages. A persisted result with a failed lock-release still needs
reconciliation; a missing journal response does not prove no dispatch occurred.
Never auto-repeat a Dispatching/uncertain stage or create a new generation to
evade its key. Operators inspect actual run/provider history, stop/drain active
runs and make a recorded recovery decision. A fresh generation is allowed
only after reconciliation/authorized new evidence/configuration changes, not
automatic retries. Preserve ledger keys while redelivery/replay remains possible.
