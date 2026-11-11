# Vanguard Auto Shop: Customer Feedback and Reputation Engine

An n8n system that asks customers for feedback after a service visit, scores each reply with Google Gemini, and sends every reply to the right person: a public-review queue, a private reply queue, a manager, or a human reviewer. A person approves every reply before it is sent.

I built this as my capstone project at TS Academy. Vanguard Auto Shop is a case study from the course, and all data in this project is sample data.

![Workflow canvas](<img width="1411" height="621" alt="canvas png" src="https://github.com/user-attachments/assets/21dea700-bf46-4dbf-9d38-a7af098383ae" />
)
![Dashboard](<img width="1763" height="823" alt="dashboard png" src="https://github.com/user-attachments/assets/80431ad3-2ffc-4d3e-9a86-04dbd290fe24" />
)

## The problem

An auto shop gets customer feedback in many places and in many moods. Happy customers should be asked to post a public review. Unhappy customers need a quick, polite reply. Serious problems should reach a manager fast. Replies the AI cannot judge should go to a person. Doing this by hand is slow, and easy to get wrong.

## What it does

1. **A job is completed.** A staff form sends the job details to n8n. The workflow saves the job, waits 20 seconds, and emails the customer a feedback link that carries the job ID.
2. **The customer sends feedback.** The feedback form sends the reply to n8n. The workflow finds the customer by email, or creates a new customer record.
3. **Gemini scores the reply.** It returns a sentiment score from -10 to +10, a severity score from 1 to 5, a suggested status, and a draft reply if the feedback is negative.
4. **Routing rules decide where it goes** (see the table below). The feedback is saved in Supabase.
5. **A manager reviews it in a dashboard** (built in Lovable, not included in this repo). They edit the AI draft, approve it, and send it.
6. **The reply is emailed to the customer.** The feedback is marked as answered, and any open manager alert is marked resolved.
7. **Error alert.** A separate n8n workflow, set as this workflow's Error Workflow, sends a Telegram message with the workflow name, the failed node, the error, and the time whenever a step fails.

## Routing rules

| Status | When it is used | Alert |
|---|---|---|
| `READY_TO_POST` | Gemini says the feedback is positive, the sentiment score is above 2, and it is not ambiguous. A repeat customer with a past complaint still gets this if the new feedback is truly positive. | Resolved |
| `FLAGGED_HUMAN_REVIEW` | Gemini cannot tell if the feedback is positive or negative | Resolved |
| `ESCALATED_MANAGER` | The customer has complained before, or severity is 4 or 5, or Gemini suggests escalation | Open |
| `PRIVATE_QUEUE` | Everything else, for example a first-time mild complaint | Resolved |

When a customer's feedback is negative (`PRIVATE_QUEUE` or `ESCALATED_MANAGER`), the customer record is flagged, so later complaints are escalated.

## Design choices

- **Human in control.** The AI writes a draft. A person edits and approves it before anything is sent.
- **Strict AI output.** The prompt asks for a fixed JSON format. A Code node cleans the reply and applies the routing rules, so the decisions are written down in code and not left to the AI alone.
- **Complaints cannot be hidden by praise.** The prompt tells Gemini to treat feedback as negative if it describes a real problem, even when the customer is polite about staff.
- **Memory in the database, not the AI.** Whether a customer has complained before is stored in Supabase, so Gemini never has to guess about past visits.
- **Error alerts in a separate workflow.** A small workflow with an Error Trigger node sends a Telegram message when this one fails, so a broken step does not go unnoticed.

## Tools

- n8n
- Supabase (database)
- Google Gemini (sentiment scoring and draft replies)
- Gmail (feedback requests and replies)
- Fillout (staff and customer forms)
- Lovable (manager dashboard)
- Telegram (error alerts)

## Set it up

### 1. Import the workflow

In n8n, create a new workflow and choose **Import from file**. Pick `workflows/vanguard-auto-shop-feedback-engine.json`.

### 2. Connect your accounts

Add credentials for **Supabase**, **Gmail**, and **Google Gemini**. The export contains no credentials.

### 3. Make the database

Create three tables in Supabase: `customers`, `jobs`, and `feedback`. The columns and types are in [database/schema.md](database/schema.md), and a starting script is in [database/schema.sql](database/schema.sql).

### 4. Add your own values

- In the **Send Feedback Request Email** node, replace `YOUR_FORM_ID` in the link with your feedback form ID.
- Check the model in the **Google Gemini Chat Model** node, and pick a current Flash model.

### 5. Connect the forms

The workflow has three webhooks. Point each one to the right sender:

| Webhook path | Sent by | Fields, in this order |
|---|---|---|
| `vanguard-jobcompleted` | Staff form when a job is done | Customer name, email, branch, service type, service description, staff name |
| `vanguard-feedback` | Customer feedback form | Name, email, branch, feedback text, job ID |
| `vanguard-response` | The manager dashboard | `customer_email`, `response_text`, `feedback_id` |

The form fields must follow this order, because the workflow reads them by position.

### 6. Set up error alerts (optional)

Make a separate workflow with an **Error Trigger** node followed by a **Telegram** node that sends you the workflow name, the failed node, and the error. Then open this workflow's **Settings** and choose that workflow under **Error Workflow**. The error workflow is not part of this export.

### 7. Test with sample data

Use made-up customers only. This workflow handles names and email addresses.

## Limits

- If Gemini's reply cannot be read, the workflow falls back to a default: private queue, sentiment -2, severity 2, and no draft. A person should check anything that looks wrong.
- The workflow reads form answers by position, so changing the order of the form questions breaks it.
- Sentiment scoring is a guide for a person. It is not a final judgment.
- The wait before the feedback email is 20 seconds. A real shop would likely wait longer before asking for feedback.
- The dashboard is not included here.
- Turn on row level security in Supabase before you store any real customer data.

## Files

- `workflows/vanguard-auto-shop-feedback-engine.json`: the workflow, with private details removed
- `database/schema.md`: the tables, columns, and types
- `database/schema.sql`: a starting script to create the tables
- `images/`: screenshots of the canvas and the dashboard
