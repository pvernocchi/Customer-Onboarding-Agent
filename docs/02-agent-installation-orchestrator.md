# 02 - Install the Customer Onboarding Intake Orchestrator

This guide installs the single v1 Copilot Studio intake orchestrator. It
receives a normalized SharePoint file-metadata event and returns a fixed
`pending_integration` assessment. It has no document reader, case registry,
specialist dispatch, provider, notification, persistence, or approval tool.
The flow—not the agent—owns durable intake, validation, deduplication, and
error handling.

## Prerequisites

- An explicitly authorized Power Platform development environment, Copilot
  Studio access/capacity, and permission to add an agent to the unmanaged
  `OnboardingOrchestrator` solution.
- Tenant-approved publisher/prefix, environment and connection references.
- Synthetic-only SharePoint test input and the v1 contracts/fixtures in
  `orchestrator/contracts/` and `orchestrator/examples/`.
- Review of [the complete v1 setup guide](01-orchestrator-setup.md). That guide
  contains the required durable ledger, flow configuration, failure handling,
  environment variables, migration boundaries, and tenant acceptance plan.

The repository is source scaffolding; it does not create an agent, flow,
SharePoint list, connection, or solution archive. Keep the flow disabled while
installing and testing.

## Create and configure the agent

1. In Power Apps or Power Automate, open **Solutions** in the authorized
   development environment. Create or select the unmanaged solution
   `OnboardingOrchestrator`, using the organization's approved publisher.
2. In Copilot Studio, select that same environment and create a **standard
   harness** agent named **Customer Onboarding Intake Orchestrator**. Add the
   agent to the solution.
3. Open `orchestrator/agent-instructions.md` in the repository. Copy its
   entire contents, including the trust boundary and exact JSON response, into
   the agent's **Instructions**. Do not replace the response example with
   prose or add alternate success responses.
4. Use generative orchestration only if required by the selected standard
   agent experience. Do not add a native event trigger. The configured
   Power Automate flow is the only intake entry point for this v1 design.
5. Add no knowledge source, uploaded document, web-search capability, tool,
   connector, downstream agent, or side-effecting action. Disable or remove
   default topics and general-knowledge behavior that could add a greeting,
   fallback, sign-in prompt, or follow-up to a valid intake response.
6. Create the v1 text environment variables listed in
   `orchestrator/config.example.json`; bind the platform-generated agent ID
   to `onb_AgentId`. Use real environment values only in the tenant. Do not
   store IDs or credentials in the example file.
7. Save the agent. Publish it only when the environment owner explicitly
   authorizes publication for the named development environment and connector
   invocation. Do not disable authentication or expose an anonymous channel
   as a workaround.

## Verify the agent

1. Use the synthetic valid event fixture as one JSON message. Require exactly
   one JSON object with the input `eventId` copied exactly and every other
   response field fixed as specified by `agent-instructions.md`.
2. Confirm there is no Markdown fence, greeting, second response, invented
   customer/case ID, approval claim, or statement that document content was
   read.
3. Send malformed input and a normal chat message. Confirm the agent returns
   the specified invalid-input result and does not turn either into a valid
   orchestration result.
4. Run `pwsh -NoProfile -File .\scripts\Test-OrchestratorContracts.ps1`.
   This local check does not exercise Copilot Studio or prove prompt-injection
   resistance.
5. Follow [orchestrator setup](01-orchestrator-setup.md) to create and test the
   durable ledger and Power Automate flow. The flow must parse and validate the
   actual response, disable automatic retries, and persist failures explicitly.
   Do not interpret `pending_integration` as completed onboarding.

## Record and deployment boundary

Record the platform-generated Agent ID and named environment in the deployment
record, then keep the agent and flow disabled until authorized end-to-end
acceptance. This v1 orchestrator is not the v2 specialist controller; see
[specialist setup](03-specialist-setup.md) before any separately authorized v2
migration. Native source must be generated and validated by the platform; do
not rename the Markdown instruction file to a Copilot Studio YAML file.
