---
name: account-research
description: Research a company or person and get actionable sales intel. Uses toflow CRM + enrichment as primary source, falls back to web search. Trigger with "research [company]", "look up [person]", "intel on [prospect]", "who is [name] at [company]", or "tell me about [company]".
compatibility: Requires mcp__toflow tools
---

# Account Research

Get a complete picture of any company or person before outreach. toflow is the primary data source — CRM history, enriched profiles, and prior activity. Web search fills any gaps.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                     ACCOUNT RESEARCH                             │
├─────────────────────────────────────────────────────────────────┤
│  PRIMARY: toflow CRM + Enrichment                                │
│  ✓ enrich_person_by_linkedin → full profile from LinkedIn URL   │
│  ✓ get_person → CRM record with company, email, phone, score    │
│  ✓ get_company → size, funding, website, employee range         │
│  ✓ list_notes → prior call notes, context, history              │
│  ✓ list_emails → recent email threads with this contact         │
│  ✓ list_message_threads → LinkedIn/WhatsApp conversations       │
│  ✓ enrich_person_email / enrich_person_phone → contact details  │
├─────────────────────────────────────────────────────────────────┤
│  SUPPLEMENT: Web Search                                          │
│  + Recent news, funding announcements, leadership changes        │
│  + Hiring signals (open roles)                                   │
│  + Product/service description if not in CRM                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Parse the Request

Identify what's being researched:
- LinkedIn URL provided → go to Step 2a
- Name + company provided → go to Step 2b
- Company name/domain only → go to Step 2c
- Role-based ("CTO at Acme") → search LinkedIn, then Step 2a

### Step 2a: LinkedIn URL → Enrich via toflow

```
1. Call enrich_person_by_linkedin(linkedin_url)
   - Returns: full profile, job title, company, location
   - Creates/updates person record in toflow
2. Call get_person(person_id) on the returned record
   - Pull: email, phone, ICP Score, Key Talking Points, LinkedIn Outreach Stage
   - Pull company record reference
3. Call get_company(company_id) from person.company
   - Pull: name, website, employee range, funding raised, estimated ARR, description
4. If email missing → call enrich_person_email(person_id)
5. Call list_notes(resource_type=person, resource_id=person_id) → prior notes
6. Call list_emails(search=company_domain) → recent email history
7. Call list_message_threads → filter by person for LinkedIn/WA threads
```

### Step 2b: Name/Email → Search CRM

```
1. Call list_records(resource_type=person, search=name_or_email)
   - If found: proceed as Step 2a from get_person
   - If not found: search LinkedIn (web search "[name] [company] LinkedIn")
     then enrich_person_by_linkedin if URL found
2. Search company: list_records(resource_type=company, search=company_name)
```

### Step 2c: Company Only

```
1. Call list_records(resource_type=company, search=company_name)
   - If found: call get_company, list associated people via list_records(resource_type=person, filters=[{field: "Company", operator: "is", value: company_id}])
   - If not found: web search for company overview
2. Check for open deals: list_records(resource_type=deal, search=company_name)
```

### Step 3: Web Search Supplement

Always run these searches to add recency:
1. `"[company name] news 2024 2025"` — funding, hires, product
2. `"[company name] careers"` — hiring signals
3. If person found: `"[name] [company] LinkedIn"` if profile data is thin

### Step 4: Synthesize

- Prioritize toflow CRM data over web (more accurate, verified)
- Merge enrichment data with CRM history
- Check ICP Score field — if scored, surface it
- Note LinkedIn Outreach Stage if set (don't re-approach someone in active sequence)
- Flag any prior relationship context from notes/emails

---

## Output Format

```markdown
# Research: [Name or Company]

**Date:** [Today's date]
**Sources:** toflow CRM [+ Enrichment] [+ Web Search]

---

## Quick Take

[2-3 sentences: who they are, why relevant, best angle for outreach]

---

## Profile

| Field | Value |
|-------|-------|
| **Name** | [Full name] |
| **Title** | [Job title] |
| **Company** | [Company name] |
| **Website** | [URL] |
| **Size** | [Employee range] |
| **Location** | [City/Country] |
| **LinkedIn** | [URL] |
| **Email** | [If available] |
| **ICP Score** | [If scored in toflow] |
| **Outreach Stage** | [If set in toflow] |

### Company Overview
[1-2 sentences: what they do, who they sell to]

### Funding
[Funding raised + estimated ARR if available]

---

## CRM History

| Field | Detail |
|-------|--------|
| **Status** | [New / Known contact / In active sequence] |
| **Last Email** | [Date + subject summary] |
| **Last Message** | [LinkedIn/WA thread summary] |
| **Open Deals** | [Deal titles and stages] |
| **Notes** | [Key points from prior notes] |

---

## Recent News & Signals (Web)

- **[Headline]** — [Date] — [Why relevant for outreach]
- **Hiring:** [Open roles in sales/engineering/etc.] — [What it signals]

---

## Key People [If company research]

| Name | Title | LinkedIn | Recommended Approach |
|------|-------|----------|---------------------|
| [Name] | [Title] | [URL] | [Why this person] |

---

## Qualification Signals

### Positive
- [Signal and evidence from toflow/web]

### Flags
- [Concern or data gap]

---

## Recommended Next Step

**Entry point:** [Who to reach out to and why]
**Approach:** [Email / LinkedIn / Re-engage — based on outreach stage in CRM]
**Hook:** [What to open with based on research]

Run `draft-outreach` to generate personalized messages based on this research.
```

---

## Notes

- If `enrich_person_by_linkedin` times out, call `get_person_enrichment_status(task_id)` to poll
- Never reach out to someone mid-sequence — check LinkedIn Outreach Stage first
- If ICP Score already exists in CRM, display it rather than re-scoring
- Related: **icp-qualifier** — score the prospect, **draft-outreach** — write the message
