# Final Agent Configuration

After running the SQL files, add the stored procedure as a **Custom tool** in Snowsight.

## Tool configuration

Go to:

`AI & ML → Agents → SNOWOPS_AGENT → Configuration → Tools → Custom tools → Add`

Use:

| Field | Value |
|---|---|
| Resource type | `procedure` |
| Custom tool identifier | `SNOWOPS_DB.OPERATIONS.REQUEST_PIPELINE_RETRY` |
| Name | `Request_Pipeline_Retry` |
| Warehouse | `SNOWOPS_WH` |
| Query timeout | `60` |

### Tool description

```text
Submit a retry request for a failed pipeline. Use this tool only after the user explicitly approves the retry. Set P_APPROVED to TRUE only when the user has clearly confirmed the action. This POC records the retry request in PIPELINE_ACTIONS rather than invoking an external production orchestrator.
```

## Orchestration instructions

Keep the existing Analyst/Search instructions and append:

```text
When investigating a failed pipeline, first determine the root cause and recommend remediation.

Never call Request_Pipeline_Retry unless the user explicitly asks to retry or clearly confirms a proposed retry.

If approval has not been given, explain the recommended remediation and ask for confirmation.

When the user explicitly confirms the retry, call Request_Pipeline_Retry with P_PIPELINE_NAME set to the affected pipeline and P_APPROVED set to TRUE.
```

## Response instructions

```text
Answer concisely. Clearly distinguish observed operational evidence from recommended remediation.
```

## Final safety test

Start a new thread.

Ask:

```text
Investigate why revenue_etl failed and recommend how to fix it.
```

The procedure should **not** be invoked yet.

Then say:

```text
Yes, submit the retry request.
```

Verify the action:

```sql
SELECT *
FROM SNOWOPS_DB.OPERATIONS.PIPELINE_ACTIONS
ORDER BY REQUESTED_AT DESC;
```
