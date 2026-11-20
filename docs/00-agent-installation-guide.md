# 00 - Installation order and agent guides

## Prepare agents manually

Create each required standard-harness agent once using 02 and 04–08. If the
named agent already exists in the tenant, verify its instructions and settings
before reusing or updating it; do not create a duplicate.

Manual authoring requires tenant configuration and verification. For a V1-only
setup, prepare just the intake orchestrator and stop after V1 acceptance.

## Exact installation order

The two-digit filename prefixes define the recommended installation order.
These Markdown files are manual instructions, **not executable scripts**:
follow their steps in Copilot Studio, Power Automate, and SharePoint. Run only
the commands explicitly shown in the guides, from the repository root.

| Order | File | Action and completion gate |
| --- | --- | --- |
| 00 | [Installation index](00-agent-installation-guide.md) | Read this sequence and the common prerequisites below. |
| 01 | [V1 infrastructure and setup](01-orchestrator-setup.md) | Complete prerequisites/configuration and the durable ledger. Stop before creating the agent; keep the flow off. |
| 02 | [V1 orchestrator installation](02-agent-installation-orchestrator.md) | Create or verify the intake agent, then test it and return to 01 for the disabled V1 flow and acceptance checks. |
| 03 | [V2 infrastructure and setup](03-specialist-setup.md) | Read the v2 boundaries and migration plan; provision SharePoint, permissions, environment variables, and connection references before authoring specialists. |
| 04 | [Document evidence installation](04-agent-installation-document-evidence.md) | Prepare and test the document specialist. |
| 05 | [Business verification installation](05-agent-installation-business.md) | Prepare and test the business specialist, required for the business path. |
| 06 | [Natural-person installation](06-agent-installation-natural-person.md) | Prepare and test the person specialist. |
| 07 | [Financial-crime installation](07-agent-installation-financial-crime.md) | Prepare and test the screening specialist. |
| 08 | [Risk-review installation](08-agent-installation-risk-review.md) | Prepare and test the final review-pack specialist. |

After 08, return to **03** for knowledge governance, V1-compatible migration
planning, and acceptance criteria. The V2 target is a Copilot Studio
orchestrator directing [native connected-agent handovers](../orchestrator/v2/connected-agent-handover.md).
Do not build the old direct flow dispatcher. V2 must stay disabled: neither
native links nor a deterministic control plane that gates every call and
result have been implemented or verified. Any isolated link testing requires
separate authorization and synthetic inputs. Never enable both creation-trigger
paths for the same intake.

For an existing v1 installation, verify 01 and 02 are already satisfied, then
start the v2 extension at 03; do not recreate or overwrite existing resources.
The intended individual route does not call the business specialist; include
it when preparing the complete six-agent scaffold.

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

| Agent | Guide | Intended invocation path |
| --- | --- | --- |
| Customer Onboarding Intake Orchestrator | [Install the V1 orchestrator](02-agent-installation-orchestrator.md) | [V1 SharePoint intake flow](01-orchestrator-setup.md); V2 would also start with SharePoint intake to the orchestrator |
| Onboarding Document Evidence | [Install document evidence](04-agent-installation-document-evidence.md) | V2 native handover from the orchestrator |
| Onboarding Business Verification | [Install business verification](05-agent-installation-business.md) | V2 native handover from the orchestrator |
| Onboarding Natural Person Verification | [Install natural-person verification](06-agent-installation-natural-person.md) | V2 native handover from the orchestrator |
| Onboarding Financial Crime Screening | [Install financial-crime screening](07-agent-installation-financial-crime.md) | V2 native handover from the orchestrator |
| Onboarding Risk Review Preparation | [Install risk-review preparation](08-agent-installation-risk-review.md) | V2 native handover from the orchestrator |

Keep the V1 metadata-only contract unchanged. Do not route a V1 event directly
to a V2 specialist or add specialist triggers. See [specialist setup](03-specialist-setup.md)
for the case infrastructure, contracts, governance, and migration requirements.

## Common prerequisites for the five specialists

Before preparing any V2 specialist:

1. Obtain explicit authorization to use a named development Power Platform
   environment. Confirm Copilot Studio access/capacity, solution permissions,
   Dataverse requirements, tenant DLP/data-residency rules, licensing, and
   connection ownership with the tenant administrator.
2. Create or select the unmanaged solution `OnboardingOrchestrator` in that
   environment. Use the organization's approved publisher and prefix; the
   examples use `onb`. Keep all five specialists in this solution.
3. Keep V2 intake and processing disabled while authoring. Provision the
   SharePoint lists/library, access controls, environment variables, and
   connection references only as specified in
   [specialist setup](03-specialist-setup.md). Agent creation alone does not
   authorize processing customer data.
4. Create a separate **standard-harness** Copilot Studio agent with the exact
   display name in its guide, or verify an existing tenant agent before reuse.
   The intake orchestrator is not a specialist.
5. Paste the complete contents of
   [`specialists/common-instructions.md`](../specialists/common-instructions.md)
   first, then append exactly the one role file named in that guide. Markdown
   links in those files are source references; they are not automatically
   loaded into the agent.
6. Configure no tools, web search, arbitrary connectors, downstream agents,
   event triggers, customer document knowledge, or side-effecting actions. The
   independent control plane must enforce authorization, connector calls,
   persistence and stage gates. The orchestrator is instructed to sequence
   native connected-agent calls; that sequence is not deterministically enforced.
7. Leave environment/provider/policy bindings unconfigured until a separately
   approved, implemented, and tested integration exists. A non-null binding
   value is not proof that a provider ran. This scaffold deliberately has no
   configured provider, approved production policy, or released knowledge
   pack.
8. Use the per-guide acceptance checks with synthetic data. Never test with
   customer records or enable production processing as part of authoring.

The instructions and JSON Schemas are not enforcement boundaries. The required
independent control plane must validate the request before dispatch and validate
the connected-agent result against
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
   sources. Keep V2 disabled.
3. Run the synthetic request for each role individually in the development
   environment. Validate the output against the schema and its role-specific
   acceptance checks; also run
   `pwsh -NoProfile -File .\scripts\Test-SpecialistContracts.ps1` locally.
4. Record the environment, solution version, agent IDs, instruction version,
   knowledge pack version (if any), test evidence, reviewer, and date in the
   organization's deployment record. Do not place secrets or personal data in
   that record or this repository.
5. With separate authorization, export native platform source, rebind target
   values and repeat synthetic verification. Export or publication does not
   authorize activation. V2 remains blocked pending independently enforced
   per-call controls, tenant acceptance, and bank approval.
