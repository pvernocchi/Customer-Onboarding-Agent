# Native connected-agent handovers

## Status and safety boundary

The six solution ZIPs contain one main agent and five separately deployed
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

The SharePoint new-file trigger remains the sole intake entry point and calls
the orchestrator. Before any V2 handover, a separately implemented deterministic
control plane must authorize the actual actor and case scope, freeze the
evidence/subject/policy snapshot, claim the event, lock the case, reserve
each stage, validate each request and result, persist all holds and journal
entries, and reconcile ambiguous calls without retry. It must prevent a next
call until validation and reservation have completed, not merely check results
after all calls. No such connected-agent interposition mechanism is implemented
or verified in these ZIPs. If the platform cannot enforce it around *each*
model-directed call, do not enable V2; redesign with a deterministic dispatcher.
The historical flow recipe is a source of control requirements, not an
implemented control plane. Keep production disabled pending bank approval.

## Configure links in an explicitly authorized development environment

Only a maker with explicit authorization may do the following, using synthetic
data. Import all six agent ZIPs into the same environment. For each of the
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
data. Do not enable general knowledge merely to make a test pass. Since exact
forwarding and per-call external guard behavior have not been verified, no
production execution is authorized.

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
