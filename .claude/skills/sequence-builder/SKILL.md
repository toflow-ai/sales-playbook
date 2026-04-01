---
name: sequence-builder
description: Design and create a multi-channel outreach sequence in toflow (email + LinkedIn + WhatsApp). Trigger with "build a sequence", "create a sequence for [persona/use case]", "set up outreach sequence", "automate follow-ups for [campaign]".
compatibility: Requires mcp__toflow tools
---

# Sequence Builder

Design a complete multi-channel sequence in toflow — email, LinkedIn, and WhatsApp steps with proper timing, personalization, and scheduling. Always asks for scheduling config before drafting content, always gets user approval before creating.

## Sequence Node Types Available

Pulled from `get_sequence_schema`. The available step types are:

| Node Type | What It Does |
|-----------|--------------|
| `email` | Send personalized email via connected inbox |
| `linkedin_connection_request` | Send LinkedIn connection request (with optional note) |
| `linkedin_message` | Send LinkedIn DM (must already be connected) |
| `whatsapp_message` | Send WhatsApp message |
| `create_task` | Create a task for a rep to take manual action |
| `check_linkedin_connection_status` | Branch: different path if connected vs. not connected |

Template variables available: `{{person.first_name}}`, `{{person.last_name}}`, `{{person.job_title}}`, `{{person.primary_location}}`, `{{company.name}}`, `{{company.website}}`, `{{workspace_member.first_name}}`, `{{workspace_member.last_name}}`, `{{workspace_member.name}}`

---

## Execution Flow

### Step 1: Gather Scheduling Config (MANDATORY — ask one by one)

Before drafting any content, collect:

1. **Timezone** — "What timezone should the sequence use?" (IANA string, e.g. `Asia/Kolkata`, `America/New_York`)
2. **Send window** — "What time window should messages be sent?" (e.g. 9am–6pm)
3. **Weekends** — "Should messages be sent on weekends?"
4. **Email threading** — "Should follow-up emails be threaded (replies in one thread) or fresh emails?"
5. **Skip dates** — "Any dates to skip? (holidays, blackout periods)"

Wait for all answers before proceeding.

### Step 2: Get Connected Accounts

```
list_connected_accounts()
→ Show user: available email accounts, LinkedIn accounts, WhatsApp accounts
→ Ask: "Which account should be used for email steps?"
→ Ask: "Which LinkedIn account for LinkedIn steps?" (if sequence includes LinkedIn)
→ Store from_account_id for each channel
```

### Step 3: Understand the Sequence Goal

Ask the user (or infer from context):
- **Who is this for?** — persona, ICP tier, company size
- **What's the goal?** — book a meeting, re-engage, post-event follow-up, etc.
- **How many touches?** — typical 5-7 step sequences work well
- **Channels?** — email only, email + LinkedIn, all three
- **Any existing sequences to reference?** — `list_sequences()` to show what's already built

### Step 4: Design the Sequence

Propose a sequence structure for user review before writing content:

**Example 5-step email + LinkedIn sequence:**

```
Day 1:  Email — Cold intro (personalized hook)
Day 3:  LinkedIn — Connection request (no pitch)
Day 5:  Email — Follow-up 1 (new angle, brief)
Day 7:  LinkedIn — Check connection status
        → If connected: LinkedIn DM (value-first)
        → If not connected: skip to next email
Day 10: Email — Follow-up 2 (different value prop / social proof)
Day 14: Email — Break-up (last attempt, permission to ignore)
```

Show this structure to the user. Get approval or adjust.

### Step 5: Draft All Content

For each step, draft content using template variables:

**Email drafts** — HTML format:
- Subject: `<50 chars, personalized, no spam triggers`
- Body: HTML with `<p style="margin: 0; margin-bottom: 12px; font-size: 14px;">...</p>` per paragraph
- Use `{{person.first_name}}`, `{{company.name}}` etc.
- No signature (appended server-side)
- Follow `inbox_manager_config()` agent_instructions

**LinkedIn connection request** — <300 chars, genuine, no pitch

**LinkedIn message** — conversational, value-first, single question

**WhatsApp** — casual, short, only if warm context

**Create task steps** — when human touch is needed (e.g., "Call {{person.first_name}} at {{company.name}} — they opened 3 emails")

Show ALL content to user at once. Get explicit approval for every step. Iterate.

### Step 6: Create the Sequence

After user approves all content:

```
create_sequence(
  name="[Sequence name]",
  scheduling_config={
    timezone: "[IANA string]",
    send_window: {start: "09:00", end: "18:00"},
    send_on_weekends: false,
    thread_follow_ups: true/false,
    skip_dates: [...]
  },
  nodes=[
    {node_id: "trigger-1", node_type: "trigger", node_name: "Start", config: {}, ui_data: {}},
    {node_id: "email-1", node_type: "email", node_name: "Day 1 - Intro Email",
     config: {
       subject: "...",
       body: "<HTML>",
       from_account_id: [id],
       from_email: "[email]",
       wait_value: 1,
       wait_unit: "days"
     }, ui_data: {}},
    // ... more nodes
  ],
  edges=[
    {edge_id: "e1", source_node_id: "trigger-1", target_node_id: "email-1", edge_type: "default"},
    // ...
  ]
)
```

**Branch node rules (check_linkedin_connection_status):**
- Requires exactly two edges: `edge_type: "true"` (connected) and `edge_type: "false"` (not connected)
- ALL nodes inside a branch MUST have `ui_data: {"parent_node_id": "<check_node_id>"}`
- Main-flow nodes use `ui_data: {}`

### Step 7: Confirm and Offer Enrollment

```
→ Sequence created: show name, node count, estimated duration
→ Ask: "Do you want to enroll anyone in this sequence now?"
→ If yes: ask for person ID, LinkedIn URL, or name
  → Find person: list_records or enrich_person_by_linkedin
  → enroll_in_sequence(sequence_id, person_id)
```

---

## Sequence Templates by Use Case

### Cold Outreach (B2B SaaS, SDR persona)
```
Day 1:  Email — Trigger-based cold intro
Day 3:  LinkedIn — Connection request (no pitch note)
Day 5:  Email — Follow-up with social proof
Day 7:  LinkedIn check → if connected: DM with insight
Day 10: Email — Different angle (ROI / competitor)
Day 14: Email — Break-up email
```

### Re-engagement (Went dark after demo)
```
Day 1:  Email — Acknowledge time passed, new reason to reconnect
Day 3:  LinkedIn — DM if connected
Day 7:  Email — New value prop / product update
Day 14: Email — Final break-up with soft CTA
```

### Post-Event Follow-up (Conference, webinar)
```
Day 1:  Email — Reference specific conversation
Day 3:  LinkedIn — Connection request with event reference
Day 5:  Email — Value-add (resource, intro, insight)
Day 10: Email — Soft CTA for next conversation
```

### Inbound Lead Nurture
```
Day 0:  Email — Immediate response to inquiry
Day 1:  Task — "Call {{person.first_name}} at {{company.name}}"
Day 3:  Email — Follow-up if no response to call
Day 7:  LinkedIn — Connection request
Day 14: Email — Long-term nurture check-in
```

---

## Output After Creation

```markdown
## Sequence Created: [Name]

**Steps:** [N] | **Duration:** [X days] | **Channels:** [Email / LinkedIn / WhatsApp]
**Scheduling:** [Timezone] | [Send window] | Weekends: [Yes/No]

### Step Summary
| Step | Channel | Timing | Subject/Preview |
|------|---------|--------|-----------------|
| 1 | Email | Day 1 | [Subject] |
| 2 | LinkedIn | Day 3 | [Connection note preview] |
| ... | ... | ... | ... |

**View in toflow:** [Sequence created — open toflow to review]

---

### Enroll Prospects

To enroll someone:
- "Enroll [name] in this sequence"
- Or I can enroll from a toflow list — "enroll everyone in [list name]"
```
