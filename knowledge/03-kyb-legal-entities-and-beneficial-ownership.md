# 03 — KYB: legal entities, ownership and control

Knowledge pack 0.1.0-draft · Used by: Business verification agent · Section IDs: `KYB-x.y`.

**Approval:** DRAFT / NOT APPROVED. **Scope:** legal persons; legal arrangements
need approved overlays. **Checked:** 2026-11-19.
**Source:** [2015/849 Arts 3(6), 13-14, 30-31](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02015L0849-20241230);
[applicability](sources-and-applicability.md).
Missing decisions: legal forms, countries/EEA, ownership/control tests, lawful
register access, authorized representation and provider/policy configuration.

## KYB-1 Entity identification data

| ID | Attribute | Typical source |
|---|---|---|
| KYB-1.1 | Registered legal name and any trading names | Official business register extract |
| KYB-1.2 | Legal form | Register extract / articles |
| KYB-1.3 | Registration number and register | Register extract |
| KYB-1.4 | Registered office address and principal place of business | Register extract; evidence if different |
| KYB-1.5 | Date and country of incorporation | Register extract / certificate of incorporation |
| KYB-1.6 | Legal Entity Identifier (LEI), if any | GLEIF — optional unless `[BANK POLICY]` requires |
| KYB-1.7 | VAT / tax identification number | National systems; VIES for intra-EU VAT |
| KYB-1.8 | Directors / members of the management body | Register extract |
| KYB-1.9 | Nature of business, sector, NACE code | Application, register, website, financials |
| KYB-1.10 | Status (active, in liquidation, struck off) | Approved source/freshness rules; no age is set in this draft |

## KYB-2 Verification

- KYB-2.1 Verify existence and status against an official register or equivalent reliable, independent source. A self-supplied copy is evidence, not verification, until checked against the source.
- KYB-2.2 Verify the persons acting on behalf of the entity and their authority (signing rules in the articles/register, board resolution, power of attorney). Each of them is identified and verified as a natural person (`02`).
- KYB-2.3 Understand the ownership **and** control structure, down to the natural persons at the top of every chain.

## KYB-3 Beneficial ownership

| ID | Rule | Notes |
|---|---|---|
| KYB-3.1 | Ownership test | Use the applicable legal definition and approved jurisdiction/policy version; this draft supplies no percentage threshold. |
| KYB-3.2 | Indirect ownership | Preserve source-cited chains and apply only approved legal aggregation/control rules; simple percentage multiplication alone does not establish beneficial ownership. |
| KYB-3.3 | Control by other means | Voting agreements, right to appoint/remove most directors, veto rights, dominant influence, family relationships acting in concert, nominee arrangements. |
| KYB-3.4 | Senior managing official fallback | Only under the applicable legal conditions, with recorded steps/difficulties and authorized review; never automatically choose a director after failed discovery. |
| KYB-3.5 | Trusts and similar arrangements | Apply the actual trust/arrangement definition, including relevant settlors, trustees, protectors, beneficiaries/classes and other ultimate controllers; not a corporate percentage shortcut. Selected law determines identification/verification of classes or future interests. |
| KYB-3.6 | Foundations, associations, NPOs | Select the actual legal-form ownership/control and financial-access rules; do not infer wrongdoing or reject solely from NPO status. |
| KYB-3.7 | Listed companies | Companies listed on an EU regulated market (or equivalent disclosure regime) may have simplified BO identification `[BANK POLICY]`. |
| KYB-3.8 | Central BO register | Use lawful current access and discrepancy procedures for the selected jurisdiction; do not assume unrestricted access or rely on it exclusively. Check 2024/1640's phased register changes and national implementation. |

## KYB-4 Sequencing dependency

1. Verify the entity and current register data (KYB-1, KYB-2.1).
2. Build the ownership/control map and identify all BOs, representatives and controllers (KYB-3).
3. An authorized human reconciles ownership/authority, commits the scoped subject
   snapshot and increments SubjectSetVersion before person checks and screening.
4. Changes require explicit reassessment/resume of affected checks under approved
   policy; never automatically repeat uncertain provider calls or reuse stale results.

## KYB-5 Draft outputs and gaps

The business agent prepares a **draft** ownership map with, for every node:
source document reference and version, observed ownership/control claims and
uncertainty. Model confidence is not evidence. It must flag:

- KYB-5.1 Missing layers, unknown holders or unresolved control relevant to the applicable ownership/control test; do not invent an aggregation formula
- KYB-5.2 Discrepancies between register, BO register and customer declarations
- KYB-5.3 Bearer shares, nominee shareholders/directors, or circular ownership
- KYB-5.4 Entities in high-risk third countries or with no apparent economic rationale for the structure
- KYB-5.5 Shell-company indicators: no employees, no physical presence, recently incorporated with large expected volumes, mass-registration address
- KYB-5.6 Stale register extracts or entity not in active status

The agent never decides who the BOs are; a human reviewer confirms the map.
Indicators are not findings of wrongdoing. These review topics do not add fields
to the constrained business-result JSON contract.

## KYB-6 Higher-risk sectors (indicative; `[BANK POLICY]` defines the list)

Cash-intensive businesses, money service businesses and payment intermediaries
(check licence), crypto-asset service providers (check MiCA authorisation),
gambling, precious metals and stones, arms and defence, real estate,
art dealers, extractive industries, and NPOs operating in conflict zones.
