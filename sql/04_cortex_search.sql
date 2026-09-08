-- SnowOps AI POC
-- 04_cortex_search.sql
-- Adds unstructured operational runbooks and Cortex Search.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SNOWOPS_WH;
USE DATABASE SNOWOPS_DB;
USE SCHEMA OPERATIONS;


GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER
TO ROLE ACCOUNTADMIN;


CREATE OR REPLACE TABLE OPERATION_RUNBOOKS (
    DOC_ID VARCHAR,
    TITLE VARCHAR,
    CATEGORY VARCHAR,
    CONTENT VARCHAR
);


INSERT INTO OPERATION_RUNBOOKS VALUES

(
    'RB001',
    'Schema Drift Recovery',
    'SCHEMA_DRIFT',
    'When a pipeline fails because of an invalid column identifier, first inspect recent upstream schema changes. If a referenced column was renamed, update the downstream transformation or mapping to use the new column name. Validate the query before restarting the pipeline. Once validation succeeds, retry the failed pipeline and confirm downstream datasets are healthy.'
),

(
    'RB002',
    'Warehouse Timeout Recovery',
    'WAREHOUSE_TIMEOUT',
    'When a pipeline fails because of a warehouse timeout, inspect warehouse utilization and query duration. Resume or resize the warehouse when appropriate, validate that sufficient compute is available, and retry the pipeline. Confirm that processing completes successfully.'
),

(
    'RB003',
    'Data Quality Failure Recovery',
    'DATA_QUALITY',
    'When a pipeline fails due to null values, duplicates, or invalid records, inspect the affected source data and validation rules. Isolate problematic records, correct the data quality issue, rerun validation checks, and retry the pipeline only after the checks pass.'
);


CREATE OR REPLACE CORTEX SEARCH SERVICE SNOWOPS_RUNBOOK_SEARCH

ON CONTENT

PRIMARY KEY (DOC_ID)

ATTRIBUTES CATEGORY

WAREHOUSE = SNOWOPS_WH

TARGET_LAG = '1 day'

AUTO_SUSPEND = 1800

AS
SELECT
    DOC_ID,
    TITLE,
    CATEGORY,
    CONTENT
FROM OPERATION_RUNBOOKS;


-- Verify the service.
SHOW CORTEX SEARCH SERVICES;

SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'SNOWOPS_DB.OPERATIONS.SNOWOPS_RUNBOOK_SEARCH',
    '{
        "query": "pipeline failed because a column was renamed",
        "columns": ["DOC_ID", "TITLE", "CATEGORY", "CONTENT"],
        "limit": 3
    }'
);


-- Replace the live specification with Analyst + Search.
ALTER AGENT SNOWOPS_AGENT
MODIFY LIVE VERSION SET SPECIFICATION =
$$

models:
  orchestration: auto

instructions:
  response: "Answer concisely. Clearly distinguish observed operational evidence from recommended remediation."

  orchestration: "Use Operations_Analyst for questions about pipelines, executions, failures, error messages, timestamps, and schema changes. Use Runbook_Search for troubleshooting procedures and remediation guidance. For root-cause investigations, use both tools when appropriate."

  sample_questions:
    - question: "Which pipelines failed?"
    - question: "Why did revenue_etl fail?"
    - question: "What schema change happened before the failure?"
    - question: "How should I fix the revenue_etl failure?"

tools:

  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "Operations_Analyst"
      description: "Queries pipeline executions, failures, error messages, and schema changes."

  - tool_spec:
      type: "cortex_search"
      name: "Runbook_Search"
      description: "Searches operational runbooks for troubleshooting procedures and recommended remediation."

tool_resources:

  Operations_Analyst:
    semantic_view: "SNOWOPS_DB.OPERATIONS.SNOWOPS_SEMANTIC_VIEW"

  Runbook_Search:
    search_service: "SNOWOPS_DB.OPERATIONS.SNOWOPS_RUNBOOK_SEARCH"
    max_results: "3"
    title_column: "TITLE"
    id_column: "DOC_ID"

    columns_and_descriptions:

      CONTENT:
        description: "Troubleshooting and remediation instructions from operational runbooks."
        type: "string"
        searchable: true
        filterable: false

      CATEGORY:
        description: "Runbook incident category."
        type: "string"
        searchable: false
        filterable: true

      TITLE:
        description: "Human-readable title of the operational runbook."
        type: "string"
        searchable: false
        filterable: false

$$;
