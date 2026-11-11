-- Starting script for the Vanguard Auto Shop feedback engine.
-- Column names and types match the Supabase project this workflow was built on.
-- The primary keys and default values below are common choices, not an export of the original.
-- Review them, and turn on row level security before you store any real customer data.

create table customers (
  id uuid primary key default gen_random_uuid(),
  name varchar,
  email varchar,
  branch_location varchar,
  has_previous_negative boolean default false,
  created_at timestamptz default now()
);

create table jobs (
  id uuid primary key default gen_random_uuid(),
  customer_name text,
  customer_email text,
  branch_location text,
  service_type text,
  service_description text,
  staff_name text,
  status text,
  email_sent boolean default false,
  created_at timestamptz default now()
);

create table feedback (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers (id),
  job_id text,
  branch_location varchar,
  raw_feedback_text text,
  sentiment_score integer,
  severity_score integer,
  status varchar,
  ai_draft_response text,
  response_sent boolean default false,
  alert_status varchar,
  is_repeat_customer boolean default false,
  created_at timestamptz default now()
);
