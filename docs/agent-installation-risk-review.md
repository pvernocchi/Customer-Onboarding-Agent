# Install the Onboarding Risk Review Preparation agent

The `risk-review` specialist prepares a traceable review pack from an immutable
assessment snapshot and approved, deterministic rule outputs. It does not
author policy, calculate risk bands, assign scores, or approve/reject an
account. The final decision remains a separate human-only process.

## Prerequisites

Complete the [common specialist prerequisites](agent-installation-guide.md#common-prerequisites-for-the-five-specialists)
and [specialist setup](specialist-setup.md). Before this agent is installed
into an active route, the bank must have separately approved policy and
country-rule versions, a deterministic rule integration, and a flow that
preserves every upstream gap/hold. The repository's knowledge pack and policy
bindings are draft/unconfigured; null configuration must fail closed.

## Install

1. In the authorized development environment, open the unmanaged
   `OnboardingOrchestrator` solution and create a separate standard-harness
   Copilot Studio agent named **Onboarding Risk Review Preparation**.
2. Paste the complete `specialists/common-instructions.md` followed by the
   complete `specialists/risk-review.md` into **Instructions**.
3. Add no policy-rule tool, web search, event trigger, decision/approval topic,
   downstream agent, or case-write permission. The flow supplies the approved
   rule report and versioned assessment snapshot.
4. Bind the platform-generated ID to `onb_ReviewAgentId`. Leave
   `configuration.policyRules`, `policyVersion`, and `countryRulesVersion`
   null until the bank's approved rule integration and applicable jurisdiction
   versions are configured and verified. Do not fill these from uploaded
   documents, model output, or draft knowledge.
5. Keep knowledge disabled unless the bank formally approves a release. If
   authorized, add only `01-regulatory-framework-eu.md`,
   `05-aml-risk-assessment.md`, and `08-human-review-and-escalation.md`
   through **Knowledge > Add knowledge**, choose **Add to agent**, verify
   readiness, and record the approved pack version. The current files are
   draft reference material, not executable policy.
6. Save in the solution. Publish only after explicit authorization for the
   named development environment, and keep the v2 flow disabled.

## Verify and connect

1. Run the `risk-review` synthetic request from
   `specialists/examples/requests.json`. With null bindings/versions, require
   `blocked_pending_configuration`, the corresponding configuration/version
   issues, `readiness: blocked`, an empty `ruleFindings` array,
   `riskRating: null`, and `finalDecision: human_only_not_made`.
2. In an approved synthetic rule-report test, verify that each output rule
   finding exactly matches the authoritative supplied rule ID, policy version,
   finding code, and evidence references. Confirm the full supplied finding
   list and all upstream gaps/holds are preserved. No new finding or rating
   may be model-generated.
3. Validate the single JSON result with
   `specialists/contracts/specialist-result.schema.json` and run
   `pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1`.
4. Route this stage last for both individual and business paths, after every
   required specialist, human ownership review when applicable, and approved
   rule evaluation. Use the flow's claimed operation, fresh conversation,
   no-retry dispatch, snapshot/correlation checks, and human-only disposition.

`ready_for_human_review` is not a favorable outcome or approval. Keep the final
decision outside this agent and preserve all holds, possible matches, and
incomplete upstream work for the authorized reviewer.
