# 09 - SharePoint provisioning and controlled deployment

Create agents manually using the [installation index](00-agent-installation-guide.md).
The repository supplies instructions, contracts and synthetic fixtures;
tenant configuration and acceptance are separate responsibilities.

## 1. Configure an authorized development environment

1. Obtain authorization for an isolated development environment with the
   required Copilot Studio, Power Automate, Dataverse and solution permissions.
   Use the bank's approved publisher and unmanaged `OnboardingOrchestrator`
   solution. Follow 02 and 04–08 to create agents, verifying any existing
   tenant agent before reuse rather than creating duplicates.
2. Use [01](01-orchestrator-setup.md) and [03](03-specialist-setup.md) to create
   the environment variables and SharePoint/Microsoft Copilot Studio connection
   references. Bind real tenant, site, library, list and agent IDs only in the
   target environment. Use approved connections or a secret store for
   credentials, never Text variables. Provider bindings remain null until
   separately approved integrations exist.
3. Provision the restricted SharePoint structures as described below. Verify
   tenant sharing, role assignments, case-level ACLs, retention and evidence
   immutability independently; the script does not enforce them.
4. Follow [01](01-orchestrator-setup.md) for the disabled V1 metadata-only
   intake flow. For V2, use [03](03-specialist-setup.md) and the
   [native handover design](../orchestrator/v2/connected-agent-handover.md).
   Do not build the historical direct specialist dispatcher. Any separately
   authorized native-link test must be isolated and synthetic, with intake
   off. Keep V2 disabled until per-call controls, tenant acceptance and bank
   approval are complete.
5. Leave knowledge unbound until approved. The
   [knowledge manifest](../knowledge/knowledge-manifest.json) maps role-specific
   files; the current pack is an unapproved draft. Bind only reviewed,
   released policy-context sources. Customer uploads and case reports are
   never shared knowledge. Recheck source access/indexing in each environment.

## 2. Provision SharePoint

The script handles four **new** structures in one bank-verified development
site. Use [01](01-orchestrator-setup.md) and [03](03-specialist-setup.md) for
split-site layouts, existing-ledger migration and the watched library's
optional `CaseId` column.

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
inspect and reconcile partial state before retrying. Verify internal names,
column types, versioning, required fields, unique indexes, no list attachments,
site access and case isolation. Record actual IDs in the environment. Never
test with real customer data.

For optional results notifications, follow
[the configuration instructions in 03](03-specialist-setup.md#internal-results-e-mail-separate-configuration-disabled)
and [the full authoring recipe in 10](10-results-email-design.md).
Manually add the proposed processing-run/outbox structures only after review;
the script does not provision them. Bind notification enablement (off by
default), approved internal routing/sender, Outlook permissions, case-link
resolver, retention and monitoring separately in each environment.

## 3. Transfer and verify tenant-authored components

Once an authorized maker has implemented and tested the development components,
add the agents and every solution-aware flow to `OnboardingOrchestrator`.
Use **Add required objects**, audit included topics/dependencies and remove
environment-variable current values before exporting through the supported
[Power Platform solution process](https://learn.microsoft.com/microsoft-copilot-studio/authoring-solutions-import-export).
Keep flows off. Separately approved custom connectors must be transferred
before their consuming components. Never commit secrets, customer data or
private environment bindings.

Import the tenant-produced solution into a second isolated environment,
inspect its import log and verify agents, topics, native links, dependencies,
connection references and flows. Rebind target values and confirm flow state
before granting access to a watched library. SharePoint provisioning and ACL
verification remain separate from solution transfer.

Repeat the synthetic acceptance checks in [01](01-orchestrator-setup.md),
[03](03-specialist-setup.md) and, when applicable,
[10](10-results-email-design.md). Cover duplicate events, cross-case attempts,
provider errors, human holds and notification reconciliation. Keep production
off unless the bank separately approves the actual target deployment.
