# Install the Onboarding Business Verification agent

The `business` specialist prepares registry, ownership, and representation
evidence for a business case. It may propose relationships only among
flow-supplied candidate subject references. It does not create people, verify
ownership completeness, establish authority, or decide the case.

## Prerequisites

Complete the [common specialist prerequisites](agent-installation-guide.md#common-prerequisites-for-the-five-specialists)
and [specialist setup](specialist-setup.md). Provide only authorized business
case snapshots and evidence. A separately approved registry adapter must
normalize candidate people to protected, case-scoped references. A human must
reconcile the resulting evidence and commit the accepted subject set before
natural-person verification or screening can proceed.

## Install

1. In the authorized development environment, open the unmanaged
   `OnboardingOrchestrator` solution and create a separate standard-harness
   Copilot Studio agent named **Onboarding Business Verification**.
2. Paste the complete `specialists/common-instructions.md` first and then the
   complete `specialists/business.md` into **Instructions**. Do not add the
   other specialist role files.
3. Add no registry/provider tool, web search, arbitrary endpoint, event
   trigger, downstream agent, or case-write permission. Only the v2 flow may
   invoke the approved registry integration or persist state.
4. Bind the platform-generated agent ID to `onb_BusinessAgentId`. Its required
   configuration field is `businessProvider`; leave it null unless a separately
   approved business-provider adapter is implemented, authorized, and tested.
5. Keep knowledge disabled unless the bank approves and releases a knowledge
   pack. If authorized, add only
   `03-kyb-legal-entities-and-beneficial-ownership.md` through **Knowledge >
   Add knowledge**, choose **Add to agent**, verify readiness, and record the
   pack version. The current content is draft and does not set country rules,
   ownership thresholds, or bank policy.
6. Save the agent in the solution. Publish only with explicit authorization
   for the named development environment; keep the v2 flow disabled.

## Verify and connect

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
4. In the business route, invoke this stage after document evidence. A
   non-human-reviewed or incomplete ownership result must stop the person and
   screening stages. After authorized human reconciliation, commit the reviewed
   subject snapshot and increment its version before continuing.

The business agent's `relatedPeople` is a proposal, not the authoritative
subject set. Never let a model or flow silently remove unresolved people to
make the next stage pass. See [the v2 business route](../orchestrator/v2/routes.json)
and [the full flow gates](../orchestrator/v2/flow-authoring.md).
