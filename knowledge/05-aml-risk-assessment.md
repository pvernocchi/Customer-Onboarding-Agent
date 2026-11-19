# 05 — AML/CFT customer risk assessment

Knowledge pack 0.1.0-draft · Used by: Risk & review agent · Section IDs: `RSK-x.y`.
Based on AMLD risk-based CDD principles and Annexes II/III. Scoring weights and bands are
`[BANK POLICY]` — the agent must use the configured rule set and **never invent
weights, thresholds or a risk band**.

**Approval:** DRAFT / NOT APPROVED. **Scope:** review preparation, not monitoring.
**Checked:** 2026-11-19. **Primary basis:** [2015/849 Arts 8, 13, 18-24, 33, 39](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02015L0849-20241230).
See [applicability](sources-and-applicability.md). Missing decisions: products,
countries, risk appetite, approved risk-factor/rule catalogue, EDD and reporting
procedures. Named EBA guidance must be checked for current AMLA replacement and
selected-authority applicability before use.

## RSK-1 Risk factor categories

### RSK-1.1 Customer
- PEP, family member or close associate (always EDD — REG-3.5)
- Complex or opaque ownership; nominee arrangements; bearer shares
- Cash-intensive or higher-risk sector (KYB-6)
- Adverse media relating to financial crime
- Activity or wealth inconsistent with profile
- Non-resident customer without clear rationale for an account in this country
- Previous refusal or exit by another institution for AML reasons (if known)

### RSK-1.2 Geographic
- Current applicable EU high-risk third-country designation, assessed against the actual Art 18a/national relationship/transaction scope and exceptions; no current list is embedded here
- Countries subject to EU sanctions or embargoes (see `06`)
- Countries identified by credible sources (FATF lists, EU/national assessments) as having significant corruption, terrorist financing or weak AML/CFT
- Connections: nationality, residence, incorporation, operations, counterparties, source of funds

### RSK-1.3 Product, service and transaction
- Products that favour anonymity or high-value cross-border flows
- Private banking, correspondent-type services, trade finance
- High expected cash deposits

### RSK-1.4 Delivery channel
- Non-face-to-face onboarding **without** safeguards is higher risk; remote onboarding compliant with EBA/GL/2022/15 is not inherently higher risk
- Introducers or intermediaries

### RSK-1.5 Lower-risk indicators (may support SDD where policy allows)
- Public administrations; companies listed on regulated markets with disclosure requirements
- Basic payment accounts with limited functionality `[BANK POLICY]`
- Residence in lower-risk EU jurisdictions

## RSK-2 Due diligence levels

| ID | Level | When | Measures |
|---|---|---|---|
| RSK-2.1 | Simplified (SDD) | Lower risk demonstrated and permitted by policy; no suspicion | Reduced frequency/extent of verification or monitoring — **never** omission of identification or sanctions screening |
| RSK-2.2 | Standard | Default | Full CDD (REG-3.1) |
| RSK-2.3 | Enhanced (EDD) | Applicable legal or approved higher-risk trigger | Apply the measures required by the actual trigger/country/policy; do not impose one generic EDD bundle or invent its approvals |

## RSK-3 Mandatory EDD triggers (cannot be scored away)

- RSK-3.1 Confirmed PEP / family member / close associate
- RSK-3.2 A relationship/transaction within the actual applicable Art 18a/national high-risk-country scope, with any legal exceptions assessed by authorized Compliance
- RSK-3.3 Any `[BANK POLICY]` mandatory trigger (e.g. specific sectors)

## RSK-4 Risk agent output (draft)

- RSK-4.1 List of risk factors found, each with evidence reference and the rule ID from the configured rule set
- RSK-4.2 Mandatory EDD triggers present (yes/no per RSK-3 item)
- RSK-4.3 Reference bank-approved deterministic rule findings only; the current contract keeps riskRating=null even when a rule set is configured.
- RSK-4.4 Open gaps and unresolved issues from upstream agents (identity, KYB, screening) — an incomplete upstream result keeps the case in review
- RSK-4.5 Actual required approvals for the relevant trigger; PEP requirements do not imply identical senior-management approval for all EDD cases

The model does not create a risk band or an authoritative compliance outcome.
Source of funds concerns the particular funds; source of wealth concerns how
wealth accumulated. Proportionate corroboration and remaining gaps must be
recorded under the actual PEP/EDD requirement, not a plausible model narrative.

Potential suspicion is handled by the MLRO/authorized Compliance function under
applicable national reporting rules. Agents do not file/withhold/announce STRs,
contact an FIU, or expose suspicion/reporting details in broad case summaries.
Protect confidentiality and tipping-off restrictions under Art 39; neutral
hold codes and restricted references belong in the general workflow.

## RSK-5 Periodic review (for policy design)

Review cadence and trigger-based reassessment require an approved national/bank
policy; this draft supplies no numeric intervals. Monitoring and FIU reporting
are separate integrations, not implemented by this source slice.
