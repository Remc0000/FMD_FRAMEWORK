# Agent_FMD_Install

Use this file when a user says: **"install FMD_framework for me using Agent_FMD_Install.md"**.

## Goal

Deploy the FMD Framework into Microsoft Fabric in a safe, repeatable way, then verify the result and summarize what happened.

## First step: ask for the missing information

Before doing anything, ask the user for these details:

| Question | Why it matters |
|---|---|
| What is the source repo? | Use the right fork or upstream source. |
| What is the target Fabric workspace name? | The setup workspace must be created or reused. |
| What capacity should be used? | Needed for workspace creation and reassignment. |
| What is the Key Vault name or URI? | Required for tenant-specific configuration. |
| What service principal should be used? | Needed for workspace roles and deployment auth. |
| Should business domains be deployed too? | Controls whether the domain notebook runs. |
| Which business domains should be created? | Example: FINANCE, SALES. |
| Should demo/example data be loaded? | Controls the final load step. |
| Should the deployment use the upstream repo or a fork? | Avoids hardcoding your personal values. |
| Should code changes be proposed first before any push? | Some fixes may need review before committing. |

If any answer is missing, continue asking before deploying.

## Deployment flow

1. Read the deployment guides:
   - `FMD_FRAMEWORK_DEPLOYMENT.md`
   - `FMD_BUSINESS_DOMAIN_DEPLOYMENT.md`
2. Clone or update the repo.
3. Create or verify the Fabric setup workspace.
4. Resolve the tenant identifiers needed for deployment.
5. Configure the setup notebook(s) with the user-provided values.
6. Run the framework deployment notebook.
7. Run the business-domain notebook if requested.
8. Load demo data if requested.
9. Verify workspaces, lakehouses, pipelines, connections, and data.
10. Report:
   - elapsed time
   - cost indication
   - what was learned
   - any repo changes that should be proposed before pushing

## Rules

- Do not reuse values from previous sessions.
- Do not hardcode tenant-specific values into shared repo files.
- If a code change is needed, explain it first and wait for approval before pushing.
- Prefer generic placeholders and user prompts over personal defaults.
- If permissions or admin scopes block deployment, stop and state the blocker clearly.

## Fabric CLI note

- If `fab auth login` fails with `No Windows console found`, do **not** treat that as a permissions problem.
- Have the user log in manually in a real Windows terminal, then confirm with `fab auth status`.
- On this machine, `fab` is most reliable when run through `cmd.exe` with `D:\npm-global` on `PATH`.
- Once `fab auth status` shows logged in, retry the domain or workspace command.

## Runtime note

- If a notebook imports `sempy.fabric` only to resolve the current workspace id, replace it with `notebookutils.runtime.context.get("currentWorkspaceId")` and fallback to `workspaceId`.
- That avoids runtime-context failures during Fabric notebook bootstrap or pipeline execution.

## Skills and helpers used in recent installs

Use these only when they match the task:

- `fabric-skills:FabricDataEngineer` — deployment orchestration and Fabric setup work
- `spark-operations-cli` — Spark/Livy/runtime triage and failure diagnostics
- `drawio-skill` — architecture diagrams and deployment visuals

## Suggested prompt

> Ask me the required inputs for an FMD Framework install, then deploy it in Fabric using the values I provide. If code changes are needed, show them before pushing.
