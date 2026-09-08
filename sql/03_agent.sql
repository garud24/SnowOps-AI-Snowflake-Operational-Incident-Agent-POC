-- SnowOps AI POC
-- 03_agent.sql
-- Creates the base Cortex Agent with a structured-data Analyst tool.
--
-- Note: Cortex Agents may require account-level access beyond a trial account.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SNOWOPS_WH;
USE DATABASE SNOWOPS_DB;
USE SCHEMA OPERATIONS;


GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER
TO ROLE ACCOUNTADMIN;

GRANT CREATE AGENT
ON SCHEMA SNOWOPS_DB.OPERATIONS
TO ROLE ACCOUNTADMIN;

GRANT USAGE
ON WAREHOUSE SNOWOPS_WH
TO ROLE ACCOUNTADMIN;


CREATE OR REPLACE AGENT SNOWOPS_AGENT
    COMMENT = 'Operational AI agent for investigating pipeline failures'
    PROFILE = '{"display_name": "SnowOps Incident Agent"}'
    FROM SPECIFICATION
$$

models:
  orchestration: auto

instructions:
  response: "Answer concisely. Clearly distinguish observed operational evidence from recommended remediation."

  orchestration: "Use Operations_Analyst for all questions about pipelines, pipeline executions, failures, error messages, schema changes, and operational incidents."

  sample_questions:
    - question: "Which pipelines failed?"
    - question: "What error caused revenue_etl to fail?"
    - question: "What schema changes happened before the revenue_etl failure?"
    - question: "Investigate why revenue_etl failed."

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "Operations_Analyst"
      description: "Queries pipeline executions, failures, error messages, and schema changes using the SnowOps semantic view."

tool_resources:
  Operations_Analyst:
    semantic_view: "SNOWOPS_DB.OPERATIONS.SNOWOPS_SEMANTIC_VIEW"

$$;


-- Verification
SHOW AGENTS;
DESCRIBE AGENT SNOWOPS_AGENT;
