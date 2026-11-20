# 07 - Install the Onboarding Financial Crime Screening agent

The `financial-crime` specialist summarizes approved-source reports for every
in-scope business and person in the reviewed case subject snapshot. It does not
perform screening, query external sources, determine source sufficiency, clear
hits, or make a compliance decision. Screening would require a separately
approved integration governed by the independent control plane.

## Prerequisites

Complete the [common specialist prerequisites](00-agent-installation-guide.md#common-prerequisites-for-the-five-specialists)
and [specialist setup](03-specialist-setup.md). The control plane must provide an accepted,
complete subject set and actual versioned provider evidence. For business
cases this includes the business and all in-scope related people after human
ownership review. Missing coverage or unresolved identities must remain
visible and block a complete screening pack.

## Prepare the agent

1. In the authorized development environment, open the imported **Onboarding
   Financial Crime Screening** agent; do not recreate it. On the manual path,
   create one separate standard-harness agent with that name. Add it to the
   unmanaged `OnboardingOrchestrator` solution if needed.
2. Verify imported **Instructions** against the complete
   `specialists/common-instructions.md` followed by `specialists/financial-crime.md`,
   or paste them in that order for manual creation.
3. Do not add a screening tool, web search, data broker, event trigger,
   downstream agent, or direct provider credentials. The approved integration
   must supply normalized reports; the agent only summarizes them.
4. Bind the generated agent ID to `onb_ScreeningAgentId`. The request's
   `configuration.screeningProvider` must remain null until the approved
   provider adapter and lawful source/region coverage are implemented,
   authorized, and tested.
5. Keep knowledge disabled until the
   [bank's knowledge release gates](03-specialist-setup.md#knowledge-ingestion-and-updates)
   are met.
   If authorized, add only
   `06-sanctions-pep-adverse-media-screening.md` through **Knowledge >
   Add knowledge**, select **Add to agent**, verify readiness, and record the
   released version. The draft file is not a live screening dataset or policy.
6. Save the agent in the solution and publish only with explicit authorization
   for the named development environment. Keep V2 disabled.

## Verify standalone behavior

1. Run the `financial-crime` synthetic request in
   `specialists/examples/requests.json`. With null provider configuration,
   require `blocked_pending_configuration`, issue
   `screening_provider_not_configured`, and one `not_screened` assessment with
   no provider evidence for every subject in the request.
2. In an approved synthetic provider test, require exact preservation of each
   supplied report state: `possible_match`, `no_match_reported`,
   `inconclusive`, or `provider_error`. Confirm every requested subject remains
   represented, including business-related people. A possible match must never
   be downgraded or omitted.
3. Validate the one JSON response against
   `specialists/contracts/specialist-result.schema.json`; run
   `pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1`.
## Required V2 gate

The [independent control plane](../orchestrator/v2/connected-agent-handover.md#independent-control-plane-required)
must allow this native handover only after human-reviewed subject scope and
required identity evidence, plus accepted ownership reconciliation for
businesses. Validate every evidence-to-subject mapping and route any hit,
provider error or incomplete coverage to human review.

There is no “clear” or “passed” outcome in this agent's contract. A provider
no-match report still requires review and cannot by itself approve onboarding.
