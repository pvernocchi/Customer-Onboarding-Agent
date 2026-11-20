# 08 — Human review, escalation and decision boundaries

Knowledge pack 0.1.0-draft · Used by: Risk & review agent (and orchestrator instructions) · Section IDs: `HRV-x.y`.

**Approval:** DRAFT / NOT APPROVED. **Checked:** 2026-11-19.
**Sources:** [2015/849 Arts 13-14, 18-24, 33, 39](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02015L0849-20241230);
[GDPR Art 22](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32016R0679);
[applicability](sources-and-applicability.md).
Missing decisions: actual legal duties, authority matrix, escalation urgency,
segregation of duties, customer communication and national/product access rules.

## HRV-1 Decision boundaries

| ID | Decision | Who decides |
|---|---|---|
| HRV-1.1 | Classify documents, list gaps, draft assessments | Agents (draft only) |
| HRV-1.2 | Identity verified | Approved verification method + human sign-off per policy |
| HRV-1.3 | Beneficial ownership map confirmed | Human reviewer (KYC analyst) |
| HRV-1.4 | Screening alert disposition | Human reviewer; sanctions true matches → sanctions/compliance team |
| HRV-1.5 | Customer risk band | Human reviewer, using the bank's rule set |
| HRV-1.6 | Approve standard-risk onboarding | Authorised staff per `[BANK POLICY]` |
| HRV-1.7 | Any required PEP/EDD authorization | Actual statutory/approved-policy authority; do not assume identical requirements for every EDD case |
| HRV-1.8 | Refuse or exit a customer | Authorised staff; documented reason; basic payment account refusal rules apply (REG-2.7) |
| HRV-1.9 | Suspicious transaction report to FIU | MLRO / designated AML officer only |

Project control: no model makes a final onboarding decision; require meaningful
authorized human review. Legal must separately assess GDPR Art 22's actual
scope, exceptions and safeguards; this is not a claim that it bans every use of AI.

## HRV-2 Mandatory escalation triggers

- HRV-2.1 Any sanctions `possible_match` → immediate authorized sanctions review; automated progression on hold, no model disposition
- HRV-2.2 PEP / family / close associate → EDD workflow and senior-management approval
- HRV-2.3 High-risk third-country connection → authorized review of the actual applicable EDD trigger/scope, not an invented model conclusion
- HRV-2.4 Suspected document fraud or synthetic identity → fraud team and MLRO
- HRV-2.5 Indicators of ML/TF suspicion → MLRO (internal suspicious activity report); do not inform the customer
- HRV-2.6 Unable to complete CDD → do not establish the relationship; MLRO considers reporting (REG-3.2)
- HRV-2.7 Agent output invalid, provider errors, or policy conflicts → operations review queue

## HRV-3 Workflow review package

The flow/operators assemble this package from authorized snapshots. The risk
agent contributes only its schema-defined draft readiness/rule references;
this list is not permission to invent extra response fields or retrieve records.

1. Case summary: customer type, products requested, case revision
2. Completeness matrix (INT-5) and outstanding items
3. Identity and authority findings per subject
4. Ownership/control map and open questions (KYB-5)
5. Screening run evidence and alert drafts (SCR-4)
6. Source-cited approved rule findings and unresolved policy gaps; riskRating remains null in the agent contract (RSK-4)
7. Required approvals and approver level
8. All issues with severity, evidence references and knowledge section IDs
9. Policy version, knowledge pack version, and agent/instruction versions

## HRV-4 Communication rules

- HRV-4.1 Agents do not contact customers.
- HRV-4.2 Requests for missing documents are sent by staff or an approved template process and must not mention screening, risk scores or suspicion (SCR-7).
- HRV-4.3 Reviewer decisions, rationale and approver identity are recorded on the case and are immutable after sign-off (amendments create a new revision).
- HRV-4.4 Internal processing-results e-mail is a minimal draft summary, never customer approval or customer outreach. Use only bank-authorized case-team recipients, safe document reasons and a secured case link; screening/suspicion details remain restricted and appear only as "Requires restricted review". See the [disabled notification design](../docs/10-results-email-design.md); bank Compliance/DPO approval and tenant acceptance are required.

## HRV-5 Service levels `[BANK POLICY]`

Define lawful operational urgency and bank-approved target times for intake,
review, sanctions escalation, outreach and stalled cases. This draft supplies
no default service period. Detailed suspicion/reporting records must remain
separate from broadly visible review packs; preserve neutral hold references.
