# Customer-Onboarding-Agent
Multi-agent customer onboarding workflow for an EU/EEA bank, supporting individuals and businesses.

## First slice: SharePoint intake orchestrator

**Status: source/configuration scaffold, not deployed or tenant-tested.**
Uses Microsoft Copilot Studio (standard harness) and a solution-aware Power
Automate cloud flow triggered by **When a file is created (properties only)**.
The SharePoint site and document library remain configurable.

Start with the [provisioning and verification guide](docs/orchestrator-setup.md).
It includes the supported integration, durable duplicate handling, error paths,
and tenant prerequisites. These files are **not an importable Power Platform
solution**; generate the actual solution and agent source from your environment.

| Artifact | Purpose |
| --- | --- |
| [Agent instructions](orchestrator/agent-instructions.md) | Paste into Copilot Studio |
| [Configuration example](orchestrator/config.example.json) | Map to solution environment variables; no credentials |
| [Event contract](orchestrator/contracts/intake-event.schema.json) | Normalized metadata-only input |
| [Result contract](orchestrator/contracts/orchestration-result.schema.json) | Explicit pending-integration result |
| [Synthetic input](orchestrator/examples/intake-event.json) / [result](orchestrator/examples/orchestration-result.json) | Local fixtures, not real customer data |
| [Local checks](scripts/Test-OrchestratorContracts.ps1) | PowerShell 7.4+; no extra packages |

```powershell
pwsh -NoProfile -File .\scripts\Test-OrchestratorContracts.ps1
```

This slice does not read document content, create customers/cases, execute
KYC/AML agents, make bank/compliance decisions, or automate human approvals.

## Source-first expansion: specialists and cases

The [specialist setup guide](docs/specialist-setup.md) adds five distinct
Copilot Studio agent definitions: document evidence, natural-person identity,
business/ownership, financial-crime screening, and risk/human-review preparation.
It includes explicit contracts/examples, a SharePoint case-list design,
versioned v2 flow authoring, case-safe resume and concurrency/reconciliation
controls. V1 contracts and event keys remain unchanged.

[Knowledge](knowledge/README.md) contains draft KYC/CDD, AML/EDD, intake,
ownership, screening, evidence/privacy and human-review guidance, with verified
primary sources and unresolved country/EEA/bank-policy overlays.
[Customer templates](customer-templates/README.md) contains CO-00 through CO-08
editable Word drafts and a dependency-free generator.
**All knowledge/forms require bank Compliance/Legal/DPO and relevant Tax approval
before use; none is a universal required-document checklist or approved policy.**

This expansion is **manual source, not a deployed/executable low-code solution**.
No real provider checks, risk decisions or human approvals have been performed.
Only local validation and Word generation run without tenant configuration.
