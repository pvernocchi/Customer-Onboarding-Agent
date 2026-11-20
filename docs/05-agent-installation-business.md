# 05 - Install the Onboarding Business Verification agent

The `business` specialist prepares registry, ownership, and representation
evidence for a business case. It may propose relationships only among
authorized candidate subject references. It does not create people, verify
ownership completeness, establish authority, or decide the case.

## Prerequisites

Complete the [common specialist prerequisites](00-agent-installation-guide.md#common-prerequisites-for-the-five-specialists)
and [specialist setup](03-specialist-setup.md). Provide only authorized business
case snapshots and evidence. A separately approved registry adapter must
normalize candidate people to protected, case-scoped references. A human must
reconcile the resulting evidence and commit the accepted subject set before
natural-person verification or screening can proceed.

## Prepare the agent

1. In the authorized development environment, create a separate standard-harness
   **Onboarding Business Verification** agent, or verify an existing tenant agent
   before reuse. Add it to the unmanaged
   `OnboardingOrchestrator` solution if needed.
2. Paste into **Instructions** the complete
   `specialists/common-instructions.md` followed by `specialists/business.md`
   in that order. Do not add other role files.
3. Add no registry/provider tool, web search, arbitrary endpoint, event
   trigger, downstream agent, or case-write permission. Only the control plane may
   invoke the approved registry integration or persist state.
4. Bind the platform-generated agent ID to `onb_BusinessAgentId`. Its required
   configuration field is `businessProvider`; leave it null unless a separately
   approved business-provider adapter is implemented, authorized, and tested.
5. Keep knowledge disabled until the
   [bank's knowledge release gates](03-specialist-setup.md#knowledge-ingestion-and-updates)
   are met. If authorized, add only
   `03-kyb-legal-entities-and-beneficial-ownership.md` through **Knowledge >
   Add knowledge**, choose **Add to agent**, verify readiness, and record the
   pack version. The current content is draft and does not set country rules,
   ownership thresholds, or bank policy.
6. Save the agent in the solution. Publish only with explicit authorization
   for the named development environment; keep V2 disabled.

## Verify standalone behavior

1. Run the `business` synthetic request from
   `specialists/examples/requests.json`. With the null binding, require
   `blocked_pending_configuration`, issue `business_provider_not_configured`,
   `registryAssessment: not_assessed`,
   `ownershipDiscovery: not_assessed`, and `relatedPeople: []`.
2. For an approved synthetic adapter test, check that the case type is
   `business`, all proposed people already exist in `subjects`, each relationship
   cites existing evidence, and unresolved ownership/authority remains
   incomplete or requires review. Reject invented people and claims of a
   complete ownership chain.
3. Validate one JSON result with
   `specialists/contracts/specialist-result.schema.json` and run
   `pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1`.
## Required V2 gate

On the business route this native handover follows document evidence. The
control plane must stop person and screening stages on unreviewed or incomplete
ownership. After authorized human reconciliation, commit the reviewed subject
snapshot and increment its version before continuing.

The business agent's `relatedPeople` is a proposal, not the authoritative
subject set. Never silently remove unresolved people to
make the next stage pass. See [the v2 business route](../orchestrator/v2/routes.json)
and [native handovers and required controls](../orchestrator/v2/connected-agent-handover.md).
