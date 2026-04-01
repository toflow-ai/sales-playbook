---
name: call-prep
description: Prepare for a sales call by pulling deal context, contact history, and prior notes from toflow, then generating an agenda and discovery questions. Trigger with "prep me for my call with [company]", "call prep [company]", "I'm meeting with [name] prep me", "get me ready for [meeting]".
compatibility: Requires mcp__toflow tools
---

# Call Prep

Full meeting brief in minutes — pulled live from toflow. Deal history, contact background, prior emails, call notes, and recent LinkedIn activity. Web search fills in news and attendee research.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        CALL PREP                                 │
├─────────────────────────────────────────────────────────────────┤
│  PRIMARY: toflow CRM                                             │
│  ✓ list_records (deal) → find active deal for this company      │
│  ✓ get_deal → stage, value, probability, expected close date    │
│  ✓ get_person → attendee records with title, email, ICP score   │
│  ✓ get_company → company profile, size, funding                 │
│  ✓ list_notes → prior call notes, internal context              │
│  ✓ list_emails → recent email threads with this contact/company │
│  ✓ list_message_threads → LinkedIn/WhatsApp conversation history│
│  ✓ list_tasks → outstanding action items for this deal          │
├─────────────────────────────────────────────────────────────────┤
│  SUPPLEMENT                                                      │
│  + Google Calendar → find the meeting, pull attendees           │
│  + Web search → recent company news, attendee LinkedIn          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Find the Meeting Context

**If calendar connected (Google Calendar):**
```
1. gcal_list_events(time_min=today, time_max=today+2days) → find upcoming meeting
2. Extract: attendee emails, meeting title, description, time
```

**If no calendar:**
```
Ask user: "Who are you meeting with and what type of call is it?"
Accept: company name, attendee names/titles, meeting type
```

### Step 2: Pull Deal from toflow

```
1. list_records(resource_type=deal, search=company_name)
   - If multiple deals: show list, ask user which one
   - If none: proceed without deal context, note it's a new prospect

2. get_deal(deal_id)
   - Pull: title, value, stage, probability, expected close date, priority, intent
   - Pull: associated people IDs, company ID

3. list_stages() + list_pipelines() → resolve stage name from ID for display
```

### Step 3: Pull Attendee Profiles

For each attendee email/name from calendar or user input:
```
1. list_records(resource_type=person, search=email_or_name)
2. get_person(person_id)
   - Pull: title, LinkedIn URL, ICP Score, Key Talking Points, Outreach Stage
3. If thin data: enrich_person_by_linkedin if LinkedIn URL available
```

### Step 4: Pull Company Profile

```
1. get_company(company_id) from deal or person reference
   - Pull: website, employee range, funding raised, estimated ARR, description
2. If no company record: list_records(resource_type=company, search=company_name)
```

### Step 5: Pull History

```
1. list_notes(resource_type=deal, resource_id=deal_id)
   + list_notes(resource_type=company, resource_id=company_id)
   → Extract: key decisions, open questions, prior commitments, concerns raised

2. list_emails(search=company_domain, page_size=10)
   → Extract: last email sent/received, open questions, attachments shared

3. list_message_threads → filter for threads with this company/person
   → Extract: LinkedIn/WhatsApp conversation status

4. list_tasks(filters=[{field: "deal", value: deal_id}])
   → Surface outstanding action items you committed to
```

### Step 6: Web Supplement

```
1. "[company name] news" → last 30-60 days, funding, hires, product
2. Attendee LinkedIn profiles if not enriched
```

### Step 7: Synthesize and Generate Brief

Combine all data into a structured prep brief. Tailor agenda by meeting type:
- **Discovery** → more questions, less talking
- **Demo** → tailor to their use case
- **Negotiation** → address known objections, path to close
- **Check-in/QBR** → value delivered, expansion signals

---

## Output Format

```markdown
# Call Prep: [Company Name]

**Meeting:** [Type] | [Date/Time]
**Attendees:** [Names + Titles]
**Your Goal:** [What you want to accomplish in this call]

---

## Deal Snapshot

| Field | Value |
|-------|-------|
| **Deal** | [Title] |
| **Stage** | [Stage name] |
| **Value** | $[Amount] |
| **Probability** | [X]% |
| **Expected Close** | [Date] |
| **Intent** | [Very Hot / Hot / Warm / Cold] |
| **Priority** | [High / Medium / Low] |

---

## Who You're Meeting

### [Name] — [Title]
- **LinkedIn:** [URL]
- **Background:** [Prior companies, education if enriched]
- **ICP Score:** [Score] — [Tier]
- **Outreach Stage:** [Stage from toflow]
- **Key Talking Points:** [From CRM if available]
- **Role in Deal:** [Decision maker / Champion / Evaluator]

[Repeat for each attendee]

---

## History & Context

**Recent emails:**
- [Date]: [Thread summary — what was discussed, any open items]

**Call notes:**
- [Note date]: [Key points from prior calls]

**LinkedIn/WhatsApp:**
- [Thread status and last message summary]

**Outstanding tasks:**
- [ ] [Action you committed to — from toflow tasks]
- [ ] [Customer commitment — from notes]

**Recent company news:**
- [News item — why relevant]

---

## Suggested Agenda

1. **Open** — [Reference last touchpoint or trigger event]
2. **[Topic 1]** — [Discovery question or value discussion based on stage]
3. **[Topic 2]** — [Address known concern from notes]
4. **[Topic 3]** — [Demo / proposal / negotiation point]
5. **Next Steps** — Propose clear follow-up with date

---

## Discovery Questions

Based on stage and history, ask these to fill gaps:

1. [Question about their current situation]
2. [Question about pain points — connect to Key Talking Points if set]
3. [Question about decision process and timeline]
4. [Question about success criteria]
5. [Question about other stakeholders not in this meeting]

---

## Potential Objections

| Objection | Response |
|-----------|----------|
| [Likely concern from notes/emails] | [How to address] |
| [Stage-appropriate objection] | [Counter] |

---

## After the Call

Run `/call-summary` with your notes to:
- Log the call to toflow as a note
- Update deal stage and probability
- Create follow-up tasks
- Draft customer follow-up email
```

---

## Tips

1. **Always check notes** — the history often has the most important context
2. **Check tasks** — don't forget commitments you made last call
3. **Check email threads** — the last email exchange shows where momentum stands
4. **Check Intent field** — if deal intent dropped to Cold, address that first
