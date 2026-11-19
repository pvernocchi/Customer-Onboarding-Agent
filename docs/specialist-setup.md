# Five specialists, SharePoint cases and draft knowledge

## Delivery status

**Repository source only. No tenant deployment or execution is claimed.**
The five agents have distinct instructions, role-discriminated JSON contracts,
synthetic request/result examples, and a deterministic flow-authoring design.
The SharePoint design, flow routes, configuration and agent/knowledge manifests
are **manual authoring inputs**, not importable Copilot Studio/Power Automate
solutions. Native `.mcs.yaml` definitions/solution archives must be generated
and verified through the actual environment, not fabricated here.

The only executable artifacts are dependency-free local contract checks and
the customer Word-template generator. Neither provisions cloud resources,
performs identity/screening checks, makes a risk decision or sends customer data.
The case store is a **SharePoint list**, not a Dataverse case table. Copilot
Studio's platform/solution and optional knowledge-storage requirements can
still involve Dataverse.

## Source map and boundaries

| Source | Purpose |
| --- | --- |
| [Agent manifest](../specialists/agents.json), [shared instructions](../specialists/common-instructions.md) and five role files | Exact manual Instructions composition and separate Agent ID bindings |
| [Request contract](../specialists/contracts/specialist-request.schema.json) / [result contract](../specialists/contracts/specialist-result.schema.json) | Explicit per-role task/payload variants, case/version correlation and non-decision outcomes |
| [Requests](../specialists/examples/requests.json) / [results](../specialists/examples/results.json) | Five independent synthetic examples, all providers deliberately unconfigured; not one execution trace |
| [SharePoint design](../sharepoint/case-management.design.json) / [conditional-write recipe](../sharepoint/conditional-update.http) | Case list, stage journal, immutable evidence library and v1 ledger additions |
| [V2 routes](../orchestrator/v2/routes.json), [configuration](../orchestrator/v2/config.example.json) and [flow steps](../orchestrator/v2/flow-authoring.md) | Individual/business sequencing, authorization, idempotency, resume and reconciliation |
| [Knowledge overview](../knowledge/README.md), [source register](../knowledge/sources-and-applicability.md), [mapping](../knowledge/knowledge-manifest.json) | Draft guidance, current/future/national/EEA applicability and scoped source ownership |
| [Customer forms](../customer-templates/README.md) | CO-00 through CO-08 editable Word drafts and reproducible source |

No approved provider, country rules, bank risk policy, national/EEA overlay or
data-sharing authorization has been supplied. All bindings/approved policy
versions remain null. Native knowledge/tool integrations remain disabled.
The knowledge pack is **0.1.0-draft, not compliance-approved**. The case metadata
is a candidate link, not proof of authorization or identity.

## Author the five agents

1. In the explicitly authorized development environment, create five separate
   standard-harness Copilot Studio agents with the names in the manifest.
   Add them to the existing unmanaged solution, using the existing solution's
   environment and approved publisher. Do not change the v1 agent in place.
2. Paste the complete shared instructions, followed by that agent's role file,
   into **Instructions**. Their Markdown links identify repository sources;
   they are not automatic file inclusion or active runtime knowledge binding.
   Use no web search, arbitrary REST/MCP endpoints, downstream agent tools,
   document knowledge, or model-driven side-effecting tool calls.
3. Use generative orchestration only as supported by the selected standard
   experience. Disable irrelevant default topics/general knowledge and verify
   one JSON response per valid request. Add no event triggers to specialists.
4. Bind the platform-generated IDs to the five `onb_*AgentId` variables. From
   the flow call **Microsoft Copilot Studio / Execute Agent and wait**
   (`ExecuteCopilotAsyncV2`), Agent=the configured role ID,
   Environment ID=the actual existing environment, Message=serialized validated
   request, locale=en-GB, fresh/empty Conversation ID, Retry policy=None.
5. Require a single response, parse `lastResponse` directly, validate the role's
   schema and every semantic correlation/reference/hold. Never repair prose,
   coerce a success, reuse conversation state or accept fabricated provider
   execution. Test every synthetic role example individually in the tenant.

Power Automate is the v2 orchestration controller. It invokes specialists in
the order defined in the route source; the original v1 agent stays intact.
This intentionally avoids a model selecting identities, permissions, providers
or the sequence of compliance checks. Native child/connected agents exist,
but adding them on top would create another dispatch path and is not part of
this design. A later native-agent redesign needs equivalent enforced gates.

## Provision SharePoint and permissions

Create `OnboardingCases`, `OnboardingStageExecutions` and `OnboardingEvidence`
using the exact internal field names/types in the design. Set Title to the
opaque case/evidence/operation key rather than a customer name. Enforce unique
values/indexes on CaseId, IntakeFolderUniqueId, OperationKey and EvidenceId.
Enable version history; disable attachments/external sharing on operational
lists. SharePoint lookup/text relationships are not foreign-key enforcement:
the flow validates every case and reference.

A bank-controlled case writer creates cases, sets Individual/Business from
authoritative intake, chooses scope/countries and provisions an isolated intake
folder with bank-approved ACLs. CaseId is a canonical GUID unrelated to the
SharePoint item ID, customer ID, person reference or file-event identity.
Do not expose case-list edits to customer uploaders. An editable metadata field,
a filtered list view and a service account's broad access are not authorization.

Direct uploads require tenant-verified bank-issued identity/access permissions,
case-folder isolation and an approved scope/actor authorization check. Until
that is provided, allow only controlled bank-operator test uploads. Customer
forms describe a future bank-provided secure location, not a deployed portal.
Confirm external/customer licensing, sharing and data protection separately.

Case subject snapshots contain case-scoped opaque person/business references
and roles; keep underlying identity/relationship evidence in protected storage.
Intermediate relevant businesses use kind=business, role=ownership_entity;
the beneficial_owner/representative/controlling_person roles are natural people.
The business adapter may propose candidate people, but a human must reconcile
ownership/authority and commit the reviewed subject set before person checks.
Do not infer customer type/people/cases from documents or filenames.

Use the REST conditional-write pattern, not a generic unconditioned Update item,
for locks, resumes and case/state changes. Preserve exact ETags; 412 is a
conflict, not permission to overwrite. No wildcard If-Match, no expiring-lock
auto-takeover, no exactly-once or cross-list transaction guarantee is claimed.
Detailed flow/recovery steps are in the linked flow source.

## Knowledge ingestion and updates

The [source mapping](../knowledge/README.md) assigns distinct topics to each role;
the machine-readable manifest matches the agent referenceSources. Operations
owns the data-protection/record-keeping file; country overlays remain unapproved.
The source register, approval decisions and manifests are governance records,
not facts about a case or substitutes for an executable policy rule bundle.

After Compliance/Legal/DPO approval and a separate explicit authorization to
configure the named environment:

1. Resolve the decision register and applicable country/EEA overlays. Release
   signed-off reference files with approver/date/change history. Do not change
   `productionEnabled` merely because files are present. Keep the current
   draft out of production and leave null policy bindings null.
2. In each relevant agent's **Knowledge > Add knowledge**, upload only its
   approved mapped Markdown files, give clear scope/version descriptions, and
   finish **Add to agent**. Microsoft currently documents `.md` support.
   Uploads use Dataverse storage/search; confirm Dataverse search, DLP, licensing
   and access requirements with the administrator. SharePoint case storage
   remains a list; knowledge storage is a separate platform concern.
3. Uploaded knowledge is available at agent scope and must not be assumed to
   retain an original document's per-user ACL. Use only material authorized for
   the agent's audience; never upload customer files, identity records, provider
   reports, suspicion/STR records, live sanctions datasets or restricted case
   snapshots as shared knowledge. Source-selection prompts are not ACLs.
4. Knowledge answers remain reference guidance. The flow still checks approved
   policyVersion/countryRulesVersion and concrete provider evidence. If
   reference guidance conflicts, preserve policy_conflict/policy_gap for review,
   never choose a favorable answer or silently treat future law as current.
5. Record the released knowledge pack version with the request snapshot and,
   when used, configuration.knowledgePackVersion. Record consulted file/section/
   pack in result.knowledgeReferences separately from evidenceUsed. Reject a
   citation to another role's source, unknown version or customer document.
6. On updates, use the Knowledge UI's supported replace/delete-and-add process
   available in the tenant, wait for the source to be ready, remove superseded
   versions, verify retrieval/citations and rerun contract/adversarial tests.
   Republish only when authorized. Preserve the prior source/version for audit;
   do not assume replacing a local file updates the cloud agent.

Retrieval is non-deterministic grounding, not a rule engine or evidence that a
check ran. A model must not turn a draft checklist into a universal requirement.
Customer templates/tax supplements need separate Compliance, Legal and Tax
approval; do not make all forms/documents mandatory for all customers.

## V1-compatible migration

Keep all v1 files, schemaVersion=1.0 fixtures and original event payload/result
unchanged. The deterministic `sp-created:v1:...` EventKey remains the same.
V2 adds a [metadata sidecar](../orchestrator/v2/intake-context.schema.json) and
a separate [flow disposition](../orchestrator/v2/orchestration-result.schema.json).
It never changes a v1 pending_integration response into a false downstream success.

During an authorized cutover, pause v1, drain/reconcile its active runs, add the
ledger columns/choices and required lists/ACLs, build a **disabled** v2 intake
flow, then test in development before enabling one creation-trigger path only.
Legacy rows retain ContractVersion=1.0 (explicitly populate it when migrating)
and generation=0 until an authorized resume. Do not backfill/replay all files.
Legacy PendingIntegration rows may be enrolled only by selected-item resume
after case/scope/evidence review; failed/ambiguous runs need reconciliation first.
Preserve EventPayload, ResultPayload, EventKey and OwnerRunId for audit.

Missing/late/invalid CaseId metadata leads to WaitingForCase or CaseReviewRequired,
not a guessed case or dropped event. Correcting metadata does not retrigger a
creation-only flow. The controlled resume operates on the **existing ledger
row/key**, captures current file metadata/version, and conditionally advances
the generation after authorization. Once bound, a changed CaseId must be held
for review, never silently rebind an event to a different case.

## Validate and generate native artifacts

```powershell
pwsh -NoProfile -File .\scripts\Test-OrchestratorContracts.ps1
pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1
node .\customer-templates\generator\generate.js
```

Local checks exercise schema/correlation, scoped references, missing-config
fail-closed behavior, preserved screening hits, business sequence, metadata
resume shapes and INT-1/CO class mapping. They do not prove actual permissions,
model behavior, providers, platform schema keyword enforcement or concurrency.
The form generator creates real editable OOXML documents, not protected form
controls or a server-side intake validation service.

Tenant acceptance must cover: valid individual and business paths; ownership
review before checking related people; no provider/configuration as blocked;
missing/invalid/late/cross-case metadata; unauthorized upload/resume; duplicate
and concurrent events/resumes; same-case two-file contention; exact ETag 412;
stale case/file/policy/subject versions; errors/timeouts/failed writes; omitted
screening subjects; possible-hit downgrade attempts; prompt-injected evidence;
conflicting/unapproved knowledge; and final human decisions remaining separate.
No live verification/screening success can be accepted without real approved
provider evidence and tenant tests.

After authorized tests, export the actual solution with dependencies,
connection references and environment variables, and clone agents using the
Copilot Studio VS Code extension for native validated source. Keep tenant
values/credentials and customer data out of Git. SharePoint list/ACL provisioning
is external to solution export and must be repeated/verified at the target.

## Verified Microsoft sources

Checked 2026-11-19, using Microsoft Learn MCP search/fetch where available:

- [Connector invocation and response envelope](https://learn.microsoft.com/en-us/connectors/microsoftcopilotstudio/).
- [Native child/connected agent capabilities](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-add-other-agents).
- [Native editable source structure](https://learn.microsoft.com/en-us/microsoft-copilot-studio/visual-studio-code-extension-edit-agent-components)
  and [solution export](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-solutions-import-export).
- [SharePoint HTTP action](https://learn.microsoft.com/en-us/sharepoint/dev/business-apps/power-automate/guidance/working-with-send-sp-http-request)
  and [REST exact ETag/412 behavior](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/working-with-lists-and-list-items-with-rest).
  The latter page also covers retired Add-ins; this design uses supported
  SharePoint REST through the connector, not retired Add-in authentication.
- [Supported knowledge uploads and Markdown](https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-add-file-upload).

No suitable authenticated tenant-service MCP/target was supplied for platform
provisioning; none was attempted. Public regulatory sources were verified using
direct primary-source web retrieval where no regulatory MCP was available.
