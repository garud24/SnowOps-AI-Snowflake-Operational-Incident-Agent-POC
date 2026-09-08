-- SnowOps AI POC
-- 05_action_tool.sql
-- Creates the auditable retry-request action and its safety guard.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SNOWOPS_WH;
USE DATABASE SNOWOPS_DB;
USE SCHEMA OPERATIONS;


CREATE OR REPLACE TABLE PIPELINE_ACTIONS (
    ACTION_ID VARCHAR,
    PIPELINE_NAME VARCHAR,
    ACTION_TYPE VARCHAR,
    ACTION_STATUS VARCHAR,
    REQUESTED_AT TIMESTAMP_NTZ,
    DETAILS VARCHAR
);


CREATE OR REPLACE PROCEDURE REQUEST_PIPELINE_RETRY(
    P_PIPELINE_NAME VARCHAR,
    P_APPROVED BOOLEAN
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    PIPELINE_COUNT INTEGER;
    FAILED_COUNT INTEGER;
BEGIN

    -- Independent human-approval guard.
    IF (P_APPROVED IS NULL OR P_APPROVED = FALSE) THEN
        RETURN 'NOT EXECUTED: Explicit user approval is required before requesting a retry.';
    END IF;


    -- Validate that the requested pipeline exists.
    SELECT COUNT(*)
    INTO :PIPELINE_COUNT
    FROM PIPELINES
    WHERE LOWER(PIPELINE_NAME) = LOWER(:P_PIPELINE_NAME);


    IF (PIPELINE_COUNT = 0) THEN
        RETURN 'ERROR: Pipeline ' || P_PIPELINE_NAME || ' does not exist.';
    END IF;


    -- Validate that the pipeline actually has a failed execution.
    SELECT COUNT(*)
    INTO :FAILED_COUNT
    FROM PIPELINES P
    JOIN PIPELINE_RUNS R
        ON P.PIPELINE_ID = R.PIPELINE_ID
    WHERE LOWER(P.PIPELINE_NAME) = LOWER(:P_PIPELINE_NAME)
      AND R.RUN_STATUS = 'FAILED';


    IF (FAILED_COUNT = 0) THEN
        RETURN 'NOT EXECUTED: Pipeline ' ||
               P_PIPELINE_NAME ||
               ' has no failed executions.';
    END IF;


    -- POC action:
    -- record a retry request rather than calling a real external orchestrator.
    INSERT INTO PIPELINE_ACTIONS (
        ACTION_ID,
        PIPELINE_NAME,
        ACTION_TYPE,
        ACTION_STATUS,
        REQUESTED_AT,
        DETAILS
    )
    SELECT
        UUID_STRING(),
        :P_PIPELINE_NAME,
        'RETRY_PIPELINE',
        'REQUESTED',
        CURRENT_TIMESTAMP(),
        'Retry requested through SnowOps Cortex Agent POC';


    RETURN 'SUCCESS: Retry request submitted for pipeline ' ||
           P_PIPELINE_NAME || '.';

END;
$$;


GRANT USAGE
ON PROCEDURE SNOWOPS_DB.OPERATIONS.REQUEST_PIPELINE_RETRY(VARCHAR, BOOLEAN)
TO ROLE ACCOUNTADMIN;


-- Safety test: should not create a row.
CALL REQUEST_PIPELINE_RETRY(
    'revenue_etl',
    FALSE
);


-- Optional manual positive test.
-- Comment this out if you want the Agent invocation to create the first row.
-- CALL REQUEST_PIPELINE_RETRY(
--     'revenue_etl',
--     TRUE
-- );


SELECT *
FROM PIPELINE_ACTIONS
ORDER BY REQUESTED_AT DESC;
