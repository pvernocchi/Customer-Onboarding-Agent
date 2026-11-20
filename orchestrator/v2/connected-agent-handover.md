# Native connected-agent handovers

## Status and safety boundary

The six solution ZIPs package one main agent and five standalone
specialists. **They do not contain connected-agent links.** The specialists'
packaged `isAgentConnectable` is true; the orchestrator's is false. No
environment was accessed, no connections were created, and no agent was
published. The sanitized native export needed to validate a connected-agent
solution has not been supplied.

The orchestrator's instructions specify role inputs and the individual and
business routes in [routes.json](routes.json). Its choice and order of calls
are model-directed, not an enforced Power Automate state machine. A model can
skip gates, rephrase a request, duplicate a call, emit extra text, exceed a
payload limit, or mishandle the returned result. A prompt cannot provide
authorization, locks, transactional writes, exactly-once execution, reliable
per-call validation, provider execution, or human approval.

The SharePoint new-file trigger is the intended intake entry point and calls
only the orchestrator, not the specialists. V1 continues to use its unchanged
[metadata-only baseline](../../docs/01-orchestrator-setup.md). Keep V2 disabled:
no connected-agent interposition mechanism is implemented or tenant-verified.

## Independent control plane required

1. Before content or provider access, durably claim the event, authenticate
   and authorize the actor against case, scope and folder permissions, lock
   the case with exact ETags, and freeze versioned evidence, subject and
   policy snapshots. Use approved adapters only and fail closed for missing
   bindings, stale snapshots, or absent authorization.
2. Before **each** native handover, enforce the route and human gates in
   [routes.json](routes.json), validate the exact request, and confirm a
   unique owned stage reservation with an immutable request and recorded
   dispatch intent. Prevent calls that bypass these checks. In particular,
   accepted human ownership reconciliation and a committed, versioned subject
   set are required before person or screening work on the business path.
3. Before allowing the **next** handover, validate the actual result's schema,
   operation/case/role/version correlation, evidence-to-subject mappings, and
   role semantics. Persist the result and all holds durably and conditionally;
   preserve screening coverage, possible matches, and provider errors.
   Aggregate independently of the model, release only owned reservations,
   and leave final decisions to authorized humans.
4. Do not automatically retry uncertain dispatches or writes or take over
   stale locks by timer. Stop and drain affected runs; reconcile journal,
   provider and run history before recording an authorized recovery decision.
   Resume against the existing event key; preserve the original history.

The [historical flow-controller design](flow-authoring.md) preserves these
control, idempotency and recovery details. It is not a build guide: its direct
flow-to-specialist calls and connector response handling do not apply to
native handovers. If the platform cannot enforce controls around each call
and result, keep V2 disabled and redesign with a deterministic dispatcher.

## Configure links in an explicitly authorized development environment

Only a maker with explicit authorization may do the following as an isolated
synthetic evaluation. Keep intake triggers off, use no live provider bindings,
and do not modify an active V1 agent or flow. Prepare all six agents in the
same development environment using the [import or manual path](../../docs/00-agent-installation-guide.md#choose-one-agent-preparation-path),
not both. For each of the
five specialist agents, open **Settings** and check **Let other agents connect
to and use this one**. Publish each specialist for this development test and
ensure the maker owns it or has access; depending on authentication, the
orchestrator's users may also need access. Publication for development is
not approval to expose a production channel.

Open the intake orchestrator's **Agents** page. Select **Add** beside **Add an
agent**, choose the existing Copilot Studio agent, and repeat once for each row.
Set the connection's local description to the value in `routingDescription` in
[`specialists/agents.json`](../../specialists/agents.json). Clear **Pass
conversation history to this agent**; pass only the authorized task context.
On the orchestrator's **Overview** instructions use `/` to select and
reference each of the five connected agents at its corresponding handover;
plain display names in the packaged text are not platform references. Save,
verify all five connections, then separately publish the orchestrator only if
authorized for synthetic development testing.

| Specialist | Agent schema | Handover |
| --- | --- | --- |
| Onboarding Document Evidence | `onb_DocumentEvidence` | Versioned document evidence; documentEvidenceId |
| Onboarding Business Verification | `onb_BusinessVerification` | Business, ownership, representation; businessSubjectRef |
| Onboarding Natural Person Verification | `onb_NaturalPerson` | Reviewed people; personSubjectRefs |
| Onboarding Financial Crime Screening | `onb_FinancialCrime` | All reviewed subjects and screeningReports |
| Onboarding Risk Review Preparation | `onb_RiskReview` | assessmentSnapshotRef and approvedRuleFindings or explicit gaps |

Use the [request](../../specialists/contracts/specialist-request.schema.json)
and [result](../../specialists/contracts/specialist-result.schema.json)
contracts and [synthetic examples](../../specialists/examples/requests.json).
Copilot Studio may rephrase tasks or discard ungrounded replies; test exact
payload and result preservation and fail closed on missing, changed or invalid
data. Do not enable general knowledge merely to make a test pass. Successful
link tests do not prove exact forwarding or enforceable per-call guards. Keep
V2 intake disabled until those controls, tenant acceptance, and bank approval
are in place.

For packaging, place the six agents and their created components into one
unmanaged solution, use **Add required objects** on each agent and flow, export
from the development environment, and inspect its contents and dependencies.
Microsoft documents solution export for agents but does not guarantee every
separately stored component transfers. Re-import into another isolated
environment and verify all five links, descriptions, settings, dependencies,
and `/` references. Repeat binding where needed; never assume the ZIPs or
export encode working references. Connected agents are independently managed
and published, unlike child agents owned by the main agent. The model supports
only one connected-agent delegation level: the specialists must not delegate
to another connected agent.

References: [Connect an existing Copilot Studio agent](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-copilot-studio-agent),
[multi-agent overview and limitations](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-add-other-agents),
[connected-agent delegation limitation](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agents-experience/authoring-add-other-agents),
and [solution export and import](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-solutions-import-export).
