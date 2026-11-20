# 04 - Install the Onboarding Document Evidence agent

The `document-evidence` specialist classifies authorized, versioned document
excerpts and proposes source-located **unverified** claims. It does not read
files, extract text, authenticate documents, verify identity, or make decisions.
The independent V2 control plane must supply the authorized evidence snapshot
from a separately approved extraction integration.

## Prerequisites

Complete the [common specialist prerequisites](00-agent-installation-guide.md#common-prerequisites-for-the-five-specialists)
and the infrastructure/authorization setup in
[specialist setup](03-specialist-setup.md). In particular, do not treat the
SharePoint properties-only trigger as document content. Until a real,
approved extractor and authorization boundary are implemented, the provider
binding remains null and the agent must return a blocked result.

## Prepare the agent

1. In the authorized development environment, open the imported **Onboarding
   Document Evidence** agent; do not recreate it. On the manual path, create
   one separate standard-harness agent with that name. Add it to the unmanaged
   `OnboardingOrchestrator` solution if needed.
2. Open `specialists/common-instructions.md` and
   `specialists/document-evidence.md`. Verify imported **Instructions** against
   the full common instructions followed by the full role file, or paste them
   in that order for manual creation. Do not add the other role files.
3. Use no tools, event triggers, web search, downstream agents, document
   uploads, or direct file/SharePoint access. In particular, do not grant the
   agent the extractor's credentials. The control plane must supply only the authorized
   snapshot and excerpt.
4. Create/bind the v2 environment variable `onb_DocumentAgentId` to this
   platform-generated agent ID. The corresponding configuration binding is
   `documentExtractor`; keep that binding null unless an approved extractor is
   actually deployed and the control plane validates its output.
5. Keep repository knowledge disabled until the
   [bank's knowledge release gates](03-specialist-setup.md#knowledge-ingestion-and-updates)
   are met. If authorized,
   add only `04-required-intake-documents.md` and
   `07-document-and-remote-identity-verification.md` through **Knowledge >
   Add knowledge**; finish **Add to agent**, verify readiness, and record the
   released pack version. These documents are currently draft and must not be
   uploaded for production use.
6. Save the agent in the solution. Publish only under explicit authorization
   for the named development environment. Keep V2 disabled.

## Verify standalone behavior

1. Use the `document-evidence` request in
   `specialists/examples/requests.json` as a synthetic input. With the provided
   null extractor configuration/unavailable content, require the blocked
   response shown in `specialists/examples/results.json`: `unclassified`,
   `formCode: null`, and an empty `extractions` array.
2. When testing with synthetic available content in a separately approved
   extractor integration, verify each extraction uses an allowed field,
   existing evidence ID and `sourceRecordRef`, and an exact locator emitted by
   that extractor. Every assessment remains
   `unverified_document_claim`; never accept raw personal values or invented
   references.
3. Validate one JSON response against
   `specialists/contracts/specialist-result.schema.json`; then run
   `pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1`.
## Required V2 gate

This is the first native handover for both routes. The control plane must
reserve and journal the operation before calling, then independently validate
correlation, role, evidence references, locators, and semantics before advancing.

No uploaded file is an identity verification or proof of authenticity, and a
useful extraction is a draft only. See [v2 route gates](../orchestrator/v2/routes.json)
and [native handovers and required controls](../orchestrator/v2/connected-agent-handover.md).
