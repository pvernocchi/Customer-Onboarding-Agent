# 01 - SharePoint onboarding orchestrator: setup and verification

## Installation sequence

Start with [00 - Installation order](00-agent-installation-guide.md).
This file is the v1 infrastructure/setup runbook, not an executable script.
Follow this exact sequence:

1. Complete **Prerequisites and configuration**, then **Durable ledger** below.
   Leave the intake flow off.
2. Follow [02 - Orchestrator installation](02-agent-installation-orchestrator.md)
   to prepare and test the single V1 agent. Use the existing imported agent
   or create it manually, not both.
3. Return here for **Build the Power Automate flow**, failure monitoring,
   recovery, and **Verify before enabling real intake**. Run the v1 local
   contract command before tenant acceptance; local checks alone are not
   deployment evidence.
4. For a v1-only installation, stop after acceptance until activation is
   explicitly authorized. For the complete solution, continue with
   [03 - Specialist setup](03-specialist-setup.md), then guides 04 through 08
   in numeric order. Do not enable a second creation-trigger path.

This guide remains the immutable-contract **v1 baseline**. For the compatible
five-specialist/case-metadata extension and explicit migration/resume process,
see [specialist setup](03-specialist-setup.md). Do not combine both trigger paths.

## Status and integration choice

**Source scaffold only. Nothing has been created, published, or tested in a
tenant.** This guide, the agent instructions, configuration example, JSON
contracts, and synthetic fixtures are manual authoring inputs, not an importable
solution, connector definition, or generated Copilot Studio source tree.

Use a solution-aware **Power Automate automated cloud flow**:

SharePoint new-file trigger -> validate metadata -> durable unique intake claim
-> Copilot Studio **Execute Agent and wait** -> validate response -> persist
**PendingIntegration**, with a separate failure path.

The documented Microsoft Copilot Studio connector operation for **Execute Agent
and wait** is `ExecuteCopilotAsyncV2`. It accepts **Agent**, **Message**, optional
**Environment ID**, and returns `lastResponse`, `responses`, `conversationId`.
Use the connector UI to generate bindings; this repository does not fabricate
workflow JSON or connection-reference IDs.

Native Copilot Studio event triggers are also supported with generative
orchestration, but are not configured here. The explicit cloud flow provides
deterministic validation, an atomic intake claim, and failure handling before
an agent sees metadata. Do not enable both paths for the same intake.

## Prerequisites and configuration

An authorized maker must supply a development Power Platform environment with
Dataverse and suitable solution permissions (at least System Customizer for
agent solution export), Copilot Studio access/capacity, Power Automate
entitlements, and authenticated SharePoint and Microsoft Copilot Studio
connections. Connector classification alone does not establish licensing.
Confirm connector availability, DLP policies, region/data residency, bank
retention rules, run-history access, and unattended connection ownership with
the tenant administrator. No approval or compliance outcome is implied.

Use a generic SharePoint Online document library, initially synthetic documents
only. This is a library-scoped trigger, not a whole-site subscription: every
additional library needs its own configured flow, sharing the same ledger.
Existing files are not backfilled. Overwriting/editing an existing file is not
a new-file event; do not substitute a created-or-modified trigger.

1. In Power Apps or Power Automate **Solutions**, create an unmanaged development
   solution named `OnboardingOrchestrator`, using an organization-approved
   publisher with prefix `onb` (or consistently change the names below).
2. Create Text environment variables for every entry under
   `environmentVariables` in [the configuration example](../orchestrator/config.example.json).
   Supply real current values only in the tenant, not in this example.
   `onb_SiteId` is the SharePoint site collection GUID, not a Graph composite ID;
   verify it belongs to `onb_SiteUrl`. Tenant, site, and library GUIDs must be
   lowercase canonical GUIDs without braces. Keep the site URL canonical and
   fixed; verify the library GUID belongs to that site. Environment ID uses the
   actual identifier required by the connector; do not manufacture one.
3. Create and bind solution connection references through the designer.
   Connections and credentials are not environment-variable values. Give the
   intake connection read access to the selected library and write access only
   to a restricted operations ledger. Prefer a bank-managed connection owner;
   verify authentication can run unattended and complies with tenant policy.
4. Configure the ledger and agent below before enabling the flow. Keep the flow
   off during construction. Publishing or enabling anything requires a separate
   explicit deployment request and target; these are provisioning instructions,
   not authorization to deploy.

## Durable ledger (required, not an in-memory cache)

Create a restricted **SharePoint list**, outside the watched document library,
with the following columns. Use these exact names when creating columns so
their internal names match. Set Title to the event key as well.

| Column | SharePoint type / rule |
| --- | --- |
| EventKey | Single line of text, required, **Enforce unique values = Yes** (indexed) |
| State | Choice: Processing, PendingIntegration, Failed, NeedsReconciliation |
| OwnerRunId | Single line of text, required; creating flow run ID |
| ReceivedAt | Date and time, required; UTC intake time |
| UpdatedAt | Date and time, required; UTC last write |
| EventPayload | Multiple lines of plain text; normalized input snapshot |
| ResultPayload | Multiple lines of plain text; validated result only |
| ConversationId | Single line of text; connector response correlation |
| ReviewState | Choice: RequiredNotAssigned, UnderReview, Resolved |
| ErrorCode | Single line of text; sanitized operational code |
| ErrorRunId | Single line of text; failed run correlation, not raw error content |

No customer or case identifier is derived from this row's ID. This is an
**intake ledger and review backlog**, not a customer master or case database.
Human operators own review; this slice neither assigns a reviewer nor creates
an approval. Restrict editing/deletion of EventKey, OwnerRunId, and payloads to
operations administrators. Set retention explicitly: deleting a key permits
redelivery to process again. Do not purge keys while replay remains possible.

The event identity is the exact concatenation:

```text
sp-created:v1:<tenant-guid>:<site-collection-guid>:<library-guid>:<positive-item-id>
```

All GUIDs are canonical lowercase without braces; item ID is decimal without
leading zeroes. This fits the 255-character unique text column (the v1 contract
caps it at 150). It identifies creation of a list item in a library, not a flow
run, filename, path, document version, customer, or case. Duplicate delivery,
renaming, or replay of the same item keeps the key; a distinct newly created
item gets a different key. Recreating a library requires its new library GUID.

## Prepare the Copilot Studio agent

1. In the chosen development environment, open the imported **Customer Onboarding
   Intake Orchestrator**, or create that **standard-harness** agent if using the
   manual path. Add the existing agent to the custom solution if needed. Record
   its platform-generated Agent ID in `onb_AgentId`.
2. Verify the agent's **Instructions** against
   [agent-instructions.md](../orchestrator/agent-instructions.md), or paste them
   for manual creation. Enable generative orchestration if required by the
   selected agent experience. Do not add a native event trigger.
3. Add no knowledge sources, document uploads, web search, downstream agents,
   or tools. Disable general-knowledge/web capabilities available in the
   experience. Review default topics so no greeting, fallback, sign-in prompt,
   or conversational follow-up is emitted for valid intake messages.
4. Test with the synthetic input as a single JSON message. Require a single
   result matching the result fixture, with the input eventId echoed exactly.
   Instructions are not a security or schema-enforcement boundary; the flow
   must reject any nonconforming response. Never enable tools just to obtain
   the fixed pending-integration result.
5. Once explicitly authorized for a named tenant/environment, publish the agent
   for connector invocation and verify access with the chosen connection.
   Authentication requirements depend on the tenant; do not disable
   authentication or use an anonymous channel as a workaround.

## Build the Power Automate flow in the solution

Names such as `Build_event` below are author-selected action labels, not
connector operation IDs. Use dynamic-content tokens from a synthetic trigger
run to confirm actual field names/types. Do not paste raw trigger JSON into
the agent message.

1. Add SharePoint **When a file is created (properties only)**. Set **Site
   Address** = `onb_SiteUrl`, **Library Name** = `onb_LibraryId` using custom
   value/environment-variable selection. Leave optional folder filtering empty.
   Do not use the deprecated folder trigger. The trigger provides metadata,
   **not document bytes or extracted text**. If the designer requires selecting
   a library to discover its schema, select the synthetic library first, then
   bind the variables and verify tokens in a test run.
2. Add a Condition: folders must terminate without invoking the agent or
   claiming a file event. Validate **IsFolder** is explicitly false; a missing
   value fails validation, not a default to false. Map the trigger **ID** to the
   library item ID, **Identifier** to the opaque fileIdentifier,
   **File name with extension** to fileName, and **Created** to createdAt.
   Never use the filename/path as an identifier. No **Get file content** action
   belongs in this slice. If a required property is absent, fail explicitly;
   a verified **Get file properties** action may supply missing metadata.
3. Validate configuration and input before calling the agent: expected site and
   library, positive integer item ID, nonempty identifier/name, UTC Created,
   and canonical GUIDs. Validate Created as an actual calendar date/time, not
   merely an ISO-shaped string; the local validator supplements JSON Schema's
   format annotation with a date parser. Use configured IDs/URL, not
   caller-provided identity.
   Construct the event as an **object** in a Compose action named `Build_event`
   with the exact fields in the [event schema](../orchestrator/contracts/intake-event.schema.json).
   Serialize the object rather than interpolating raw filenames into JSON.
   Build EventKey from the configured IDs and the validated item ID. Example
   expression, assuming Compose actions named `Tenant_id`, `Site_id`,
   `Library_id`, and `Item_id` already contain validated canonical values:

   ```text
   concat('sp-created:v1:', outputs('Tenant_id'), ':', outputs('Site_id'), ':', outputs('Library_id'), ':', string(outputs('Item_id')))
   ```

   Add **Parse JSON** using the event schema; explicitly compare eventId with
   the recomputed EventKey. Power Automate schema keyword/format enforcement
   must be verified in the target environment; supplement it with Conditions
   for all stated constraints, including allowed fields and fixed enums.
4. **Claim** with SharePoint **Create item** in the ledger: EventKey and Title,
   State=Processing, ReviewState=RequiredNotAssigned, OwnerRunId=
   `workflow()?['run']?['name']`, ReceivedAt/UpdatedAt=`utcNow()`, and
   EventPayload=`string(outputs('Build_event'))`. The enforced unique column,
   not a preceding Get items check, arbitrates concurrent claims. Save its ID.
   Set **Create item Retry policy = None** so ambiguous creates enter the
   resolution path. Only a run that owns a confirmed claim may proceed.
5. Add a claim-resolution Scope configured with **Run after** for claim failure
   and timeout. Query **Get items** with `EventKey eq '<validated-key>'`, Top
   Count 2 (key characters cannot contain quotes). Zero rows, more than one,
   or a read failure means **Terminate: Failed**; do not interpret 401/403/429
   or an outage as a duplicate. One row with another OwnerRunId means a
   duplicate: do not invoke the agent or update that row. Record run-local
   duplicate disposition and **Terminate: Cancelled**; this is not evidence
   that the earlier run succeeded.
   Failed/stale existing work remains visible for reconciliation.
   A row owned by this run after an ambiguous Create timeout proves that its
   claim persisted: terminate Failed for operator reconciliation rather than
   dispatching from this failure branch. Do not blindly retry Create item.
6. On the confirmed **Create item succeeded** path only, call Microsoft Copilot
   Studio **Execute Agent and wait**. Agent=`onb_AgentId`, Environment ID=
   `onb_EnvironmentId`, Message=`string(outputs('Build_event'))`, locale=`en-GB`.
   Leave Conversation ID empty so files/customers never share conversation
   state. Do not pass content/contentUrl or a document attachment. Set the
   action's **Retry policy = None** to avoid an automatic second invocation
   after an ambiguous response; handle the failure explicitly.
7. Parse `lastResponse` directly using the
   [result schema](../orchestrator/contracts/orchestration-result.schema.json).
   Require exactly one `responses` entry equal to `lastResponse`, nonempty
   conversationId, exact eventId equality, exactly the allowed properties,
   and every fixed value shown in the fixture. Reject prose, fences, missing/
   extra fields, invented case/customer IDs, approval claims, and other status
   values. Do not strip fences, silently coerce data, or default to success.
8. Recheck that the ledger row belongs to this run and is still Processing.
   **Update item** to State=PendingIntegration, ResultPayload=validated JSON,
   ConversationId=response correlation, UpdatedAt=`utcNow()`,
   ReviewState=RequiredNotAssigned. Preserve EventPayload and OwnerRunId.
   Only a successful durable update means intake assessment was recorded.
   The flow may then finish successfully; **PendingIntegration is not
   customer onboarding completion**.
9. Put dispatch, response validation, and final write inside a **Process**
   Scope. Add a **Failure** Scope with Run after = failed/timed out, including
   validation Condition failures (explicitly route them to this failure path;
   a false condition alone is not a failed action). With a confirmed owned
   row, persist State=Failed for definitive validation/connector errors or
   NeedsReconciliation for ambiguous timeout/write outcomes, ErrorCode,
   ErrorRunId, and UpdatedAt. Do not store raw connector errors or customer
   data in ErrorCode. End with **Terminate: Failed** even if logging succeeds.
   If error persistence fails, still Terminate Failed; flow run history and
   the stale Processing row are the fallback evidence, not a success record.
   Pre-claim validation/configuration failures also Terminate Failed and are
   visible in run history without an agent call.

Configure tenant-native failed-run monitoring and an operations owner before
activation. Operators must regularly inspect **Failed**, **NeedsReconciliation**,
stale **Processing**, and **PendingIntegration / RequiredNotAssigned** views.
Define an operational stale threshold longer than the configured maximum
Process/connector duration. Do not auto-reclaim on a timer.

### Recovery and delivery guarantees

This is at-most-one automatic dispatch per durable event claim, **not an
exactly-once transaction across SharePoint and Copilot Studio**. Timeouts can
leave an agent response or ledger write with an unknown outcome. Duplicate
runs must not reset/retry Failed, NeedsReconciliation, or stale Processing rows.
Connector/service-internal behavior still requires tenant verification.

For recovery, an operator disables the intake flow, waits for active runs to
finish/cancels and reconciles them, inspects connector/run history, and records
their decision in ledger version history. Do not delete the key or blindly
resubmit a run. Reprocessing after an uncertain dispatch needs a separately
reviewed recovery flow/runbook; it is not supplied in this slice. The agent has
no side effects now; future downstream execution needs its own idempotency
keys, authorization, authoritative case linkage, and explicit human controls.

## Verify before enabling real intake

Local: run `pwsh -NoProfile -File .\scripts\Test-OrchestratorContracts.ps1`.
It validates synthetic fixtures and rejects malformed/false-success results.
It does not run a flow, call an agent, or prove prompt-injection resistance.

In the authorized development tenant, record evidence for each acceptance case:

| Test | Required observation |
| --- | --- |
| New synthetic file, including a subfolder upload | One normalized event, one ledger row, one agent call, PendingIntegration |
| Rename/edit/overwrite existing file | No new creation event; no new assessment for that item |
| Same filename, different new item IDs | Distinct events; neither implies a shared customer or case |
| Duplicate and concurrent deliveries | Unique claim; no second automatic agent dispatch |
| Folder or missing/invalid metadata | No agent call; invalid metadata run fails visibly |
| Filename containing quotes or instructions | JSON remains valid; no tool use, identity inference, or changed fixed output |
| Connector denied/throttled/timed out | Failed run and Failed/NeedsReconciliation state; no success fallback |
| Multiple responses, malformed JSON, wrong eventId, invented approval/case | Failed run; no PendingIntegration result accepted |
| Ledger unavailable before/after dispatch | Failed run; no unclaimed dispatch; stale work reconciled manually |
| Operator review | RequiredNotAssigned remains visible; no reviewer/approval fabricated |

## Generate real platform source and move environments

After authorized provisioning and tenant acceptance, add agent, cloud flow,
connection references, and environment variables to the unmanaged solution.
Use **Add required objects** for the agent and flow, inspect dependencies, then
**Export solution** through the platform. Keep environment-specific current
values and credentials out of source control. Import into the named target,
bind connection references and variable values, reconfigure authentication,
publish the agent only with authorization, and repeat acceptance checks before
enabling the target flow. SharePoint ledger/list provisioning is external to
the solution and must be repeated with its unique constraint.

For editable native agent source, install the Microsoft Copilot Studio VS Code
extension, sign in, select the existing development agent and **Clone Agent**
into a new repository subfolder. The extension generates `agent.mcs.yaml`,
topics/settings/connections and related components; review/sanitize the actual
generated files before committing. Use its schema validation and apply/sync
workflow. Do not rename these manual templates to `.mcs.yaml` or zip them and
claim they are an exported solution. Native export/clone, designer validation,
authentication, connector invocation and end-to-end operation cannot be
verified here without a selected tenant/environment and authenticated access.

## Official references

Verified against Microsoft Learn on 2026-11-19:

- [SharePoint trigger behavior](https://learn.microsoft.com/en-us/sharepoint/dev/business-apps/power-automate/sharepoint-connector-actions-triggers)
  and [connector reference](https://learn.microsoft.com/en-us/connectors/sharepointonline/):
  use **When a file is created (properties only)**; folder triggers are deprecated.
- [Copilot Studio connector](https://learn.microsoft.com/en-us/connectors/microsoftcopilotstudio/):
  **Execute Agent and wait**, `ExecuteCopilotAsyncV2`, documented response envelope.
- [Native event triggers](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-triggers-about):
  generative orchestration, publication and maker-credential considerations.
- [Export/import agents using solutions](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-solutions-import-export):
  generated solution packaging, dependencies and reauthentication.
- [Clone an agent in VS Code](https://learn.microsoft.com/en-us/microsoft-copilot-studio/visual-studio-code-extension-clone-agent)
  and [edit generated agent components](https://learn.microsoft.com/en-us/microsoft-copilot-studio/visual-studio-code-extension-edit-agent-components):
  supported native YAML/source workflow.
