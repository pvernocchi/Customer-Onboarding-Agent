<div align="center">

# 🏦 Customer Onboarding Agent

**A source-first, multi-agent onboarding workflow design for an EU/EEA bank**

[![Status: source scaffold](https://img.shields.io/badge/status-source%20scaffold-blue)](#-delivery-status)
[![Platform: Power Platform](https://img.shields.io/badge/platform-Microsoft%20Power%20Platform-742774)](#-architecture)
[![Scope: EU/EEA](https://img.shields.io/badge/scope-EU%2FEEA-155EEF)](#-scope-and-intended-use)
[![Contracts: versioned JSON](https://img.shields.io/badge/contracts-versioned%20JSON-00875A)](#-contracts-and-validation)

*Controlled intake, traceable evidence preparation, and human-led review — not automated onboarding decisions.*

</div>

> [!IMPORTANT]
> **Six agent-only solution ZIPs are available, but no tenant import has been verified.** See the [build and import guide](docs/09-build-and-import.md). The cloud flows and bindings still require authoring in an approved tenant. Do not use real customer data with this scaffold.

## ✨ At a glance

This project describes a staged onboarding workflow for **individuals and businesses** in an EU/EEA banking context:

- **V1 intake slice:** a SharePoint new-file event is normalized and durably claimed, then sent as metadata-only JSON to a Copilot Studio intake orchestrator. A validated response records `PendingIntegration`; it does not create a customer or case.
- **V2 source-first expansion:** a controlled Power Automate flow design links an intake event to an authorized SharePoint case, captures versioned evidence, and coordinates five focused specialist agents through explicit contracts and deterministic gates.
- **Human control:** ownership, identity conflicts, possible screening hits, risk and final onboarding decisions remain subject to authorized human review. The workflow never equates a draft with a verification or approval.
- **Local utilities:** PowerShell contract checks and a dependency-free Node.js generator for nine editable Word template drafts.

## 🧭 Contents

- [Delivery status](#-delivery-status)
- [Scope and intended use](#-scope-and-intended-use)
- [Architecture](#-architecture)
- [Workflow walkthrough](#-workflow-walkthrough)
- [Specialist agents](#-specialist-agents)
- [Data, contracts, and controls](#-data-contracts-and-controls)
- [Repository map](#-repository-map)
- [Run local checks and generate templates](#-run-local-checks-and-generate-templates)
- [Tenant setup and controlled deployment](#-tenant-setup-and-controlled-deployment)
- [Security, privacy, and recovery](#-security-privacy-and-recovery)
- [Known limitations](#-known-limitations)

## 🚦 Delivery status

| Area | Current state | What this means |
| --- | --- | --- |
| Agent packaging | Six [PAC-generated solution ZIPs](deployment/packages/), build script and offline authoring inventory | Archive structure, prompts and capability settings checked locally; no tenant import. |
| V1 SharePoint intake | Manual setup guide, instructions, JSON schemas and synthetic fixtures | No flow or agent has been provisioned, published or tenant-tested. |
| V2 cases and specialists | Manual designs, instructions, routes, schemas and examples | No executable cloud flow, specialist agent, case list, provider adapter or permission model is supplied. |
| Knowledge pack | `0.1.0-draft` reference material | Not approved legal advice, bank policy, a rule engine or production knowledge configuration. |
| Customer templates | CO-00–CO-08 editable Word drafts | Not approved forms, protected form controls, signed records or a customer portal. |
| Local validation | PowerShell contract checks; Node.js template generator | These run locally; they do not prove cloud behavior, permissions, model behavior or provider execution. |

**Only synthetic examples are included.** Microsoft Power Platform resources, SharePoint lists, connections, credentials, provider integrations, screening results and customer records are not included or claimed to exist.

## 🎯 Scope and intended use

The design covers document intake and controlled preparation of customer due-diligence evidence for individual and business onboarding. It is intended as a **starting point for a bank's engineering, operations, Compliance, Legal, Data Protection Officer (DPO), MLRO and Tax teams** to review and adapt.

It is not a universal KYC checklist or a statement of the rules applicable in any particular country. The bank must define and approve its policies, national and EEA overlays, providers, lawful basis, accepted evidence, retention, access model, and customer communications before use.

## 🏗️ Architecture

The diagram shows both the **implemented-as-source V1 baseline** and its **V2 design expansion**. Solid arrows describe intended data/control flow, not deployed integrations. Dashed links denote reference material or human-controlled activity. In particular, V1 and V2 must not be enabled as competing file-creation trigger paths for the same intake.

```mermaid
flowchart LR
  subgraph Actors[Actors and source material]
    U[Bank operator / authorized uploader]
    Forms[CO-00–CO-08 Word drafts<br/>conditional customer inputs]
    Knowledge[Draft knowledge pack<br/>reference only; approval required]
    Human[Authorized human reviewers<br/>ownership · identity · screening · risk · final decision]
  end

  subgraph SharePoint[SharePoint Online · provisioned by the bank]
    Library[Configured document library<br/>file metadata and documents]
    Ledger[(Restricted intake ledger<br/>unique EventKey · state · audit references)]
    Cases[(OnboardingCases<br/>authoritative case and scope snapshot)]
    Evidence[(OnboardingEvidence<br/>immutable evidence references and versions)]
    Journal[(OnboardingStageExecutions<br/>unique operation keys and stage states)]
  end

  subgraph Flow[Power Automate · solution-aware flows authored in tenant]
    V1[V1 intake flow<br/>validate metadata · claim · dispatch · persist]
    V2[V2 orchestrator flow<br/>authorize case · lock · version · route stages]
    Resume[Restricted selected-item resume flow<br/>operator-authorized pending work]
    Adapters[Future approved adapters<br/>extraction · identity · registry · screening · policy]
  end

  subgraph Copilot[Microsoft Copilot Studio · separately authored agents]
    Intake[Customer Onboarding<br/>Intake Orchestrator]
    Doc[Document Evidence]
    Person[Natural Person Verification]
    Business[Business Verification]
    Crime[Financial Crime Screening]
    Risk[Risk Review Preparation]
  end

  U -->|new file| Library
  Library -->|properties-only creation event| V1
  V1 -->|normalized metadata JSON only| Intake
  V1 -->|unique claim, validated result, failure state| Ledger
  Intake -->|single structured response| V1

  Library -->|event + CaseId metadata; V2 design| V2
  V2 -->|validate unique case, folder, ACL and scope| Cases
  V2 -->|owned case reservation; exact-ETag updates| Cases
  V2 -->|claim, generation, disposition| Ledger
  V2 -->|versioned snapshots| Evidence
  V2 -->|unique stage claim and outcome| Journal
  V2 -->|approved evidence/provider tasks| Adapters
  Adapters -->|source-located evidence and normalized reports| Evidence
  Adapters -->|validated task context| V2
  V2 -->|role-specific JSON; sequential invocation| Doc
  V2 -->|after reviewed subject gate| Person
  V2 -->|business evidence and candidate ownership| Business
  V2 -->|all in-scope subjects after review| Crime
  V2 -->|approved rule outputs and preserved gaps| Risk
  Doc -->|draft result| V2
  Person -->|draft result| V2
  Business -->|candidate relationships, not accepted ownership| V2
  Crime -->|report summary, never hit clearance| V2
  Risk -->|review pack, never a decision| V2
  V2 -->|blocked/review result reference| Ledger
  V2 -.->|case-scoped sources, only after approval| Knowledge
  Knowledge -.->|role-mapped reference guidance| Doc
  Knowledge -.->|role-mapped reference guidance| Person
  Knowledge -.->|role-mapped reference guidance| Business
  Knowledge -.->|role-mapped reference guidance| Crime
  Knowledge -.->|role-mapped reference guidance| Risk
  Forms -.->|selected, bank-approved inputs| U
  Human -->|accept subject set, reconcile exceptions,<br/>make decisions outside agent authority| Cases
  Human -->|inspect holds, stage history and evidence| Ledger
  Human -->|authorized resume after correction/reconciliation| Resume
  Resume -->|same event key; controlled new generation| V2
```

### Component responsibilities

| Component | Responsibility and boundary |
| --- | --- |
| SharePoint document library | Bank-configured intake location. The V1 trigger reads file properties, not document bytes. V2 separately authorizes case scope and captures immutable evidence only after required gates. |
| V1 Power Automate flow | Validates event metadata, builds a deterministic event key, makes a unique durable claim, invokes the intake agent once, validates its response and records a pending integration or explicit failure state. |
| V2 Power Automate flow | The deterministic controller: validates case authorization, reserves a case using exact ETags, enforces route and version gates, dispatches stages, validates responses, aggregates holds, and records recovery states. It is design source only. |
| Copilot Studio agents | Produce constrained draft assessments from validated role-specific requests. Agents do not call providers, browse, write case data, or make decisions. Each invocation uses a fresh conversation and no automatic retry. |
| SharePoint intake ledger | Durable, restricted event identity and operational state. It is not a customer master or case database. V2 preserves V1 event keys and payloads and stores separate V2 snapshot references. |
| SharePoint case and stage lists | V2's authoritative case metadata/reservation and immutable stage-operation journal. Exact-ETag writes and unique keys prevent unsafe overwrites/duplicate dispatch claims. |
| Evidence library and future adapters | Bank-approved services must retrieve/extract evidence or call real providers. Only source/version-backed outputs may enter validated tasks; no adapters or provider bindings are implemented here. |
| Knowledge and customer forms | Draft references and optional, conditional customer-input templates. Neither is evidence that a check ran or an authority to collect every document. |
| Human review | Authorized people reconcile evidence, ownership, possible matches, policy conflicts and gaps, and make any final decision through a separate bank process. |

## 🔄 Workflow walkthrough

### V1 — metadata-only intake baseline

1. A new file in the configured SharePoint library triggers **When a file is created (properties only)**. This is library-scoped; existing files and edits/overwrites are not backfilled as new-file events.
2. The flow rejects folders and invalid or missing metadata, then constructs a normalized event. File name and identifier are metadata, not customer or case identity. No `Get file content` action belongs in this slice.
3. A restricted SharePoint ledger enforces uniqueness of `EventKey` to arbitrate duplicate/concurrent delivery. Only the run that confirms its claim may continue.
4. The flow calls Copilot Studio **Execute Agent and wait** with one serialized JSON event and an empty conversation ID. The intake agent has no tools, knowledge sources, document uploads or downstream agents.
5. The flow validates the response envelope and exact schema/correlation, then writes `PendingIntegration`. Connector ambiguity, invalid responses and persistence errors remain visible as `Failed` or `NeedsReconciliation`; they are not success.

`PendingIntegration` means only that the intake assessment was durably recorded. It does **not** create a customer or case, run identity/KYC/AML checks, approve a customer or complete onboarding.

### V2 — case-linked specialist design

V2 is a compatible, manual extension; it does not mutate V1 schemas or re-interpret a V1 pending result as successful downstream work.

1. The flow validates the case metadata against the bank-managed case list, the configured tenant/site/library, the case's intake folder, verified permissions and authenticated upload context. Missing or invalid case metadata is held for review; a model or filename never supplies identity or case linkage.
2. It freezes the authorized case, policy, subject-set and file-version context. A case-level exact-ETag reservation prevents overlapping work on the same case while allowing separate cases to proceed.
3. Role-specific request objects are written to versioned snapshots and unique stage-journal rows. Providers are called only by separately approved/configured flow adapters; model agents receive validated task context, never arbitrary endpoints or provider credentials.
4. The flow invokes agents in deterministic order, validates a single response and every event/operation/case/revision/subject/evidence reference, then records only a draft, blocked outcome or review requirement.
5. The flow aggregates all upstream issues and holds without allowing a risk summary to erase them. It conditionally releases only reservations owned by that run. Final approved/rejected/closed transitions remain outside this workflow.
6. Eligible pending work can be resumed only by an authorized operator through the separate selected-item flow after review. Resume preserves the same event key and history; uncertain dispatches require reconciliation, not blind retry.

**Routes:**

- **Individual:** document evidence → reviewed in-scope person set → natural-person assessment → financial-crime screening of every in-scope subject → risk-review preparation.
- **Business:** document evidence → business registry/ownership/authority evidence → **human-reconciled ownership and subject set** → natural-person assessment for related people → screening of the business and all relevant people → risk-review preparation.

An incomplete ownership graph blocks the related-person and screening stages until a human accepts the subject set. Possible screening hits cannot be cleared by an agent. When a provider or policy binding is absent, the stage is blocked and no fictitious result is created.

## 🤖 Specialist agents

Each V2 specialist has a distinct instruction file and role-discriminated request/result contract. Shared instructions establish data boundaries and require exactly one JSON response. A configured ID or draft response never proves that a provider ran.

| Role | Preparation responsibility | Required binding in a future tenant |
| --- | --- | --- |
| `document-evidence` | Classify documents and propose source-located evidence claims; does not verify identity. | `documentExtractor` |
| `natural-person` | Prepare identity evidence assessments for customers, representatives and beneficial owners. | `identityProvider` |
| `business` | Prepare business, ownership and representation evidence for human reconciliation. | `businessProvider` |
| `financial-crime` | Summarize approved-source reports for all in-scope people and businesses; never clear hits. | `screeningProvider` |
| `risk-review` | Prepare a traceable review pack from approved, versioned rule outputs; no model decision. | `policyRules` |

All specialist calls are intended to use **Execute Agent and wait** with serialized role-specific JSON, a fresh conversation, and retry policy `None`. The Power Automate flow—not the model—owns authorization, ordering, provider invocation, idempotency, result validation, persistence and recovery.

## 🧾 Data, contracts, and controls

### Versioned contracts

- **V1:** `orchestrator/contracts/intake-event.schema.json` and `orchestrator/contracts/orchestration-result.schema.json` define a metadata-only event and explicit pending-integration result. Synthetic fixtures live in `orchestrator/examples/`.
- **V2:** `specialists/contracts/specialist-request.schema.json` and `specialists/contracts/specialist-result.schema.json` define role-specific tasks, version/case/event correlation, allowed references and non-decision outcomes.
- **V2 sidecars/results:** `orchestrator/v2/intake-context.schema.json` and `orchestrator/v2/orchestration-result.schema.json` add case context and a separate flow disposition without changing V1 payloads.
- **Synthetic examples:** `specialists/examples/` and `orchestrator/v2/examples/` are local fixtures, not real customer data or one end-to-end execution trace.

Schemas are supplemented with explicit flow conditions and semantic reference checks. JSON Schema format annotations or local validation do not, on their own, prove that the target Power Automate designer enforces every constraint.

### Durable identity and safe retries

V1 `EventKey` identifies a new library item using the configured tenant, site, library and positive item ID. It is independent of the filename, path, flow run, customer or case. SharePoint's enforced unique column arbitrates concurrent claims; a prior `Get items` check is not a lock.

V2 stage operation keys add the unchanged event key, authorized generation, case revision, subject-set version, role and instruction version. Exact-ETag conditional writes protect case reservations, resumes and state updates. A `412` conflict is not permission to overwrite. No cross-list/provider transaction or exactly-once guarantee is claimed.

### Operational states and recovery

V1 uses `Processing`, `PendingIntegration`, `Failed` and `NeedsReconciliation`, with a separate review-state field. V2 adds holds such as `WaitingForCase`, `CaseReviewRequired` and `WaitingForCaseBusy`, plus `V2Processing`, `V2Blocked` and `V2ReviewRequired`.

Operators are expected to monitor stale processing, failed, reconciliation and unassigned-review work. Ambiguous writes or dispatch timeouts can have unknown outcomes; do not automatically repeat them, reclaim locks by timer, delete ledger keys or resubmit blindly. Disable/drain the affected flow, inspect run/provider history and stage journals, then make and record an authorized recovery decision. Detailed states and procedures are in the [V1 setup guide](docs/01-orchestrator-setup.md) and [V2 flow design](orchestrator/v2/flow-authoring.md).

## 🗂️ Repository map

| Path | Contents |
| --- | --- |
| [`docs/00-agent-installation-guide.md`](docs/00-agent-installation-guide.md) | Start here: exact installation sequence for the numbered setup and per-agent guides, including return points for flow authoring and acceptance. |
| [`docs/01-orchestrator-setup.md`](docs/01-orchestrator-setup.md) | V1 prerequisites, solution/environment variables, SharePoint ledger, agent and flow authoring, validation, failure handling and tenant acceptance checks. |
| [`docs/03-specialist-setup.md`](docs/03-specialist-setup.md) | V2 authoring, case permissions, specialist setup, knowledge ingestion, V1-compatible migration and acceptance coverage. |
| [`orchestrator/`](orchestrator/) | V1 agent instructions, configuration example, JSON contracts and synthetic fixtures. |
| [`orchestrator/v2/`](orchestrator/v2/) | V2 route map, flow-authoring instructions, case-context/result contracts and configuration example. |
| [`specialists/`](specialists/) | Five agent instruction files, shared instructions, manifest, contracts and synthetic role examples. |
| [`sharepoint/case-management.design.json`](sharepoint/case-management.design.json) | Proposed case list, intake-ledger additions, stage journal and evidence library schema. It is a design, not a provisioning script. |
| [`sharepoint/conditional-update.http`](sharepoint/conditional-update.http) | Exact-ETag SharePoint conditional-update recipe. |
| [`knowledge/`](knowledge/) | Draft EU/EEA reference pack, source/applicability register, unresolved policy decisions and role-to-source manifest. |
| [`customer-templates/`](customer-templates/) | CO-00–CO-08 editable Word drafts, form source and generator. |
| [`scripts/Test-OrchestratorContracts.ps1`](scripts/Test-OrchestratorContracts.ps1) | V1 synthetic contract and failure-shape checks. |
| [`scripts/Test-SpecialistContracts.ps1`](scripts/Test-SpecialistContracts.ps1) | V2 specialist contract, correlation, scope and fail-closed checks. |

## 🧪 Run local checks and generate templates

Local checks require **PowerShell 7.4+** and no additional packages. The document generator requires **Node.js 22.15+** (or a later supported release providing `zlib.crc32`). Run from the repository root:

```powershell
pwsh -NoProfile -File .\scripts\Test-OrchestratorContracts.ps1
pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1
node .\customer-templates\generator\generate.js
```

The generator writes nine `.docx` files to `customer-templates/` by default; an optional output directory can be passed as its argument. Generated Word documents are editable drafts, not protected form controls. Review source and generated output together.

**Local success is not tenant acceptance.** These commands do not provision resources, call Copilot Studio, extract documents, run identity or screening providers, prove permissions/concurrency, or verify legal content. See each setup guide for tenant-specific acceptance cases.

## ⚙️ Tenant setup and controlled deployment

Start with the [build and import guide](docs/09-build-and-import.md) for the six
agent packages, SharePoint provisioning script, and full tenant export procedure.
If you import the agents, use the manual runbooks to verify them rather than
creating duplicates.

Follow [`docs/00-agent-installation-guide.md`](docs/00-agent-installation-guide.md)
in numeric order: 01 infrastructure -> 02 v1 agent -> return to 01 for the v1
flow and acceptance -> 03 v2 prerequisites -> 04 document -> 05 business ->
06 natural person -> 07 financial crime -> 08 risk review -> return to 03
for v2 integration and acceptance. These Markdown files are manual runbooks,
not executable installation scripts. Stop after the v1 acceptance steps for
a v1-only installation.

1. Obtain explicit authorization for a named development tenant/environment. Confirm Power Platform, Copilot Studio and Power Automate capacity, Dataverse/solution permissions, SharePoint access, DLP, region, retention, run-history access and connection ownership.
2. Follow [`docs/01-orchestrator-setup.md`](docs/01-orchestrator-setup.md) to create the unmanaged solution, environment variables, connection references, restricted unique-key ledger, standard-harness intake agent and disabled solution-aware V1 flow. Use synthetic files only during initial testing.
3. Run the local V1 contract checks, then complete the guide's tenant acceptance tests before any separately authorized activation.
4. For V2, follow [`docs/03-specialist-setup.md`](docs/03-specialist-setup.md) and [`orchestrator/v2/flow-authoring.md`](orchestrator/v2/flow-authoring.md). Provision and verify case/evidence/stage lists, ACLs, exact-ETag writes, actor authorization, reviewed subject sets, approved policy/provider bindings and all specialist agents before considering a flow.
5. Generate/export actual Power Platform solution and native agent source from the tenant using supported Microsoft tooling. Keep real environment values, credentials, customer files and sensitive provider/screening data out of this repository. Rebind and re-test in every target environment.

Configuration JSON files are **examples only**; placeholder values are not credentials, and IDs/connection references must be generated and bound in the target environment. Merely adding files to a solution or publishing an agent is not authorization to enable intake.

## 🔐 Security, privacy, and recovery

- Treat uploaded files, filenames, metadata, provider responses, agent drafts and quoted text as untrusted data—not instructions. The flow must independently enforce authorization and contracts; prompts are not a security boundary.
- V1 passes metadata only. V2 may read evidence only after tenant-verified case, folder, ACL and authenticated-actor checks. A service connection's access is not proof that the uploader is authorized.
- Keep sensitive evidence in restricted, versioned storage; lists and agent results should use opaque references and minimal data. Never put credentials or customer data in config examples, Git, general knowledge uploads or error messages.
- No arbitrary web search, URL fetch, REST/MCP tool or downstream agent tool is enabled for the authored agents. Providers, extraction and rule execution require independently approved flow adapters and real versioned reports.
- Knowledge is reference guidance, never case evidence or an override for configured policy. The current pack is draft and must not be production-enabled without Compliance/Legal/DPO approval and country applicability review.
- Customer forms are conditional drafts, not universal document requirements. Bank Compliance, Legal, DPO and Tax must approve selected forms and privacy language before release.
- Define bank-owned access, retention, monitoring, incident response, and human review before tenant activation. Never infer identity, ownership, customer type, scope or a successful check from documents, metadata, model output or missing errors.

## ⚠️ Known limitations

- No complete tenant solution export, tenant configuration or deployed flows are included.
- No real document extraction, identity verification, business registry lookup, sanctions/PEP/adverse-media screening, risk calculation or provider call has been performed.
- Country/EEA/bank-policy overlays and approved provider or policy versions remain unresolved; the knowledge pack and customer forms are drafts.
- Customer upload permissions and portal/secure-sharing experience are not implemented. Until an institution's access model is reviewed and verified, use controlled bank-operator synthetic uploads only.
- There is no exactly-once transaction across SharePoint, Copilot Studio and future providers. Ambiguous outcomes require operator reconciliation.
- A prepared draft or `PendingIntegration` state is not customer onboarding completion, verification, clearance, approval or rejection.
