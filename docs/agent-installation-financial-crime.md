# Install the Onboarding Financial Crime Screening agent

The `financial-crime` specialist summarizes approved-source reports for every
in-scope business and person in the reviewed case subject snapshot. It does not
perform screening, query external sources, determine source sufficiency, clear
hits, or make a compliance decision. Screening is performed by a separately
approved integration controlled by the v2 flow.

## Prerequisites

Complete the [common specialist prerequisites](agent-installation-guide.md#common-prerequisites-for-the-five-specialists)
and [specialist setup](specialist-setup.md). The flow must provide an accepted,
complete subject set and actual versioned provider evidence. For business
cases this includes the business and all in-scope related people after human
ownership review. Missing coverage or unresolved identities must remain
visible and block a complete screening pack.

## Install

1. In the authorized development environment, open the unmanaged
   `OnboardingOrchestrator` solution and create a separate standard-harness
   Copilot Studio agent named **Onboarding Financial Crime Screening**.
2. Paste the full `specialists/common-instructions.md` followed by the full
   `specialists/financial-crime.md` into **Instructions**.
3. Do not add a screening tool, web search, data broker, event trigger,
   downstream agent, or direct provider credentials. The approved flow
   integration supplies normalized reports; the agent only summarizes them.
4. Bind the generated agent ID to `onb_ScreeningAgentId`. The request's
   `configuration.screeningProvider` must remain null until the approved
   provider adapter and lawful source/region coverage are implemented,
   authorized, and tested.
5. Keep knowledge disabled unless Compliance/Legal formally approves a release.
   If authorized, add only
   `06-sanctions-pep-adverse-media-screening.md` through **Knowledge >
   Add knowledge**, select **Add to agent**, verify readiness, and record the
   released version. The draft file is not a live screening dataset or policy.
6. Save the agent in the solution and publish only with explicit authorization
   for the named development environment. Do not enable the flow yet.

## Verify and connect

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
4. Route this stage only after human-reviewed subject scope and required
   identity evidence. For businesses, require accepted ownership reconciliation.
   Claim the stage before dispatch, use a fresh conversation and no automatic
   retry, validate every evidence-to-subject mapping, and route any hit,
   provider error, or incomplete coverage to human review.

There is no “clear” or “passed” outcome in this agent's contract. A provider
no-match report still requires review and cannot by itself approve onboarding.
