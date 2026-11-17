# Admin portal

SQLPage administration module for user accounts, access profiles, password resets, equipment allocation, jobs and reload checklists.

## Layout and installation

- Root SQL files define SQLPage pages and form actions.
- admin.css and admin.js provide the portal presentation.
- The image files are static branding assets.

Mount this folder at Admin inside an existing SQLPage host application. The host must supply authentication, session tables, shared templates, linked application routes and an appropriately configured database connection. This is a module, not a standalone SQLPage installation.

Database configuration and credentials must remain outside this repository. Configure them privately in the host application. Never place passwords, populated environment files, account exports or connection strings in tracked files.

## Sanitized snapshot

The example email address and the ExampleHardwareDb and ExampleOperationsDb SQL identifiers replace local values. Map these example database identifiers to the reviewed databases in your own environment before use. Existing SQLPage parameters and password hashing are preserved.

Generated outputs, reports, database content, logs, account email drafts, operational helpers, deployment scripts and local configuration are excluded. The one-off helpers depend on local rollout artifacts or individual accounts and are not part of the application source snapshot.

The .gitignore file uses an explicit allowlist. Review both the content and the allowlist when adding files. Ignored files can still be added with git add -f; inspect the staged file list before every push.

## Verification

The initial export passed a JavaScript syntax check, Gitleaks source and committed-history scans, and an exact-value comparison against available local credential settings and account email drafts. These checks report no secret values. Source files in the working application were preserved.

To repeat the source and history scans, install Gitleaks and run:

```powershell
node --check admin.js
gitleaks dir . --redact=100
gitleaks git . --redact=100
git diff --cached --name-only
```

SQL routes were reviewed as source only. No application endpoints, database writes, deployments or service operations were performed. Review form actions before any integration testing: several routes intentionally modify users, sessions or hardware records.
