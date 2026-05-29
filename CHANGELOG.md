# Changelog

All notable changes to the FMD Framework are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added
- `execution.sp_GetLandingzoneEntity` — JSON-formatting stored procedure for landing zone parallel execution, consistent with the existing `sp_GetBronzelayerEntity` and `sp_GetSilverlayerEntity` counterparts.
- `logging.vw_ExecutionSummary` — Unified view across `PipelineExecution`, `NotebookExecution`, and `CopyActivityExecution` audit tables. Resolves START/END/FAIL pairs into a single row per execution unit with duration and status columns. Use to build observability dashboards or feed alerting.

### Fixed
- `execution.sp_GetBronzeCleansingRule` — `@OutputTable` was declared but never populated; added `INSERT INTO @OutputTable` so the procedure returns the correct result set instead of an empty set.
- `execution.sp_GetSilverCleansingRule` — Same fix as above for the Silver layer counterpart.

---

## [1.0.0] — Initial Release

### Added
- Medallion Lakehouse architecture: Landing Zone → Bronze → Silver → Gold.
- Fabric SQL Database (`SQL_FMD_FRAMEWORK`) with `integration`, `execution`, and `logging` schemas.
- Full set of orchestration pipelines: `PL_FMD_LOAD_ALL`, `PL_FMD_LOAD_LANDINGZONE`, `PL_FMD_LOAD_BRONZE`, `PL_FMD_LOAD_SILVER`.
- Source connectors: Azure SQL, ADLS Gen2, SFTP/FTP, ADF, Oracle, OneLake (files + tables), Custom Notebook.
- Notebooks: `NB_FMD_LOAD_LANDING_BRONZE`, `NB_FMD_LOAD_BRONZE_SILVER`, `NB_FMD_DQ_CLEANSING`, `NB_FMD_CUSTOM_DQ_CLEANSING`, `NB_FMD_UTILITY_FUNCTIONS`, `NB_FMD_PROCESSING_PARALLEL_MAIN`.
- Business Domain support with Gold layer templates (`NB_LOAD_GOLD`, `NB_CREATE_DIMDATE`, `NB_CREATE_SHORTCUTS`).
- Variable Libraries (`VAR_CONFIG_FMD`, `VAR_FMD`) with Test / Acceptance / Production value sets.
- Fabric CLI-first deployment via `setup/NB_SETUP_FMD.ipynb` and `setup/NB_SETUP_BUSINESS_DOMAINS.ipynb`.
- Taskflow (`FMD_FABRIC_TASKFLOW.json`) for visual orchestration.
- Bulk onboarding tool: `PL_TOOLING_POST_ASQL_TO_FMD`.
- Architecture diagrams (Excalidraw) under `Images/Architecture/`.
