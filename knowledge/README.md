# Onboarding knowledge pack (EU/EEA bank)

**Status: DRAFT v0.1 — reference material, not approved bank policy or legal advice.**
Every file must be reviewed, adapted and signed off by the bank's Compliance /
MLRO function (and Legal / DPO where noted) before any agent uses it in
production. Items marked `[BANK POLICY]` are deliberately left for the bank to
decide; items marked `[COUNTRY OVERLAY]` vary by Member State and must be filled
in `10-country-overlays.md`.

## How agents must use this knowledge

- Knowledge files are **reference guidance**, never case evidence. Agents must
  not treat anything here as a fact about a specific customer.
- Knowledge never overrides the bank-approved rule set or policy version
  referenced in a case. If knowledge and configured policy disagree, the agent
  raises a `policy_conflict` issue for human review; unresolved applicability
  raises `policy_gap`. Neither can be silently resolved by a model.
- Knowledge does not authorise an agent to approve, reject, clear a screening
  hit, or close a case. Those are human decisions (see `08`).
- Cite the knowledge file and section ID (e.g. `KYC-2.3`) when a draft
  assessment relies on it, plus the knowledge pack version.

## Files and agent mapping

The mapping below is this project's scoped knowledge design, not a claim that
Microsoft mandates this exact division. After approval, attach only the listed
reference sources; keep customer evidence outside knowledge.

| File | Topic | Document intake | Identity (natural person) | Business (KYB) | Financial crime screening | Risk & review |
|---|---|:-:|:-:|:-:|:-:|:-:|
| `01-regulatory-framework-eu.md` | EU AML/CFT legal baseline and timeline | | | | | ✓ |
| `02-kyc-natural-persons.md` | CDD for individuals, representatives, UBOs | | ✓ | | | |
| `03-kyb-legal-entities-and-beneficial-ownership.md` | Entity verification, ownership, control | | | ✓ | | |
| `04-required-intake-documents.md` | Document checklists and acceptance criteria | ✓ | | | | |
| `05-aml-risk-assessment.md` | Risk factors, SDD/EDD, high-risk third countries | | | | | ✓ |
| `06-sanctions-pep-adverse-media-screening.md` | Screening scope, matching, hit handling | | | | ✓ | |
| `07-document-and-remote-identity-verification.md` | Document authenticity, remote onboarding | ✓ | ✓ | | | |
| `08-human-review-and-escalation.md` | Decision boundaries, escalation, tipping-off | | | | | ✓ |
| `09-data-protection-and-record-keeping.md` | GDPR, minimisation, retention | (flow/ops) | | | | |
| `10-country-overlays.md` | Member State specifics template | per agent as approved | | | | |

`09` governs the flows and operators more than the agents; attach it to an
agent only if the bank wants the agent to explain retention/minimisation gaps.

## Versioning

- Pack version: `0.1.0-draft`. Bump the minor version on content change and
  record approver, date and change summary in the change log below.
- Each case must record the knowledge pack version and policy version in use.
- Review on relevant legal/source changes and at a bank-approved cadence;
  this draft sets no refresh frequency.
- Key upcoming change: the EU AML Regulation (EU) 2024/1624 applies from
  **10 July 2027**; files flag where requirements will change.

## Change log

| Version | Date | Approver | Summary |
|---|---|---|---|
| 0.1.0-draft | 2026-11-19 | — (not approved) | Initial draft |

Primary references, checked dates and legal applicability are maintained once
in [sources-and-applicability.md](sources-and-applicability.md). All topic files
are draft reference guidance as of **2026-11-19**, not country-specific legal
determinations. [policy-decisions.json](policy-decisions.json) records unresolved
choices; [knowledge-manifest.json](knowledge-manifest.json) is the authoring map.
No source is uploaded or production-enabled.

The [source-first setup guide](../docs/03-specialist-setup.md) explains the five
agent contracts, knowledge ingestion/update steps and customer-form boundaries.
Customer forms CO-00 through CO-08 are drafts, not an instruction to collect
every form from every customer.
