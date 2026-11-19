# Agent installation guides

These guides describe how to manually create the six Copilot Studio agents in
an authorized Power Platform development environment. The repository is a
source scaffold: it does not contain importable Copilot Studio agent packages,
and no tenant resources are provisioned by following these steps.

## Choose the guide

| Agent | Guide | Invocation path |
| --- | --- | --- |
| Customer Onboarding Intake Orchestrator | [Install the v1 orchestrator](agent-installation-orchestrator.md) | The v1 SharePoint intake flow in [orchestrator setup](orchestrator-setup.md) |
| Onboarding Document Evidence | [Install document evidence](agent-installation-document-evidence.md) | The v2 sequential specialist flow |
| Onboarding Natural Person Verification | [Install natural-person verification](agent-installation-natural-person.md) | The v2 sequential specialist flow |
| Onboarding Business Verification | [Install business verification](agent-installation-business.md) | The v2 sequential specialist flow |
| Onboarding Financial Crime Screening | [Install financial-crime screening](agent-installation-financial-crime.md) | The v2 sequential specialist flow |
| Onboarding Risk Review Preparation | [Install risk-review preparation](agent-installation-risk-review.md) | The v2 sequential specialist flow |

The v1 orchestrator and v2 specialists are separate designs. Do not combine
their triggers or route a v1 event directly into a v2 specialist. The v2 flow,
SharePoint case infrastructure, authorization gates, schemas, and recovery
process are described in [specialist setup](specialist-setup.md) and
[v2 flow authoring](../orchestrator/v2/flow-authoring.md).

## Common prerequisites for the five specialists

Before creating any v2 specialist:

1. Obtain explicit authorization to use a named development Power Platform
   environment. Confirm Copilot Studio access/capacity, solution permissions,
   Dataverse requirements, tenant DLP/data-residency rules, licensing, and
   connection ownership with the tenant administrator.
2. Create or select the unmanaged solution `OnboardingOrchestrator` in that
   environment. Use the organization's approved publisher and prefix; the
   examples use `onb`. Keep all five specialists in this solution.
3. Keep the v2 orchestration flow disabled while authoring. Install the
   SharePoint lists/library, access controls, environment variables, and
   connection references only as specified in
   [specialist setup](specialist-setup.md). Agent creation alone does not
   authorize processing customer data.
4. Create each specialist as a separate **standard-harness** Copilot Studio
   agent using the exact display name in its guide. Do not modify the v1
   orchestrator to serve as a specialist.
5. In **Instructions**, paste the complete contents of
   [`specialists/common-instructions.md`](../specialists/common-instructions.md)
   first, then append exactly the one role file named in that guide. Markdown
   links in those files are source references; they are not automatically
   loaded into the agent.
6. Configure no tools, web search, arbitrary connectors, downstream agents,
   event triggers, document knowledge, or side-effecting actions. The
   Power Automate flow performs authorization, connector calls, persistence,
   and sequencing. The agent only prepares a constrained draft.
7. Leave environment/provider/policy bindings unconfigured until a separately
   approved, implemented, and tested integration exists. A non-null binding
   value is not proof that a provider ran. This scaffold deliberately has no
   configured provider, approved production policy, or released knowledge
   pack.
8. Use the per-guide acceptance checks with synthetic data. Never test with
   customer records or enable production processing as part of authoring.

The instructions and JSON Schemas are not enforcement boundaries. The v2
flow must validate the request before dispatch and independently validate the
single `lastResponse` against
[`specialist-result.schema.json`](../specialists/contracts/specialist-result.schema.json),
including correlation, references, scope, and role-specific semantics.
Disable automatic retries for agent dispatch; an ambiguous outcome requires
reconciliation, not a second invocation.

## Finish and record the installation

1. Save each agent in the solution and record the platform-generated agent ID
   in the corresponding v2 environment variable from
   [`orchestrator/v2/config.example.json`](../orchestrator/v2/config.example.json).
   Do not commit environment-specific IDs, credentials, or customer data.
2. Verify each agent's name, instructions, standard harness, absence of tools
   and triggers, and (if knowledge is authorized) exact mapped knowledge
   sources. Keep the v2 flow disabled.
3. Run the synthetic request for each role individually in the development
   environment. Validate the output against the schema and its role-specific
   acceptance checks; also run
   `pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1` locally.
4. Record the environment, solution version, agent IDs, instruction version,
   knowledge pack version (if any), test evidence, reviewer, and date in the
   organization's deployment record. Do not place secrets or personal data in
   that record or this repository.
5. Only after separate authorization, generate/export native platform source,
   bind target connection references and environment values, repeat acceptance
   tests, and enable the approved flow. The repository files are manual
   authoring inputs, not an export or a deployment.
