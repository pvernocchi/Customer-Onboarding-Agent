# 09 - Build and import onboarding packages

The [development packages](../deployment/packages/) are **six agent-only Power Platform solution ZIPs**: the
metadata-only intake orchestrator and five standalone specialists. It uses
Microsoft PAC to generate and pack classic (standard-harness) agent workspaces
with their instructions and the minimal scaffold's platform topics. It does
not add custom topics, tools, channels, knowledge, connectors, or flows. The
archives were built with Microsoft PAC 2.15.1 and inspected locally. They have
not been imported into a tenant. This is not a full solution export.

## 1. Build the six agent packages

Use PowerShell 7.4+ and a [Power Platform CLI installation](https://learn.microsoft.com/power-platform/developer/cli/introduction)
whose `pac copilot help` lists both `init` and `pack`. If `pac` resolves to a
Windows batch launcher, pass the full path of its native `pac.exe` or
`pac.launcher.exe` via `-Pac`. Run from the repository root and use a new
output directory:

```powershell
.\scripts\Build-OnboardingAgentPackages.ps1 -OutputDirectory "$HOME\onboarding-build"
```

The build calls [`pac copilot init` and `pac copilot pack`](https://learn.microsoft.com/power-platform/developer/cli/reference/copilot)
locally without `--environment`. It doesn't sign in, import, or publish.
Complete output consists of `workspaces\<role>` (native agent source),
`packages\<role>` (one solution ZIP), and an inventory. If a build fails partway
through, don't treat that directory as a complete release; use a new directory
for the next attempt.

If PAC is unavailable, use the checked-in ZIPs or run with `-PrepareOnly` to
prepare six instruction files and `component-inventory.json` without network
access. The inventory and
Markdown are authoring inputs, **not importable solution files**. The local
build checks the packaged prompts and that web browsing, file analysis, general
knowledge and native agent connectivity are disabled. The SharePoint plan was
validated locally, but provisioning and tenant import were not tested.

## 2. Import and bind in an authorized development environment

1. Follow the [Microsoft agent solution import procedure](https://learn.microsoft.com/microsoft-copilot-studio/authoring-solutions-import-export)
   for each generated ZIP in a clean development environment with Dataverse.
   Check for conflicting agent schema names before importing. If ZIPs were not
   built, [use the manual creation sequence](00-agent-installation-guide.md)
   instead; do not both import and manually create duplicate agents.
2. Verify each agent's installed instructions, authentication and topics. Do
   not enable channels, web search, event triggers, autonomous delegation,
   tools or unapproved knowledge. No additional application topic definitions
   exist in the design. Keep all agents unpublished except for separately
   authorized synthetic testing requiring publication in development.
3. Use the generated inventory to create the Text environment variable
   definitions in the `OnboardingOrchestrator` solution with no defaults.
   Bind current site, library, list, environment and agent IDs in the target
   environment only. The optional provider endpoint variables have no defaults
   and do not implement or authorize an adapter. Use approved connections or
   a secret store for credentials, never a Text variable. Create and bind the
   SharePoint intake-read, SharePoint restricted-operations and Microsoft
   Copilot Studio connection references in the designer.
4. Provision the restricted SharePoint structures. The script below handles
   four **new** structures in one bank-verified development site. Use [01](01-orchestrator-setup.md)
   and [03](03-specialist-setup.md) for split-site layouts, existing-ledger
   migration, and the watched library's optional `CaseId` column. The script
   does not verify or change tenant sharing, role assignments, case-level
   ACLs, retention or evidence immutability; audit them separately.
5. In that same custom solution, build the disabled [SharePoint intake cloud
   flow](01-orchestrator-setup.md) and [V2 case processing and authorized
   operator resume flows](../orchestrator/v2/flow-authoring.md). The design
   connects specialists through **Power Automate's Execute Agent and wait**
   with one explicit role and validated request per dispatch. It does not use
   natively connected/child agents or agent-triggered tools for routing;
   substituting generative routing would bypass the deterministic design.
   Keep provider failures distinct from no match, validate untrusted filenames
   and document data at each boundary, and leave all decisions with reviewers.
6. Leave knowledge unbound. The [knowledge manifest](../knowledge/knowledge-manifest.json)
   maps role-specific files; the current pack is an unapproved draft. In an
   authorized environment, bind only reviewed, released policy-context sources
   to their designated role. Customer uploads and case reports are never
   knowledge. Recheck source access and indexing in each environment.

### SharePoint provisioning

```powershell
# Print list titles, templates and CAML field XML without connecting.
.\scripts\Initialize-OnboardingSharePoint.ps1 | Format-List

# Only once the bank verifies the isolated development site and approves the app.
$connection = Connect-PnPOnline -Url $site -ClientId $approvedClientId -Interactive -ReturnConnection
.\scripts\Initialize-OnboardingSharePoint.ps1 -Apply -Connection $connection `
  -RestrictedSiteUrl $site -ConfirmRestrictedDevelopmentSite -Confirm
```

Apply requires [PnP.PowerShell](https://pnp.github.io/powershell/) and list
creation rights. The script stops before creation if a target already exists;
it is not a migration or rollback tool. If creation stops partway through,
inspect and reconcile the partial state with the maker before retrying. In
SharePoint, verify internal names, column types, versioning, required fields,
unique indexes, no list attachments, site access and case isolation. Record
the actual IDs in the environment. Never test with real customer data.

## 3. Export, repack and validate the complete solution

Once an authorized maker has implemented and tested the development components,
add all six agents and every solution-aware flow to `OnboardingOrchestrator`.
Run **Add required objects** on agents and flows, audit included topics and
dependencies, and remove environment variable current values from the solution
before export. Export from the development tenant with flows **off**. If the
bank approves custom provider connectors, export them as prerequisites and
import them before the consuming solution. Do not copy secret settings or
customer data into the repository.

Use the tenant-produced unmanaged export as the input for repeatable builds:

```powershell
pac solution unpack --zipfile OnboardingOrchestrator.zip --folder .\solution-source --packagetype Unmanaged
pac solution pack --zipfile OnboardingOrchestrator_repacked.zip --folder .\solution-source --packagetype Unmanaged
pac solution create-settings --solution-zip OnboardingOrchestrator_repacked.zip --settings-file .\deployment-settings.dev.json
```

Review the unpacked source and exported objects before claiming full component
coverage. Fill the settings file privately or bind through the import UI.
Import into a second isolated development environment, inspect the import log,
and verify that agents, topics, dependencies, references, and flows survived
the move. Check flow state before granting connections access to any watched
library. Follow the synthetic acceptance tests in [01](01-orchestrator-setup.md)
and [03](03-specialist-setup.md), including duplicate events, cross-case
attempts, provider errors, and human holds. Keep production off unless the bank
separately approves the actual target deployment.
