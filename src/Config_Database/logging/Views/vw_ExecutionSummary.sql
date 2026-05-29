
CREATE VIEW [logging].[vw_ExecutionSummary]
AS
-- Unified execution summary across Pipeline, Notebook, and Copy Activity audit logs.
-- Each row represents one completed unit of work (START + END/FAIL pair resolved).
-- Use this view to build observability dashboards or feed alerting logic.

-- Pipeline executions
SELECT
    pe_start.[WorkspaceGuid],
    pe_start.[PipelineRunGuid]                          AS [RunGuid],
    pe_start.[PipelineParentRunGuid]                    AS [ParentRunGuid],
    'Pipeline'                                          AS [ExecutionType],
    pe_start.[PipelineName]                             AS [ObjectName],
    pe_start.[EntityId],
    pe_start.[EntityLayer],
    pe_start.[TriggerType],
    pe_start.[TriggerTime],
    pe_start.[LogDateTime]                              AS [StartDateTime],
    COALESCE(pe_end.[LogDateTime], pe_fail.[LogDateTime]) AS [EndDateTime],
    DATEDIFF(SECOND, pe_start.[LogDateTime],
        COALESCE(pe_end.[LogDateTime], pe_fail.[LogDateTime])) AS [DurationSeconds],
    CASE
        WHEN pe_fail.[LogType] IS NOT NULL THEN 'Failed'
        WHEN pe_end.[LogType]  IS NOT NULL THEN 'Succeeded'
        ELSE 'Running'
    END                                                 AS [Status],
    COALESCE(pe_fail.[LogData], pe_end.[LogData])       AS [LogData]
FROM [logging].[PipelineExecution] pe_start
LEFT JOIN [logging].[PipelineExecution] pe_end
    ON  pe_end.[PipelineRunGuid] = pe_start.[PipelineRunGuid]
    AND pe_end.[LogType] = 'End'
LEFT JOIN [logging].[PipelineExecution] pe_fail
    ON  pe_fail.[PipelineRunGuid] = pe_start.[PipelineRunGuid]
    AND pe_fail.[LogType] = 'Fail'
WHERE pe_start.[LogType] = 'Start'

UNION ALL

-- Notebook executions
SELECT
    ne_start.[WorkspaceGuid],
    ne_start.[PipelineRunGuid]                          AS [RunGuid],
    ne_start.[PipelineParentRunGuid]                    AS [ParentRunGuid],
    'Notebook'                                          AS [ExecutionType],
    ne_start.[NotebookName]                             AS [ObjectName],
    ne_start.[EntityId],
    ne_start.[EntityLayer],
    ne_start.[TriggerType],
    ne_start.[TriggerTime],
    ne_start.[LogDateTime]                              AS [StartDateTime],
    COALESCE(ne_end.[LogDateTime], ne_fail.[LogDateTime]) AS [EndDateTime],
    DATEDIFF(SECOND, ne_start.[LogDateTime],
        COALESCE(ne_end.[LogDateTime], ne_fail.[LogDateTime])) AS [DurationSeconds],
    CASE
        WHEN ne_fail.[LogType] IS NOT NULL THEN 'Failed'
        WHEN ne_end.[LogType]  IS NOT NULL THEN 'Succeeded'
        ELSE 'Running'
    END                                                 AS [Status],
    COALESCE(ne_fail.[LogData], ne_end.[LogData])       AS [LogData]
FROM [logging].[NotebookExecution] ne_start
LEFT JOIN [logging].[NotebookExecution] ne_end
    ON  ne_end.[PipelineRunGuid] = ne_start.[PipelineRunGuid]
    AND ne_end.[NotebookName]    = ne_start.[NotebookName]
    AND ne_end.[LogType] = 'End'
LEFT JOIN [logging].[NotebookExecution] ne_fail
    ON  ne_fail.[PipelineRunGuid] = ne_start.[PipelineRunGuid]
    AND ne_fail.[NotebookName]    = ne_start.[NotebookName]
    AND ne_fail.[LogType] = 'Fail'
WHERE ne_start.[LogType] = 'Start'

UNION ALL

-- Copy Activity executions
SELECT
    ca_start.[WorkspaceGuid],
    ca_start.[PipelineRunGuid]                          AS [RunGuid],
    ca_start.[PipelineParentRunGuid]                    AS [ParentRunGuid],
    'CopyActivity'                                      AS [ExecutionType],
    ca_start.[CopyActivityName]                         AS [ObjectName],
    ca_start.[EntityId],
    ca_start.[EntityLayer],
    ca_start.[TriggerType],
    ca_start.[TriggerTime],
    ca_start.[LogDateTime]                              AS [StartDateTime],
    COALESCE(ca_end.[LogDateTime], ca_fail.[LogDateTime]) AS [EndDateTime],
    DATEDIFF(SECOND, ca_start.[LogDateTime],
        COALESCE(ca_end.[LogDateTime], ca_fail.[LogDateTime])) AS [DurationSeconds],
    CASE
        WHEN ca_fail.[LogType] IS NOT NULL THEN 'Failed'
        WHEN ca_end.[LogType]  IS NOT NULL THEN 'Succeeded'
        ELSE 'Running'
    END                                                 AS [Status],
    COALESCE(ca_fail.[LogData], ca_end.[LogData])       AS [LogData]
FROM [logging].[CopyActivityExecution] ca_start
LEFT JOIN [logging].[CopyActivityExecution] ca_end
    ON  ca_end.[PipelineRunGuid]    = ca_start.[PipelineRunGuid]
    AND ca_end.[CopyActivityName]   = ca_start.[CopyActivityName]
    AND ca_end.[LogType] = 'End'
LEFT JOIN [logging].[CopyActivityExecution] ca_fail
    ON  ca_fail.[PipelineRunGuid]   = ca_start.[PipelineRunGuid]
    AND ca_fail.[CopyActivityName]  = ca_start.[CopyActivityName]
    AND ca_fail.[LogType] = 'Fail'
WHERE ca_start.[LogType] = 'Start'

GO

