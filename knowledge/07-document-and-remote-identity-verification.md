# 07 — Document checks and remote identity verification

Knowledge pack 0.1.0-draft · Used by: Document intake and Identity agents · Section IDs: `DOC-x.y`.
**Approval:** DRAFT / NOT APPROVED. **Checked:** 2026-11-19.
**Source:** [EBA/GL/2022/15](https://www.eba.europa.eu/legacy/regulation-and-policy/regulatory-activities/anti-money-laundering-and-countering-financing-4)
(application 2 October 2023 per EBA page); [applicability](sources-and-applicability.md).
Missing decisions: current national/EEA accepted methods/documents, provider
assurance/security standards, lawful biometric processing and fallback process.

## DOC-1 What an agent can and cannot establish

| Agent can report (draft) | Only an approved method or a human can establish |
|---|---|
| Document class, legibility, completeness of pages | Authenticity of the document |
| Expiry date vs. today; issuing state recognised | That the holder is the person applying (liveness/biometric match) |
| Data consistency across documents and the application | That the document was not tampered with at the pixel/chip level |
| Missing or conflicting fields | Final verification status |

## DOC-2 Basic visual checks for scans (indicators only)

- DOC-2.1 All data pages/both sides present; photo and MRZ visible
- DOC-2.2 MRZ check digits consistent with printed data (if parsed by an approved tool)
- DOC-2.3 Fonts, alignment and layout consistent with the document type
- DOC-2.4 No visible editing artefacts, cropping of security features, or screenshots of screens
- DOC-2.5 Acceptance of each document/method is a selected-country/bank decision, not a generic rule excluding a document category.

Failures are reported as `possible_tampering` or `quality_issue` for human
review. The agent never concludes a document is forged.

## DOC-3 Remote onboarding requirements (EBA/GL/2022/15 summary)

- DOC-3.1 The bank must document and assess its remote solution before use (pre-implementation assessment) and monitor it on an ongoing basis.
- DOC-3.2 Collected evidence must be legible, unaltered and captured in real time where relevant; images must be of sufficient quality.
- DOC-3.3 Reliable, independent source verification: e.g. reading the NFC chip of eMRTDs/eID cards, eIDAS-notified eID, qualified trust services.
- DOC-3.4 Where biometrics are used: liveness detection and a biometric match between the person and the document photo, with appropriate accuracy and anti-spoofing.
- DOC-3.5 Where video is used: trained staff, sufficient quality, and measures against deepfakes/manipulation.
- DOC-3.6 Fall back to other methods (in-branch, further verification) when the remote process cannot provide adequate assurance.
- DOC-3.7 Outsourced providers remain the bank's responsibility; provider configuration and versions must be recorded.

## DOC-4 Evidence record for verification

For each verified person record: method (KYC-3), provider and product version,
transaction/reference ID, timestamp, result codes, assurance level (for eID),
reviewer (if manual), and linked document references. Agents cite these
references; they do not restate biometric data or document numbers.

## DOC-5 Fraud indicators (escalate)

- DOC-5.1 Same face/photo across different identities
- DOC-5.2 Document template/serial anomalies flagged by the provider
- DOC-5.3 Device, IP geolocation or session inconsistent with declared residence (when provided by the flow)
- DOC-5.4 Repeated failed attempts or provider fraud alerts
- DOC-5.5 Indicators of synthetic identity (new identity with no history, inconsistent attributes)

Use only authorized scoped evidence; never compare faces, device data or other
cases from memory. Provider fraud alerts remain allegations/indicators for
review, not model findings of forgery or identity verification.
