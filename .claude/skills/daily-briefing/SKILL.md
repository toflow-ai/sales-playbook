---
name: daily-briefing
description: Start your day with a prioritized sales briefing pulled live from toflow — pipeline alerts, tasks due, email priorities, and today's meetings. Trigger with "morning briefing", "daily brief", "what's on my plate today", "prep my day", or "start my day".
compatibility: Requires mcp__toflow tools
---

# Daily Sales Briefing

Live data from toflow — not a static report. Pulls deals, tasks, emails, and messages in real-time, then prioritizes into a scannable 2-minute brief.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                      DAILY BRIEFING                              │
├─────────────────────────────────────────────────────────────────┤
│  DATA PULL (toflow — all live)                                   │
│  ✓ list_records (deal) → pipeline snapshot, closing soon        │
│  ✓ list_tasks → tasks due today + overdue                       │
│  ✓ list_emails → unread from prospects, waiting on replies      │
│  ✓ list_message_threads → LinkedIn/WhatsApp unread              │
│  ✓ list_enrollments → active sequences with recent activity     │
│  + Google Calendar → today's meetings                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Pull Today's Meetings (if calendar connected)

```
gcal_list_events(
  time_min=[today 00:00],
  time_max=[today 23:59]
)
→ Filter: external meetings (non-internal attendees)
→ Extract: time, company, attendees, description
```

### Step 2: Pull Pipeline Alerts from toflow

```
1. Get all open deals:
   list_records(
     resource_type=deal,
     filters=[{field: "status", operator: "is_not", value: "won"},
              {field: "status", operator: "is_not", value: "lost"}],
     sort="Expected Close Date:asc",
     page_size=50
   )

2. Flag deals for priority:
   CLOSING THIS WEEK: expected_close_date <= today+7
   STALE: no activity info — check deal notes via list_notes
   HIGH VALUE: value > threshold (use largest deals as high-value)
   HIGH INTENT: Intent = "Very Hot" or "Hot"
   HIGH PRIORITY: Priority = "3" (High)
```

### Step 3: Pull Tasks Due Today

```
list_tasks(
  filters=[{field: "due_date", operator: "lte", value: today_iso}],
  sort="due_date:asc"
)
→ Show overdue + due today
```

### Step 4: Pull Email Priorities

```
list_emails(
  page_size=20,
  sort="Created At:desc"
)
→ Identify: unread from known prospect domains
→ Identify: sent emails with no reply (sent >2 days ago, no reply thread)
```

### Step 5: Pull LinkedIn/WhatsApp Unread

```
list_message_threads(page_size=20)
→ Filter: threads with unread or recent incoming messages
→ Extract: person name, company, message preview
```

### Step 6: Prioritize

Use this ranking to determine the #1 Priority:
```
1. URGENT: Deal closing today/tomorrow not yet won
2. HIGH: Meeting today with active deal > $10K
3. HIGH: Unread reply from a decision-maker
4. MEDIUM: Deal closing this week (7 days)
5. MEDIUM: Overdue task on an active deal
6. MEDIUM: Hot/Very Hot deal with no recent activity
7. LOW: General tasks due today
```

### Step 7: Assemble Briefing

Include all sections with data. Skip sections if no data (e.g., no meetings → no meetings section).

---

## Output Format

```markdown
# Daily Briefing | [Day, Month Date]

---

## #1 Priority

**[Most important thing to do right now]**
[Why — deal value, close date, or urgency]

---

## Today's Meetings

### [Time] — [Company] ([Meeting Type])
**Attendees:** [Names and titles]
**Deal:** [Stage] | $[Value] | [Intent level]
**Prep:** [One-line action before this meeting — e.g., "review last call notes"]

*Run `call-prep [company]` for full meeting brief*

---

## Pipeline Alerts

### Closing This Week
| Deal | Stage | Value | Close Date | Intent | Action |
|------|-------|-------|------------|--------|--------|
| [Deal] | [Stage] | $[X] | [Date] | [Hot/Warm] | [What to do] |

### Needs Attention
| Deal | Stage | Value | Alert | Action |
|------|-------|-------|-------|--------|
| [Deal] | [Stage] | $[X] | [Why flagged] | [Next step] |

---

## Tasks Due Today

| Task | Deal | Due | Priority |
|------|------|-----|----------|
| [Task title] | [Deal] | [Date] | [H/M/L] |

---

## Email Priorities

### Reply Needed (Unread from Prospects)
| From | Subject | Received |
|------|---------|----------|
| [Name @ Company] | [Subject] | [Time] |

### Waiting on Reply
| To | Subject | Sent | Days Waiting |
|----|---------|------|--------------|
| [Name @ Company] | [Subject] | [Date] | [N] |

---

## LinkedIn/WhatsApp

| Person | Company | Channel | Preview |
|--------|---------|---------|---------|
| [Name] | [Company] | [LI/WA] | [Message snippet] |

---

## Suggested Actions

1. **[Action]** — [Why now — specific deal/contact]
2. **[Action]** — [Why now]
3. **[Action]** — [Why now]

---

*Run `call-prep [company]` before meetings*
*Run `/call-summary` after each call*
*Run `/pipeline-review` for full pipeline analysis*
```

---

## Quick Mode

If user says "quick brief" or "tldr my day":

```markdown
# Quick Brief | [Date]

**#1:** [Single priority action]
**Meetings:** [N] — [Company 1], [Company 2]
**Closing this week:** [Deal 1] $[X], [Deal 2] $[X]
**Tasks overdue:** [N]
**Unread replies:** [N]

**Do Now:** [The one thing that matters most]
```

---

## End of Day Mode

If user says "wrap up my day" or "end of day":

```markdown
# End of Day | [Date]

**Calls completed:** [List with 1-line outcome each]
**Tasks completed:** [N] done, [N] still open

**Pipeline updates needed:**
- [Deal] — update stage to [Stage]? (run /call-summary to log)

**Tomorrow's focus:**
1. [Deal/task priority]
2. [Deal/task priority]

**Open loops:**
- [ ] [Uncommitted action item]
```
