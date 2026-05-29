
CREATE PROCEDURE [execution].[sp_GetLandingzoneEntity]
(   @WorkspaceId UNIQUEIDENTIFIER
)
WITH EXECUTE AS CALLER
AS
BEGIN
    SET NOCOUNT ON;

    -- Returns a JSON array of landing zone entities scoped to the given workspace.
    -- Each element carries all fields required by PL_FMD_LDZ_COMMAND_* pipelines
    -- so that PL_FMD_LOAD_LANDINGZONE can fan-out via a ForEach activity.
    SELECT CONCAT(
        '[',
        STRING_AGG(
            CONCAT(
                CONVERT(NVARCHAR(MAX), '{'),
                '"EntityId"            : ', '"', LOWER(CONVERT(NVARCHAR(36), [EntityId])),           '"',
                ',"DataSourceId"       : ', '"', LOWER(CONVERT(NVARCHAR(36), [DataSourceId])),       '"',
                ',"DataSourceName"     : ', '"', REPLACE(REPLACE([DataSourceName],     '\', '\\'), '"', '\"'), '"',
                ',"DataSourceNamespace": ', '"', REPLACE(REPLACE([DataSourceNamespace],'\', '\\'), '"', '\"'), '"',
                ',"DataSourceType"     : ', '"', REPLACE(REPLACE([DataSourceType],     '\', '\\'), '"', '\"'), '"',
                ',"ConnectionType"     : ', '"', REPLACE(REPLACE([ConnectionType],     '\', '\\'), '"', '\"'), '"',
                ',"ConnectionGuid"     : ', '"', LOWER(CONVERT(NVARCHAR(36), [ConnectionGuid])),     '"',
                ',"SourceSchema"       : ', '"', REPLACE(REPLACE([SourceSchema],       '\', '\\'), '"', '\"'), '"',
                ',"SourceName"         : ', '"', REPLACE(REPLACE([SourceName],         '\', '\\'), '"', '\"'), '"',
                ',"TargetFilePath"     : ', '"', REPLACE(REPLACE([TargetFilePath],     '\', '\\'), '"', '\"'), '"',
                ',"TargetFileName"     : ', '"', REPLACE(REPLACE([TargetFileName],     '\', '\\'), '"', '\"'), '"',
                ',"TargetFileType"     : ', '"', REPLACE(REPLACE([TargetFileType],     '\', '\\'), '"', '\"'), '"',
                ',"TargetLakehouseGuid": ', '"', LOWER(CONVERT(NVARCHAR(36), [TargetLakehouseGuid])),'"',
                ',"WorkspaceGuid"      : ', '"', LOWER(CONVERT(NVARCHAR(36), [WorkspaceGuid])),      '"',
                ',"IsIncremental"      : ', '"', CASE WHEN [IsIncremental] = 1 THEN 'True' ELSE 'False' END, '"',
                ',"IsIncrementalColumn": ', '"', ISNULL(REPLACE(REPLACE([IsIncrementalColumn], '\', '\\'), '"', '\"'), ''), '"',
                ',"LastLoadValue"      : ', '"', ISNULL(REPLACE(REPLACE([LastLoadValue],       '\', '\\'), '"', '\"'), ''), '"',
                ',"SourceDataRetrieval": ', '"', ISNULL(REPLACE(REPLACE([SourceDataRetrieval], '\', '\\'), '"', '\"'), ''), '"',
                ',"CustomNotebookName" : ', '"', ISNULL(REPLACE(REPLACE([CustomNotebookName],  '\', '\\'), '"', '\"'), ''), '"',
                '}'
            ),
            ','
        ) WITHIN GROUP (ORDER BY [EntityId]),
        ']'
    ) AS PipelineParams
    FROM [execution].[vw_LoadSourceToLandingzone]
    WHERE [WorkspaceGuid] = @WorkspaceId;

    SET NOCOUNT OFF;
END

GO

