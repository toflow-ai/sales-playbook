---
description: Process call notes or a transcript — extract action items, update the deal in toflow, create follow-up tasks, and draft customer follow-up email
argument-hint: "<call notes, transcript, or description of what happened>"
---

# /call-summary

Process call notes or a transcript to extract action items, update the deal in toflow, and draft follow-up communications.

## Usage

```
/call-summary <notes or transcript>
```

Process these call notes: $ARGUMENTS

---

## What This Command Does

```
┌─────────────────────────────────────────────────────────────────┐
│                      CALL SUMMARY                                │
├─────────────────────────────────────────────────────────────────┤
│  EXTRACT                                                         │
│  ✓ Key discussion points and decisions                          │
│  ✓ Action items with owners and due dates                       │
│  ✓ Objections, concerns, and open questions                     │
│  ✓ Buying signals or risk signals                               │
│  ✓ Deal stage / probability change (if applicable)              │
├─────────────────────────────────────────────────────────────────┤
│  LOG TO toflow                                                   │
│  ✓ create_note → call summary saved to deal/person/company      │
│  ✓ update_record (deal) → stage, probability, intent, close date│
│  ✓ create_task → follow-up actions with due dates               │
├─────────────────────────────────────────────────────────────────┤
│  DRAFT                                                           │
│  ✓ Customer-facing follow-up email (via inbox_manager_config)   │
│  ✓ draft_email → creates draft in connected inbox               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Identify the Deal/Contact

```
1. Extract company name from notes
2. list_records(resource_type=deal, search=company_name) → find active deal
3. If multiple deals: show list, ask which one
4. list_records(resource_type=person, search=attendee_name_or_email) → find contacts
5. If no deal found: offer to create one after summary
```

### Step 2: Extract From Notes

Systematically parse the call notes/transcript for:

- **Attendees** — names and titles (both sides)
- **Meeting type** — discovery / demo / negotiation / check-in
- **Key discussion points** — what was covered
- **Customer priorities** — what they said they care about
- **Pain points** — problems they're experiencing
- **Objections/concerns** — hesitations raised
- **Competitor mentions** — any alternatives they mentioned
- **Buying signals** — urgency, budget references, timeline, champion behavior
- **Risk signals** — delays, gatekeeping, negative language
- **Action items** — commitments from both sides with due dates
- **Agreed next step** — what happens next and when

### Step 3: Assess Deal Impact

Based on what was discussed:
- Should the deal stage advance, stay, or regress?
- Should the probability change?
- Should the intent change (Very Hot / Hot / Warm / Cold)?
- Should the expected close date be updated?

Surface these as suggestions — always confirm with user before updating.

### Step 4: Generate Internal Summary

Present the full internal summary for review before logging anything.

### Step 5: Log to toflow (with user confirmation)

**Create note:**
```
create_note(
  resource_type="deal",  // or "person" or "company"
  resource_id=deal_id,
  content="[Formatted internal summary]"
)
```

**Update deal (confirm each change):**
```
update_record(
  resource_type="deal",
  id=deal_id,
  attributes={
    "Stage": [new_stage_id],      // if advancing
    "Probability": [new_pct],     // if changed
    "Intent ": [new_intent],      // if changed
    "Expected Close Date": [date] // if updated
  }
)
```

**Create tasks for action items:**
```
For each action item owned by you:
create_task(
  title="[Action]",
  description="[Context from call]",
  due_date="[YYYY-MM-DD]",
  resource_type="deal",
  resource_id=deal_id
)
```

### Step 6: Draft Follow-Up Email

```
1. inbox_manager_config() → load workspace rules
2. list_connected_accounts() → get sender account
3. Compose follow-up email:
   - Confirm key points discussed
   - Your commitments (what you'll send/do)
   - Customer commitments (what they'll do)
   - Clear next step with date
   - Plain text, no markdown formatting
4. Show draft to user → get approval
5. draft_email(to_person_id, from_account_id, subject, html_body) after approval
```

---

## Output

### Internal Summary

```markdown
## Call Summary: [Company] | [Date]

**Attendees:** [Their names + titles] | [Your name]
**Call Type:** [Discovery / Demo / Negotiation / Check-in]
**Duration:** [If known]

### Key Discussion Points
1. [Topic — what was discussed and decided]
2. [Topic]

### Customer Priorities
- [Priority they expressed]

### Objections / Concerns
- [Concern] — [How addressed / status]

### Competitive Intel
- [Competitor mentioned + context]

### Buying Signals
- [Signal and what it means]

### Action Items
| Owner | Action | Due Date |
|-------|--------|----------|
| [You] | [Task] | [Date] |
| [Customer] | [Task] | [Date] |

### Agreed Next Step
[What happens next, who owns it, and when]

### Deal Impact
- Stage: [Current] → [Suggested] — [Reason]
- Probability: [Current]% → [Suggested]%
- Intent: [Current] → [Suggested]
```

---

### Follow-Up Email Draft

```
Subject: [Meeting recap — Company Name]

Hi [Name],

[Specific callback to meeting — what you discussed]

Here's what we covered:
- [Key point 1]
- [Key point 2]

From my side, I'll:
- [Your commitment 1]
- [Your commitment 2]

From your side:
- [Their commitment]

[Agreed next step] — I'll [send calendar / reach back out] by [date].

[Signature appended by server]
```

---

## Email Style Rules

1. Plain text feel — no markdown, no asterisks, no headers
2. Short paragraphs — 2-3 sentences max
3. Confirm commitments clearly — both sides
4. One clear next step with a date
5. Follow agent_instructions from inbox_manager_config

---

## Tips

1. **Include attendee names** — helps assign action items correctly
2. **Note deal stage** — helps me suggest the right stage transition
3. **Flag the big thing** — "Main concern was pricing" → I'll highlight it
4. **Paste competitor mentions verbatim** — useful competitive intel to log
