# 00 - Installation order and agent guides

These guides describe manual authoring in an authorized Power Platform
development environment. For the optional agent-only PAC build, SharePoint
provisioning script, and solution export/import, see
[09 - Build and import packages](09-build-and-import.md). If you import an
agent package, verify it in the corresponding guide instead of creating it
again. No tenant deployment or import has been tested from this repository.

## Exact installation order

The two-digit filename prefixes define the recommended installation order.
These Markdown files are manual instructions, **not executable scripts**:
follow their steps in Copilot Studio, Power Automate, and SharePoint. Run only
the commands explicitly shown in the guides, from the repository root.

| Order | File | Action and completion gate |
| --- | --- | --- |
| 00 | [Installation index](00-agent-installation-guide.md) | Read this sequence and the common prerequisites below. |
| 01 | [V1 infrastructure and setup](01-orchestrator-setup.md) | Complete prerequisites/configuration and the durable ledger. Stop before creating the agent; keep the flow off. |
| 02 | [V1 orchestrator installation](02-agent-installation-orchestrator.md) | Create and test the intake agent, then return to 01 to build the disabled flow and complete its acceptance checks. Stop here for a v1-only installation. |
| 03 | [V2 infrastructure and setup](03-specialist-setup.md) | Read the v2 boundaries and migration plan; provision SharePoint, permissions, environment variables, and connection references before authoring specialists. |
| 04 | [Document evidence installation](04-agent-installation-document-evidence.md) | Create, bind, and test the document specialist. |
| 05 | [Business verification installation](05-agent-installation-business.md) | Create, bind, and test the business specialist. Required for the complete solution's business path. |
| 06 | [Natural-person installation](06-agent-installation-natural-person.md) | Create, bind, and test the person specialist. |
| 07 | [Financial-crime installation](07-agent-installation-financial-crime.md) | Create, bind, and test the screening specialist. |
| 08 | [Risk-review installation](08-agent-installation-risk-review.md) | Create, bind, and test the final review-pack specialist. |

After 08, return to **03** for knowledge governance, v1-compatible migration,
and validation/native-artifact steps. Follow
[v2 flow authoring](../orchestrator/v2/flow-authoring.md) sections 1 through 7
to build the disabled controller, then run the local checks below and complete
the tenant acceptance matrix in 03. Publish, export/import, or activate only
under separate authorization. Never enable both creation-trigger paths for
the same intake.

For an existing v1 installation, verify 01 and 02 are already satisfied, then
start the v2 extension at 03; do not recreate or overwrite existing resources.
For an authorized individual-only route, 05 is not dispatched at runtime;
install it as well when deploying the complete six-agent solution.

Installation order is not permission to bypass runtime gates. The individual
runtime route is document evidence -> reviewed person set -> natural person ->
financial crime -> risk review. The business route inserts business evidence
and **human-reconciled ownership/subject-set acceptance** before natural
person. Creating agent 05 does not satisfy that human gate.

Run these checks in this order after authoring (PowerShell 7.4+ required):

```powershell
pwsh -NoProfile -File .\scripts\Test-OrchestratorContracts.ps1
pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1
```

They validate local contracts, not installation or tenant acceptance. Provider
bindings and policy versions remain null until real approved integrations
exist; the baseline specialist examples must remain blocked.

## Agent reference

| Agent | Guide | Invocation path |
| --- | --- | --- |
| Customer Onboarding Intake Orchestrator | [Install the v1 orchestrator](02-agent-installation-orchestrator.md) | The v1 SharePoint intake flow in [orchestrator setup](01-orchestrator-setup.md) |
| Onboarding Document Evidence | [Install document evidence](04-agent-installation-document-evidence.md) | The v2 sequential specialist flow |
| Onboarding Business Verification | [Install business verification](05-agent-installation-business.md) | The v2 sequential specialist flow |
| Onboarding Natural Person Verification | [Install natural-person verification](06-agent-installation-natural-person.md) | The v2 sequential specialist flow |
| Onboarding Financial Crime Screening | [Install financial-crime screening](07-agent-installation-financial-crime.md) | The v2 sequential specialist flow |
| Onboarding Risk Review Preparation | [Install risk-review preparation](08-agent-installation-risk-review.md) | The v2 sequential specialist flow |

The v1 orchestrator and v2 specialists are separate designs. Do not combine
their triggers or route a v1 event directly into a v2 specialist. The v2 flow,
SharePoint case infrastructure, authorization gates, schemas, and recovery
process are described in [specialist setup](03-specialist-setup.md) and
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
   [specialist setup](03-specialist-setup.md). Agent creation alone does not
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
