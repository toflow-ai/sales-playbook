# toflow Sales Skills

AI-native sales skills and commands for Claude, built on toflow.ai as the primary data source. All skills pull live data from toflow — CRM records, enrichment, email, LinkedIn, sequences, and pipeline analytics.

## Skills (auto-triggered by Claude)

| Skill | Trigger Examples | Primary toflow Tools |
|-------|-----------------|---------------------|
| `account-research` | "research Acme", "look up John at TechCorp" | `enrich_person_by_linkedin`, `get_person`, `get_company`, `list_notes` |
| `draft-outreach` | "draft email to VP Sales at Notion", "reach out to [LinkedIn URL]" | `inbox_manager_config`, `draft_email`, `send_connection_request`, `enroll_in_sequence` |
| `call-prep` | "prep me for my call with Stripe", "get me ready for this meeting" | `get_deal`, `list_notes`, `list_emails`, `list_message_threads`, `list_tasks` |
| `daily-briefing` | "morning briefing", "what's on my plate today" | `list_records`, `list_tasks`, `list_emails`, `list_message_threads` |
| `sequence-builder` | "build a sequence", "create outreach for SDR personas" | `get_sequence_schema`, `list_connected_accounts`, `create_sequence`, `enroll_in_sequence` |
| `competitive-intelligence` | "how do we compare to Outreach", "battlecard for Apollo" | `list_records` (won/lost), `list_notes`, web search |
| `icp-qualifier` | "qualify this prospect", "score this lead" | `enrich_person_by_linkedin`, `get_person`, `update_record` |

## Commands (slash-invoked)

| Command | What It Does | Primary toflow Tools |
|---------|-------------|---------------------|
| `/call-summary` | Log a call, update deal, create tasks, draft follow-up | `create_note`, `update_record`, `create_task`, `draft_email` |
| `/pipeline-review` | Live pipeline health check + prioritized action plan | `list_records`, `list_stages`, `run_report` |
| `/forecast` | Weighted forecast with commit/upside + gap analysis | `list_records`, `run_report` (Deals dataset) |

## How Skills and Commands Work Together

```
Morning:
  → "daily briefing" — what's urgent, what's on my calendar

Before a call:
  → "call prep Stripe" — pull deal + history + agenda

After a call:
  → "/call-summary [notes]" — log + update deal + draft follow-up

New prospect:
  → "research [LinkedIn URL]" — enrich + ICP score
  → "qualify this prospect" — full ICP score with recommendation
  → "draft outreach to [name]" — personalized email + LinkedIn message

New campaign:
  → "build a sequence for SDR hiring managers" — design + create in toflow

Weekly:
  → "/pipeline-review" — flag risks + get action plan
  → "/forecast Q2" — weighted scenarios + gap analysis
```

## toflow Tool Reference

### CRM
- `record_schema(resource_type)` — field schema for person/company/deal
- `filter_guide()` — filter/sort syntax for list_records
- `list_records` — query CRM with filters
- `create_record` / `update_record` — create or update CRM records
- `get_person` / `get_company` / `get_deal` — get specific records

### Enrichment
- `enrich_person_by_linkedin(linkedin_url)` — full profile from LinkedIn URL
- `enrich_person_email(person_id)` — find email address
- `enrich_person_phone(person_id)` — find phone number
- `get_person_enrichment_status(task_id)` — poll if enrichment times out

### Email
- `inbox_manager_config()` — workspace email rules (always call before drafting)
- `list_connected_accounts()` — available sender accounts
- `draft_email` — create email draft
- `send_email` — send (only after user confirms)
- `reply_to_email`, `forward_email` — thread management
- `list_emails`, `get_email`, `get_email_tracking` — email history

### LinkedIn
- `search_linkedin` — find people on LinkedIn
- `check_linkedin_connection` — check connection status before messaging
- `send_connection_request` — send LinkedIn connection
- `send_linkedin_message` — DM a connected person
- `send_inmail` — InMail a non-connected person
- `start_linkedin_conversation` — start a new thread
- `get_linkedin_person_posts` — get someone's recent posts

### WhatsApp
- `send_whatsapp_message` — send WhatsApp message
- `start_whatsapp_conversation` — start WhatsApp thread

### Sequences
- `get_sequence_schema()` — node types, template variables, scheduling rules
- `list_sequences` — existing sequences
- `create_sequence` — build a multi-step sequence
- `enroll_in_sequence` — enroll a person
- `list_enrollments` — enrollment status
- `update_enrollment` / `retry_enrollment` — manage enrollments

### Tasks
- `create_task` — create a follow-up task
- `list_tasks` — get tasks with filters
- `update_task` / `delete_task` — manage tasks

### Notes
- `create_note` — log a note to a deal/person/company
- `list_notes` — get notes
- `update_note` / `delete_note` — manage notes

### Reports & Analytics
- `list_datasets()` — available datasets (Deals, Emails, Messages)
- `validate_and_preview_report` — preview before running
- `run_report` — execute report query

### Lists & Views
- `get_all_lists`, `create_list` — CRM lists
- `add_people_to_list`, `add_companies_to_list` — add records to lists
- `get_list_items`, `remove_from_list` — manage list membership
- `list_views`, `create_view`, `get_view` — saved views

## Golden Rules (from toflow MCP)

1. Always call `record_schema(resource_type)` before creating/updating CRM records
2. Always call `filter_guide()` before using `list_records` with filters
3. Always call `inbox_manager_config()` before drafting any email
4. Always show drafted content to the user before saving or sending
5. Always confirm before any destructive action (delete, close lost)
6. Never add email signatures — appended server-side automatically
7. Never enrich or message someone mid-sequence — check `LinkedIn Outreach Stage` first
