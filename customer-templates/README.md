# Customer upload templates

**DRAFT / NOT APPROVED.** These are real editable Word `.docx` documents, not
completed customer records, protected form controls, verified electronic
signatures or a deployed upload service. Bank Compliance, Legal, DPO and Tax
must adapt/approve the selected forms and privacy notice before issuance.
All bank/country/product placeholders remain unresolved.

Do not issue the entire pack indiscriminately. Select lawful necessary sections
and evidence, remove nonapplicable fields, set accepted alternatives and
formats/freshness, and supply actual secure case-specific upload instructions.
No default document age, ownership threshold, PEP lookback, notification period,
income/risk band, tax classification or universal checklist is prescribed.

| Code / editable document | Conditional purpose | INT-1 classification |
| --- | --- | --- |
| [CO-00 upload guide](CO-00-customer-upload-guide.docx) | Bank-adapted instructions; not normally returned | other_supporting; not evidence of checks |
| [CO-01 individual application](CO-01-individual-application-form.docx) | Selected individual intake fields | application_form |
| [CO-02 business application](CO-02-business-application-form.docx) | Selected legal-entity intake fields | application_form |
| [CO-03 individual tax worksheet](CO-03-tax-self-certification-individual.docx) | Draft supplement only; Tax must validate/replace with applicable official self-certification | tax_self_certification |
| [CO-04 entity tax worksheet](CO-04-tax-self-certification-entity.docx) | Same limitation; no generic CRS/FATCA entity or controlling-person test | tax_self_certification |
| [CO-05 ownership declaration](CO-05-beneficial-ownership-declaration.docx) | Customer claims, ownership/control chart and explicit unresolved matters | ubo_declaration |
| [CO-06 funds/wealth declaration](CO-06-source-of-funds-and-wealth-declaration.docx) | Only requested fund/wealth scope and corroborating evidence | source_of_funds_evidence or source_of_wealth_evidence according to content |
| [CO-07 authority/signatories](CO-07-board-resolution-authorised-signatories.docx) | Optional Legal-adapted authority evidence for the actual legal form | board_resolution |
| [CO-08 related person](CO-08-related-person-information-sheet.docx) | Only requested in-scope representative/owner/other person's selected details | application_form |

These are expected content labels, not guaranteed classifications. The
[INT-1 taxonomy](../knowledge/04-required-intake-documents.md) and specialist
contract keep formCode separate from documentType. A code/filename is not proof
of authenticity, completeness, identity, authority, tax status or case linkage.
Bank/provider evidence is separate from customer declarations. The customer
does not upload a provider report on the bank's behalf.

## Secure case upload

The bank provisions the authoritative case and an approved isolated SharePoint
case folder. Give the customer only their bank-issued CaseId and authorized
location once the external-access model is approved. The current source design
permits bank-operated test intake only until this authorization model is
configured and verified. No public links or live permissions exist here.

Use the exact CaseId in the library's **CaseId metadata column**; a value typed
inside a form or filename is not a binding. The flow validates the case list,
folder/ACL and authenticated access context before reading document content.
Never reveal another case's records or allow customers to edit authoritative
case fields. Prefer bank-set metadata; independently revalidate any user edit.

Only new-file creation triggers intake. If metadata is absent/invalid/late,
the existing event is held. An authorized operator corrects/validates it and
explicitly resumes that same ledger event; changing metadata alone does not
rerun it. Ask the bank through its approved contact channel, not another case.
Follow approved malware/content checks, protected storage, minimal excerpts,
secure flow histories and the bank's lawful retention schedule.

## Regeneration and release

Source is [generator/forms.js](generator/forms.js); the dependency-free
[generator](generator/generate.js) builds OOXML with Node's native CRC32 API
(Node **22.15+**, or a later supported release that provides `zlib.crc32`):

```powershell
node .\customer-templates\generator\generate.js
```

The generator writes the nine documents here with deterministic ZIP timestamps.
Review changes in source and generated files together. ZIP/XML validation does
not prove Word pagination/accessibility or legal validity; bank release review
must inspect the rendered documents, approved labels/fields, signatures and
privacy wording in the target Word client. Do not submit a signed form with
unresolved bank placeholders. No customer data belongs in these repository files.
