# Database tables

These are the tables in the Supabase project, with column types read from the database. The `Used by the workflow` column shows what the n8n workflow does with each column.

Do not put real customer data in this repository. Use made-up sample data for testing.

## customers

| Column | Type | Used by the workflow |
|---|---|---|
| `id` | uuid | Customer ID, used by other tables |
| `name` | character varying | Customer name |
| `email` | character varying | Used to find an existing customer |
| `branch_location` | character varying | Branch the customer visited |
| `has_previous_negative` | boolean | Set to true after a negative feedback, so later complaints are escalated |
| `created_at` | timestamp with time zone | Used to pick the latest matching customer |

## jobs

| Column | Type | Used by the workflow |
|---|---|---|
| `id` | uuid | Job ID, sent in the feedback link |
| `customer_name` | text | Customer name |
| `customer_email` | text | Where the feedback request is sent |
| `branch_location` | text | Branch |
| `service_type` | text | Type of service |
| `service_description` | text | What was done |
| `staff_name` | text | Staff member who did the job |
| `status` | text | Not used by this workflow |
| `email_sent` | boolean | Set to true after the feedback request is sent |
| `created_at` | timestamp with time zone | Not used by this workflow |

## feedback

| Column | Type | Used by the workflow |
|---|---|---|
| `id` | uuid | Feedback ID, used by the dashboard and the reply webhook |
| `customer_id` | uuid | Links to `customers.id` |
| `job_id` | text | The job ID that came with the feedback form |
| `branch_location` | character varying | Branch |
| `raw_feedback_text` | text | What the customer wrote |
| `sentiment_score` | integer | From -10 to 10, from Gemini |
| `severity_score` | integer | From 1 to 5, from Gemini |
| `status` | character varying | `READY_TO_POST`, `PRIVATE_QUEUE`, `ESCALATED_MANAGER`, or `FLAGGED_HUMAN_REVIEW` |
| `ai_draft_response` | text | Draft reply for a person to edit and approve |
| `response_sent` | boolean | Set to true after the reply is emailed |
| `alert_status` | character varying | `OPEN` for manager escalations, then `RESOLVED` |
| `is_repeat_customer` | boolean | True if the customer had a past negative feedback |
| `created_at` | timestamp with time zone | When the feedback was saved |

Note: `feedback.job_id` is stored as text, while `jobs.id` is a uuid. They hold the same value, but because the types differ, they cannot be linked with a foreign key.

A starting script to create these tables is in [schema.sql](schema.sql).
