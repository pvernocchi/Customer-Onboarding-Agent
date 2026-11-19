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
