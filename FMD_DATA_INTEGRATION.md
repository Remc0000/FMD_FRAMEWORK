---
Title: Load Data from Azure SQL into FMD
Description: Step-by-step guide to registering an Azure SQL data source and loading tables through the Landing Zone → Bronze → Silver pipeline.
Topic: how-to
Date: 05/2026
---

# Loading Data from Azure SQL into FMD

This guide explains how to connect an Azure SQL database to the FMD Framework after the initial deployment has been completed. It covers single-table onboarding via stored procedures and bulk onboarding via the `PL_TOOLING_POST_ASQL_TO_FMD` pipeline.

> **Prerequisites:** Complete the [FMD Framework Deployment](FMD_FRAMEWORK_DEPLOYMENT.md) before following this guide.

---

## Overview

Every source table you want to load must be registered in the `SQL_FMD_FRAMEWORK` configuration database before a pipeline can process it. The registration follows a three-step hierarchy:

```
integration.Connection          ← the Fabric connection to the source system
    └─ integration.DataSource   ← the source system (e.g. RvDSQL)
           └─ integration.LandingzoneEntity  ─┐
              integration.BronzeLayerEntity   ├─ registered together via sp_UpsertLandingzoneBronzeSilver
              integration.SilverLayerEntity  ─┘
```

Once registered, `PL_FMD_LOAD_ALL` picks up the entity on the next run and moves data through:

```
Azure SQL  →  Landing Zone (Parquet)  →  Bronze (Delta)  →  Silver (SCD Type 2 Delta)
```

---

## Step 1 — Create a Fabric connection to Azure SQL

1. In Microsoft Fabric, go to **Settings → Manage connections and gateways**.
2. Select **New connection**.
3. Choose **Azure SQL Database** as the connection type.
4. Fill in the server and database name (e.g. `RvDSQL`), set authentication to **OAuth2**.
5. Save the connection and open it. Copy the **Connection GUID** from the browser URL — you will need it in the next step.

> **Tip:** Name the connection consistently, for example `CON_RVDSQL`, so it is easy to identify later.

---

## Step 2 — Register the connection in the config database

Open the `SQL_FMD_FRAMEWORK` database (in your `FMD_FRAMEWORK_CONFIGURATION` workspace) and run:

```sql
-- Register the Fabric connection
EXEC [integration].[sp_UpsertConnection]
    @ConnectionGuid = '<paste Connection GUID from Step 1>',
    @Name           = 'CON_RVDSQL',
    @Type           = 'ASQL_01',
    @IsActive       = 1;
```

Note the `ConnectionId` returned — you need it in the next step.

---

## Step 3 — Register the data source

```sql
-- Register the Azure SQL database as a data source
EXEC [integration].[sp_UpsertDataSource]
    @ConnectionId = <ConnectionId from Step 2>,
    @Name         = 'RvDSQL',
    @Namespace    = 'RVDSQL',      -- Short prefix used in landing zone file paths (max 10 chars)
    @Type         = 'ASQL_01',
    @Description  = 'Azure SQL Database RvDSQL',
    @IsActive     = 1;
```

Note the `DataSourceId` returned — you need it when registering tables.

---

## Step 4 — Register tables (single-table onboarding)

Use `sp_UpsertLandingzoneBronzeSilver` to register a table across all three layers in one call. Run once per table you want to load.

```sql
EXEC [integration].[sp_UpsertLandingzoneBronzeSilver]
    @DataSourceId        = <DataSourceId from Step 3>,
    @WorkspaceGuid       = '<your development DATA workspace GUID>',

    -- Source table in Azure SQL
    @SourceSchema        = 'dbo',
    @SourceName          = 'Customer',

    -- Target name in Bronze and Silver lakehouses
    @TargetSchema        = 'dbo',
    @TargetName          = 'Customer',

    -- Landing zone file settings
    @SourceCustomSelect  = NULL,              -- NULL = SELECT *, or provide custom SQL
    @FileName            = 'Customer',
    @FilePath            = 'landing',
    @FileType            = 'parquet',

    -- Incremental load settings
    @IsIncremental       = 1,                 -- 0 = full reload every run
    @IsIncrementalColumn = 'ModifiedDate',    -- watermark column; NULL if full load

    @CustomNotebookName  = NULL,              -- NULL = use standard pipeline
    @PrimaryKeys         = 'CustomerId';      -- comma-separated if composite key
```

Repeat for every table you want to include. The stored procedure is idempotent — re-running it updates the existing registration instead of creating duplicates.

### Full load example (no watermark)

```sql
EXEC [integration].[sp_UpsertLandingzoneBronzeSilver]
    @DataSourceId        = <DataSourceId>,
    @WorkspaceGuid       = '<DATA workspace GUID>',
    @SourceSchema        = 'dbo',
    @SourceName          = 'ProductCategory',
    @TargetSchema        = 'dbo',
    @TargetName          = 'ProductCategory',
    @SourceCustomSelect  = NULL,
    @FileName            = 'ProductCategory',
    @FilePath            = 'landing',
    @FileType            = 'parquet',
    @IsIncremental       = 0,
    @IsIncrementalColumn = NULL,
    @CustomNotebookName  = NULL,
    @PrimaryKeys         = 'ProductCategoryId';
```

---

## Step 4 (alternative) — Bulk onboarding with PL_TOOLING_POST_ASQL_TO_FMD

If you have many tables to onboard, use the `PL_TOOLING_POST_ASQL_TO_FMD` pipeline instead of running the SP manually for each table.

The pipeline reads table metadata directly from the Azure SQL source, posts it to FMD, and registers all matching tables automatically.

**How to run it:**

1. Open your **CODE workspace** in Fabric.
2. Find the pipeline `PL_TOOLING_POST_ASQL_TO_FMD`.
3. Click **Run** and supply the following parameters:

| Parameter | Description | Example |
|---|---|---|
| `DataSourceId` | ID returned in Step 3 | `1` |
| `WorkspaceGuid` | Your DATA workspace GUID | `xxxxxxxx-xxxx-...` |
| `SourceSchema` | Schema to scan in Azure SQL | `dbo` |
| `PrimaryKeys` | Default primary key column name | `Id` |
| `IsIncremental` | Default incremental flag | `1` |
| `IsIncrementalColumn` | Default watermark column | `ModifiedDate` |

> **Note:** The bulk pipeline applies the same `PrimaryKeys` and `IsIncrementalColumn` to all discovered tables. Adjust individual tables afterwards using `sp_UpsertLandingzoneBronzeSilver` if specific tables need different keys or watermarks.

---

## Step 5 — Run the pipeline

Once your tables are registered, trigger the load from your **CODE workspace**:

| Pipeline | What it does |
|---|---|
| `PL_FMD_LOAD_ALL` | Full end-to-end run: Landing Zone → Bronze → Silver |
| `PL_FMD_LOAD_LANDINGZONE` | Only extract from Azure SQL to Landing Zone (Parquet files) |
| `PL_FMD_LOAD_BRONZE` | Only Landing Zone → Bronze (Delta, deduplication) |
| `PL_FMD_LOAD_SILVER` | Only Bronze → Silver (SCD Type 2 history) |

For the first run, use **`PL_FMD_LOAD_ALL`**.

---

## Incremental vs Full load behaviour

| Setting | Behaviour |
|---|---|
| `@IsIncremental = 0` | Full table reload every run. Previous data in Bronze and Silver is replaced. |
| `@IsIncremental = 1` | Only rows where `IsIncrementalColumn > LastLoadValue` are extracted. The watermark is updated automatically after each successful run in `execution.LandingzoneEntityLastLoadValue`. |

---

## Verifying the result

After the pipeline completes, query the Silver lakehouse table in your DATA workspace:

```sql
-- In the Fabric SQL analytics endpoint for LH_SILVER_LAYER
SELECT TOP 100 * FROM dbo.Customer;
```

Check audit logs in the config database:

```sql
-- Pipeline execution history
SELECT TOP 50 *
FROM [logging].[vw_ExecutionSummary]
WHERE [EntityLayer] IN ('LandingZone', 'Bronze', 'Silver')
ORDER BY [StartDateTime] DESC;
```

---

## Disabling a table

To stop a table from being processed without deleting its history, set `@IsActive = 0` on the individual entity:

```sql
-- Deactivate a landing zone entity (stops all downstream processing too)
UPDATE [integration].[LandingzoneEntity]
SET    [IsActive] = 0
WHERE  [SourceSchema] = 'dbo'
AND    [SourceName]   = 'Customer';
```

---

## Related resources

- [FMD Framework Deployment Guide](FMD_FRAMEWORK_DEPLOYMENT.md)
- [FMD Business Domain Deployment Guide](FMD_BUSINESS_DOMAIN_DEPLOYMENT.md)
- [FMD Framework website](https://erwindekreuk.com/fmd-framework/)
- [FMD Framework wiki](https://github.com/edkreuk/FMD_FRAMEWORK/wiki)
