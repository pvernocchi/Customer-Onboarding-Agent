# 06 — Sanctions, PEP and adverse media screening

Knowledge pack 0.1.0-draft · Used by: Financial crime screening agent · Section IDs: `SCR-x.y`.

The agent **does not perform screening itself**. Screening is executed by an
approved provider through a controlled flow; the agent prepares a draft review
of the provider's results.

**Approval:** DRAFT / NOT APPROVED. **Checked:** 2026-11-19.
**Sources:** [Commission official sanctions resources](https://finance.ec.europa.eu/eu-and-world/sanctions-restrictive-measures/overview-sanctions-and-related-resources_en);
[2015/849 Arts 20-23, 39](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02015L0849-20241230).
See [applicability](sources-and-applicability.md). Missing decisions: applicable
regimes, national/EEA measures, providers/coverage, matching rules and escalation.

## SCR-1 Who is screened

Candidate coverage below must be scoped under actual approved legal/policy
requirements. It is not a universal obligation to collect/screen every director
or every document subject. Once the authorized scope is reviewed, the flow must
cover the complete accepted person/business set, not silently omit a subject.

- SCR-1.1 Individual customer
- SCR-1.2 Business customer (legal name, trading names, former names)
- SCR-1.3 All beneficial owners, directors/management body, authorised signatories and representatives
- SCR-1.4 Intermediate entities in the ownership chain
- SCR-1.5 Change/list-update review and any re-screening require approved ongoing-monitoring policy and controlled scheduling, outside this creation-only slice. Do not automatically replay uncertain calls; changes/resume use the existing journal and case/subject-version controls.

## SCR-2 Lists and sources

| ID | Source | Mandatory? |
|---|---|---|
| SCR-2.1 | Official EU consolidated financial sanctions list | Useful source; the applicable OJ legal acts control, including restrictions not resolved by list matching |
| SCR-2.2 | UN measures and their applicable implementation | Select applicable legal regimes and approved coverage; a separate raw-list call is not a universal legal prescription |
| SCR-2.3 | National sanctions lists of the bank's Member State(s) | `[COUNTRY OVERLAY]` |
| SCR-2.4 | Other regimes (US OFAC, UK OFSI, etc.) | `[BANK POLICY]` — e.g. due to USD clearing or group policy |
| SCR-2.5 | Approved PEP sources/process | Meet applicable identification/EDD requirements; no named database is universally mandated by this pack |
| SCR-2.6 | Adverse media (provider) | Risk-based `[BANK POLICY]` |

Record list name, provider, list version/timestamp, and match configuration for
every screening run.

## SCR-3 Sanctions — key principles

- SCR-3.1 Applicable sanctions prohibitions and required actions cannot be waived by a model or risk score. Legal scope, ownership/control, exceptions and national enforcement require authorized sanctions review.
- SCR-3.2 **Ownership and control** must be assessed under the actual applicable legal measures and approved current guidance; this draft configures no percentage or aggregation rule.
- SCR-3.3 Sectoral measures (e.g. restrictions on deposits from certain nationals/residents, securities, loans) may restrict specific products even without a listing — check the current regulations for affected countries.
- SCR-3.4 A confirmed sanctions match is **never** disposed of by an agent. Hold automated progression and escalate to authorized sanctions/Legal/Compliance for the actual prohibitions, freezing/reporting duties, exceptions or licences. The model cannot grant an exception or announce a legal outcome.

## SCR-4 Match handling

| ID | Draft classification | Meaning | Required action |
|---|---|---|---|
| SCR-4.1 | `provider_no_match_requires_review` | Approved provider report states no match for the scoped run | Preserve report/coverage/time; not bank clearance |
| SCR-4.2 | `possible_match` | Alert with partial match | Human review mandatory |
| SCR-4.3 | `inconclusive` | Unresolved report/identity information | Human review; never downgrade a provider possible_match into this state |
| SCR-4.4 | `possible_match` | Provider alert remains unresolved regardless of model opinion | Authorized sanctions/Compliance review; preserve the alert |
| SCR-4.5 | `provider_error` / `not_screened` | Provider error or missing report | Error/gap — never treated as no match |

Discriminators to compare: full name and aliases, date/year of birth,
nationality, place of birth, identification numbers, address, gender, for
entities registration number and country. Name-only similarity is never enough
to discount or confirm a match.

## SCR-5 PEP specifics

- SCR-5.1 PEP categories (AMLD Art. 3(9)): heads of state/government, ministers; members of parliament; members of supreme/constitutional courts; members of courts of auditors and central bank boards; ambassadors and senior military officers; members of the management bodies of state-owned enterprises; directors of international organisations; members of governing bodies of political parties. Member States publish national lists of prominent public functions `[COUNTRY OVERLAY]`.
- SCR-5.2 Family/close-associate and former-PEP definitions/time treatment require current applicable national rules; future AMLR provisions do not become today's defaults.
- SCR-5.3 Close associates: joint beneficial ownership or close business relations with a PEP; sole BO of an entity set up for a PEP's benefit.
- SCR-5.4 Middle-ranking or junior officials are not PEPs by function alone.
- SCR-5.5 PEP status is not proof of wrongdoing or a model refusal criterion. Apply the actual PEP measures and authorized approval process, not a generic EDD bundle (RSK-2.3).

PEP status and a possible sanctions match are not proof of wrongdoing. Preserve
the distinction between PEP, sanctions and adverse-media reports. Agents never
clear hits, freeze assets, permit transactions or make account decisions.

## SCR-6 Adverse media

Consider only credible, relevant information related to financial crime
(fraud, corruption, money laundering, terrorism financing, sanctions evasion,
tax crimes, organised crime). Record source, date and relevance; do not rely on
unverified social media. Allegations are flagged for review, not treated as
findings of fact.

## SCR-7 Tipping off

Customer communications and any lawful disclosure exceptions need authorized
Compliance/Legal handling. Do not expose suspicion, reporting or investigation
details in ordinary case titles, outreach, model replies or shared knowledge.
Use restricted compliance records and neutral operational holds.
