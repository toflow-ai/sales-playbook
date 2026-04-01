---
name: draft-outreach
description: Research a prospect in toflow, then draft personalized multi-channel outreach (email + LinkedIn + WhatsApp). Always researches first. Trigger with "draft outreach to [person/company]", "write cold email to [prospect]", "reach out to [name]", "send LinkedIn message to [person]".
compatibility: Requires mcp__toflow tools
---

# Draft Outreach

Research first, then draft. This skill always pulls prospect data from toflow before writing — no generic outreach. Supports email (via toflow draft), LinkedIn connection/message, and WhatsApp. Can optionally enroll the prospect in a sequence.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                      DRAFT OUTREACH                              │
├─────────────────────────────────────────────────────────────────┤
│  Step 1: RESEARCH (always first)                                 │
│  - enrich_person_by_linkedin → full profile + company data      │
│  - get_person → email, phone, ICP Score, Outreach Stage         │
│  - get_company → website, size, funding (for personalization)   │
│  - list_notes + list_emails → prior relationship context        │
│  - enrich_person_email → find email if missing                  │
├─────────────────────────────────────────────────────────────────┤
│  Step 2: DRAFT (research-personalized)                           │
│  - inbox_manager_config → load workspace email rules            │
│  - list_connected_accounts → get valid sender accounts          │
│  - Compose email + LinkedIn + WhatsApp variants                  │
│  - Show to user → get approval                                   │
├─────────────────────────────────────────────────────────────────┤
│  Step 3: DELIVER                                                  │
│  - draft_email → creates draft in connected inbox               │
│  - send_connection_request → LinkedIn                           │
│  - send_linkedin_message / send_inmail → LinkedIn DM            │
│  - send_whatsapp_message → WhatsApp                             │
│  - Optional: enroll_in_sequence → multi-step follow-up          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Research the Prospect

**If LinkedIn URL provided:**
```
1. enrich_person_by_linkedin(linkedin_url)
2. get_person(person_id)
   - Note: ICP Score, Key Talking Points, LinkedIn Outreach Stage
3. get_company via person.company reference
   - Pull: website, employee range, funding raised, description
4. If email missing: enrich_person_email(person_id)
5. list_notes(resource_type=person, resource_id=...) → prior context
6. list_emails(search=contact_email_or_domain) → email history
```

**If name/company provided:**
```
1. list_records(resource_type=person, search=name) to find in CRM
2. If not found: web search "[name] [company] LinkedIn" → get URL → enrich
3. list_records(resource_type=company, search=company_name) for company data
```

**Check prior outreach:**
- If LinkedIn Outreach Stage is "In conversation" or "Meeting booked" → do not cold outreach, show history instead
- If prior emails found → offer "re-engage" variant instead of cold email

### Step 2: Load Workspace Email Config

```
1. inbox_manager_config() → load agent_instructions and member preferences
   - Follow agent_instructions STRICTLY when writing email
2. list_connected_accounts() → get available email/LinkedIn/WhatsApp accounts
   - Ask user which account to use if multiple available
```

### Step 3: Identify the Hook

Priority order:
1. **Trigger event** — funding, new hire, product launch, job posting (most timely)
2. **Their content** — recent LinkedIn post, article, interview (shows research)
3. **Key Talking Points** from CRM (already enriched by ICP qualifier)
4. **Company initiative** — expansion, new market, hiring pattern
5. **Role-based pain** — SDR tooling, outbound scale, sequence management

### Step 4: Draft Messages

**Email (HTML for draft_email):**
```
Structure (AIDA):
- Subject: <50 chars, personalized, no spam words
- Opening: Specific hook from research (1 sentence)
- Interest: Their likely challenge in 1-2 sentences
- Desire: Brief proof point ("We helped [similar company] achieve X")
- Action: One clear, low-friction CTA

HTML format: wrap each paragraph in:
<p style="margin: 0; margin-bottom: 12px; font-size: 14px;">...</p>
NO markdown in email body. Plain text tone.
Do NOT add a signature — appended server-side.
```

**LinkedIn Connection Request (<300 chars):**
```
Hi {{person.first_name}}, [specific observation/mutual interest/genuine hook].
Would love to connect. [No pitch]
```

**LinkedIn Follow-up Message (after connected):**
```
[Value-first: insight, observation, or relevant question]
[Soft transition to why you reached out]
[Single question, not pitch]
```

**WhatsApp (if phone enriched):**
```
[Casual, short, only if warm or referred context]
```

### Step 5: Show Draft → Get Approval

ALWAYS display the full draft to the user before saving or sending.
Wait for explicit approval. Iterate based on feedback.

### Step 6: Execute Based on User Approval

**Email:**
```
draft_email(
  to_person_id=<id>,
  from_account_id=<selected_account>,
  subject=<approved subject>,
  html_body=<approved HTML body>
)
→ Confirm: "Draft created — review in your inbox before sending"
```

**LinkedIn connection:**
```
Check check_linkedin_connection(person_id) first
If not connected: send_connection_request(person_id, message=<approved note>)
If connected: send_linkedin_message(person_id, message=<approved message>)
```

**WhatsApp:**
```
start_whatsapp_conversation(person_id, message=<approved message>)
```

**Sequence enrollment (optional):**
```
List available sequences: list_sequences()
Ask user: "Want to enroll in a follow-up sequence?"
If yes: enroll_in_sequence(sequence_id, person_id)
Update person record: update_record(resource_type=person, id=person_id,
  attributes={"LinkedIn Outreach Stage": "Connection Request Sent"})
```

---

## Output Format

```markdown
# Outreach Draft: [Name] @ [Company]
**Date:** [Today] | **Sources:** toflow CRM + Enrichment

---

## Research Summary

**Target:** [Name], [Title] at [Company]
**ICP Score:** [Score if available] — [Tier]
**Current Outreach Stage:** [Stage from toflow]
**Hook:** [Specific personalization angle from research]
**Company:** [Size], [Funding], [Key signal]

---

## Email Draft

**To:** [Email or "enriching..."]
**From:** [Selected sender account]
**Subject:** [Subject]

---

[HTML-formatted email body for approval]

---

**Subject Alternatives:**
1. [Option 2]
2. [Option 3]

---

## LinkedIn

**Connection Request (<300 chars):**
[Text]

**Follow-up Message (after connected):**
[Text]

---

## Why This Approach

| Element | Reasoning |
|---------|-----------|
| Opening hook | [What research finding makes it personal] |
| Pain point | [Their likely challenge] |
| CTA | [Why this ask makes sense] |

---

## Next Steps

[ ] Approve email → will create draft in inbox
[ ] Approve LinkedIn → will send connection request
[ ] Enroll in sequence → [Recommended sequence name] for follow-up
```

---

## Email Style Rules

1. **No markdown in email** — no asterisks, bold, or headers. Plain text feel.
2. **Short paragraphs** — 2-3 sentences max. White space is good.
3. **One CTA** — don't offer 3 options. One clear ask.
4. **Follow agent_instructions** from inbox_manager_config strictly.
5. **No signature** — appended server-side automatically.

## What NOT to Do

- Generic openers: "I hope this finds you well", "I'm reaching out because..."
- Feature dump: listing 5 capabilities in the first email
- Fake personalization: "I noticed you work at [Company]" (too obvious)
- Re-cold-outreach someone already in an active sequence

## Channel Selection Logic

```
IF email available in toflow:
  → Email is primary (higher response rate)
  → Prepare LinkedIn as backup/parallel

IF no email, LinkedIn URL available:
  → Connection request first, DM after connected
  → Offer inmail if not connected and premium account available

IF phone available and warm context:
  → WhatsApp as supplement, not primary
```
