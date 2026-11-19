# 06 - Install the Onboarding Natural Person Verification agent

The `natural-person` specialist prepares evidence assessments for the
authorized, human-reviewed subject set. It does not execute identity checks,
merge people, establish legal identity, or make a bank verification decision.
An approved identity-provider adapter and the v2 flow—not this agent—must
perform and preserve any provider operation.

## Prerequisites

Complete the [common specialist prerequisites](00-agent-installation-guide.md#common-prerequisites-for-the-five-specialists)
and [specialist setup](03-specialist-setup.md). Before dispatch, the flow must
confirm the case and upload authorization, approved evidence snapshot, complete
reviewed subject set, case revision, and (for business cases) accepted
ownership/representation review. An uploaded identity document alone is not
identity verification.

## Install

1. In the authorized development environment, open the unmanaged
   `OnboardingOrchestrator` solution and create a separate standard-harness
   Copilot Studio agent named **Onboarding Natural Person Verification**.
2. Paste the complete `specialists/common-instructions.md` first and then the
   complete `specialists/natural-person.md` into **Instructions**. Do not
   append another specialist role file.
3. Add no tools, provider connection, web search, event trigger, downstream
   agent, or document knowledge. The controlled flow supplies authorized
   reports and opaque subject/evidence references; the agent must not contact
   an identity service.
4. Bind the platform-generated agent ID to `onb_PersonAgentId` in the v2
   solution. The corresponding request field is `configuration.identityProvider`.
   Leave it null until an approved provider adapter is operational and its
   normalized evidence is supplied. A configured ID alone does not prove a
   check occurred.
5. Keep knowledge disabled unless the bank formally approves a released pack.
   If authorized, add only `02-kyc-natural-persons.md` and
   `07-document-and-remote-identity-verification.md` through **Knowledge >
   Add knowledge**, complete **Add to agent**, verify readiness, and record the
   pack version. The current pack is draft; do not use it as production policy
   or case evidence.
6. Save in the solution and publish only with explicit authorization for the
   named development environment. Leave the v2 flow disabled.

## Verify and connect

1. Run the `natural-person` synthetic request from
   `specialists/examples/requests.json`. With the null identity-provider
   binding, require `blocked_pending_configuration`, issue
   `identity_provider_not_configured`, and one `not_assessed` entry for every
   requested person, with empty provider-evidence IDs.
2. Use synthetic provider-result fixtures only if an approved test adapter is
   available. Confirm output assessments are limited to the result schema's
   allowed values, match each requested opaque subject exactly, and cite only
   available `approved_provider` evidence for that subject. Do not accept
   “verified” as a model-created outcome.
3. Validate the single JSON result with
   `specialists/contracts/specialist-result.schema.json` and run
   `pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1`.
4. Place the stage after `document-evidence` for an individual. For a business,
   do not dispatch until the business ownership result has been reviewed and
   the authoritative subject set has been committed with an incremented
   `SubjectSetVersion`. Use the flow's unique stage claim, fresh conversation,
   no-retry dispatch, and independent result checks.

The flow must require accepted subject-set review and preserve missing,
conflicting, ambiguous, or failed-provider evidence as a hold. This agent
cannot assert that all required people have been identified.
