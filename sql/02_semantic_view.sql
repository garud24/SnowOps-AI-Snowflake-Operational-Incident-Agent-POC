-- SnowOps AI POC
-- 02_semantic_view.sql
-- Adds business semantics used by Cortex Analyst / Cortex Agents.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SNOWOPS_WH;
USE DATABASE SNOWOPS_DB;
USE SCHEMA OPERATIONS;


CREATE OR REPLACE SEMANTIC VIEW SNOWOPS_SEMANTIC_VIEW

TABLES (

    pipelines AS SNOWOPS_DB.OPERATIONS.PIPELINES
        PRIMARY KEY (PIPELINE_ID)
        COMMENT = 'One row represents one operational data pipeline',

    pipeline_runs AS SNOWOPS_DB.OPERATIONS.PIPELINE_RUNS
        PRIMARY KEY (RUN_ID)
        COMMENT = 'Execution history of operational pipelines including failures and errors',

    schema_changes AS SNOWOPS_DB.OPERATIONS.SCHEMA_CHANGES
        PRIMARY KEY (CHANGE_ID)
        COMMENT = 'Schema modifications that may affect operational pipelines'

)

RELATIONSHIPS (

    pipeline_run_to_pipeline AS
        pipeline_runs (PIPELINE_ID)
        REFERENCES pipelines (PIPELINE_ID)

)

DIMENSIONS (

    pipelines.pipeline_name AS PIPELINE_NAME
        WITH SYNONYMS = ('pipeline', 'job', 'workflow')
        COMMENT = 'Name of the operational pipeline',

    pipelines.owner_team AS OWNER_TEAM
        COMMENT = 'Team responsible for the pipeline',

    pipelines.pipeline_status AS PIPELINE_STATUS
        COMMENT = 'Current state of the pipeline',

    pipeline_runs.run_id AS RUN_ID
        COMMENT = 'Unique pipeline execution identifier',

    pipeline_runs.run_status AS RUN_STATUS
        WITH SYNONYMS = ('execution status', 'job status')
        COMMENT = 'Whether a pipeline execution succeeded or failed',

    pipeline_runs.start_time AS START_TIME
        COMMENT = 'Time when pipeline execution started',

    pipeline_runs.end_time AS END_TIME
        COMMENT = 'Time when pipeline execution completed',

    pipeline_runs.error_message AS ERROR_MESSAGE
        WITH SYNONYMS = ('error', 'failure reason', 'exception')
        COMMENT = 'Error generated when a pipeline execution fails',

    pipeline_runs.rows_processed AS ROWS_PROCESSED
        COMMENT = 'Number of records processed during execution',

    schema_changes.change_id AS CHANGE_ID
        COMMENT = 'Unique identifier of a schema change',

    schema_changes.table_name AS TABLE_NAME
        COMMENT = 'Database table affected by a schema change',

    schema_changes.column_name AS COLUMN_NAME
        COMMENT = 'Column affected by a schema change',

    schema_changes.change_type AS CHANGE_TYPE
        WITH SYNONYMS = ('schema modification', 'schema update')
        COMMENT = 'Type of schema modification',

    schema_changes.old_value AS OLD_VALUE
        COMMENT = 'Value or name before the schema change',

    schema_changes.new_value AS NEW_VALUE
        COMMENT = 'Value or name after the schema change',

    schema_changes.change_time AS CHANGE_TIME
        COMMENT = 'Time when the schema modification occurred'

)

COMMENT = 'Semantic model for investigating pipeline failures and operational incidents';


-- Verification
SHOW SEMANTIC VIEWS;
DESCRIBE SEMANTIC VIEW SNOWOPS_SEMANTIC_VIEW;

SELECT *
FROM SEMANTIC_VIEW(
    SNOWOPS_SEMANTIC_VIEW
    DIMENSIONS
        pipelines.pipeline_name,
        pipeline_runs.run_status,
        pipeline_runs.error_message,
        pipeline_runs.start_time
);

SELECT *
FROM SEMANTIC_VIEW(
    SNOWOPS_SEMANTIC_VIEW
    DIMENSIONS
        schema_changes.table_name,
        schema_changes.column_name,
        schema_changes.change_type,
        schema_changes.old_value,
        schema_changes.new_value,
        schema_changes.change_time
);
