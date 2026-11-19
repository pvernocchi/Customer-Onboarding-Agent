# 02 — KYC checks for natural persons

Knowledge pack 0.1.0-draft · Used by: Identity verification agent · Section IDs: `KYC-x.y`.

Applies to: individual (retail) customers; persons acting on behalf of a
customer (legal representatives, attorneys, authorised signatories); and
beneficial owners of business customers.

**Approval:** DRAFT / NOT APPROVED. **Checked:** 2026-11-19.
**Sources:** [2015/849 Arts 13-14](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02015L0849-20241230);
[remote onboarding guidelines](https://www.eba.europa.eu/legacy/regulation-and-policy/regulatory-activities/anti-money-laundering-and-countering-financing-4).
See [applicability](sources-and-applicability.md). Missing decisions: lawful data
fields, accepted evidence/methods/providers, country/EEA and product rules.

## KYC-1 Roles to identify

| ID | Role | Identify | Verify |
|---|---|:-:|:-:|
| KYC-1.1 | Individual customer | Required | Required, before the relationship is established (see REG-3.2) |
| KYC-1.2 | Person acting on behalf of the customer | Required | Required, plus evidence of authority (power of attorney, board resolution, register extract) |
| KYC-1.3 | Beneficial owner of a business customer | Required | Reasonable, risk-based measures; level set by `[BANK POLICY]` |
| KYC-1.4 | Senior managing official under a legally available fallback | Only after applicable conditions and review | Apply actual legal identification/verification measures and record steps/difficulties; never automatic substitution |

## KYC-2 Candidate identification fields, subject to approved scope

These are not universal collection requirements. Collect only fields supported
by the applicable national/product policy and lawful purpose.

| ID | Attribute | Notes |
|---|---|---|
| KYC-2.1 | Full legal name (all forenames and surnames) | Record transliteration rules used for non-Latin scripts |
| KYC-2.2 | Date of birth | |
| KYC-2.3 | Place of birth | Actual national requirement must be selected; future AMLR does not supply today's default |
| KYC-2.4 | Nationality / nationalities | Only as required by approved lawful scope; never a model-based refusal criterion |
| KYC-2.5 | Residential address | Proof requirement is `[BANK POLICY]` / `[COUNTRY OVERLAY]` |
| KYC-2.6 | Identity document type, number, issuing state, expiry | Store references; mask numbers in agent outputs |
| KYC-2.7 | National identification / tax identification number | Where nationally required; CRS/FATCA self-certification (see INT-2.6) |
| KYC-2.8 | Occupation / employment status / employer | Supports risk profile and source-of-funds plausibility |

## KYC-3 Candidate verification methods (no default preference or approval)

| ID | Method | Notes |
|---|---|---|
| KYC-3.1 | In-person check of an original, valid government-issued photo ID | Passport, EU/EEA national ID card, residence permit |
| KYC-3.2 | eIDAS-notified electronic identification at assurance level *substantial* or *high*, or a European Digital Identity Wallet | See REG-2.9 |
| KYC-3.3 | Remote document + biometric (selfie/liveness) verification by an approved provider | Must meet EBA/GL/2022/15; see `07` |
| KYC-3.4 | Qualified electronic signature / other national schemes | `[COUNTRY OVERLAY]` |
| KYC-3.5 | Reliance on another obliged entity | Only where policy permits (REG-3.9) |

Any listed method requires national acceptance, bank approval and suitable
privacy/security controls; its name alone is not evidence that checks occurred.
An uploaded image of an identity document **alone is not verification**. The
agent may describe source-supported presence, quality and date/expiry claims,
not certify document validity or authenticity; only an
approved verification method or a human reviewer establishes verification.

## KYC-4 Purpose and nature of the relationship

Assess under the applicable approved relationship and risk policy:

- KYC-4.1 Purpose of the account (salary, savings, mortgage, investments…)
- KYC-4.2 Expected activity: monthly inflows/outflows, cash usage, cross-border payments and countries
- KYC-4.3 Source of funds for the initial deposit and expected flows
- KYC-4.4 Source of wealth evidence where the applicable PEP/EDD or other approved requirement calls for it; do not impose an identical form on every EDD case.

## KYC-5 Checks the identity agent prepares (drafts only)

| ID | Check | Possible draft outcomes |
|---|---|---|
| KYC-5.1 | Data completeness against KYC-2 | complete / missing fields listed |
| KYC-5.2 | Consistency across documents and application form (name, DOB, nationality, address) | consistent / conflicts listed |
| KYC-5.3 | Document-date/acceptance evidence for human review | source-supported date claim / acceptance gap / unknown; not authenticated validity |
| KYC-5.4 | Verification method evidence present (provider report, eID assertion, in-person attestation) | present / absent / failed |
| KYC-5.5 | Authority evidence for representatives | present / insufficient |
| KYC-5.6 | Minor or legal incapacity indicators | requires guardian/legal representative documentation |

Draft outcomes are **never** "verified" or "approved". Any conflict, absence, or
provider failure is reported as a gap for human review.
This table describes review checks, not extra JSON fields: the agent emits
only the limited assessments/references allowed by its actual role contract.

## KYC-6 Common red flags (escalate, never conclude)

- KYC-6.1 Inconsistent personal data across documents
- KYC-6.2 Reluctance to provide information or unexplained urgency
- KYC-6.3 Address is a mail-forwarding service or matches many unrelated applicants
- KYC-6.4 Same contact details (phone/email/device) used across unrelated applications
- KYC-6.5 Expected activity inconsistent with stated occupation or income
- KYC-6.6 Third party apparently directing the application

Red flags are indicators only; the presence of one does not establish
suspicion. Do not disclose red-flag reasoning to the customer (REG-3.7).

## KYC-7 Inclusion and non-discrimination

- KYC-7.1 Recommended operational control: do not infer failed identity or ineligibility solely from a nonstandard address, refugee/asylum status or non-EU ID. Route to the bank-approved alternative-evidence/access procedure under the actual `[COUNTRY OVERLAY]`; the model cannot decide eligibility.
- KYC-7.2 Applicable basic-payment-account access/refusal rules require country/product/customer-scope review (REG-2.7). Decisions and communications belong to authorized staff.
- KYC-7.3 The model cannot infer refusal/eligibility from nationality. Authorized staff must assess actual access, non-discrimination and sanctions/product restrictions rather than applying a generic rule.
