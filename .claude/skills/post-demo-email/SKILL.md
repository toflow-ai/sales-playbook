---
name: post-demo-email
description: Draft a detailed post-demo follow-up email to a prospect in toflow, covering demo highlights (as a workflow journey), AI features + MCP integrations, and pricing. Includes competitive comparison only if the user mentions a competitor or it came up in the demo call notes. Always pulls demo call notes from toflow for personalization. Trigger with "post demo email", "follow up after demo", "send recap after demo call", "demo follow-up email to [name/company]", "write recap for [name]", "recap email after call with [company]".
compatibility: Requires mcp__claude_ai_toflow_ai tools
---

# Post-Demo Follow-Up Email

A structured follow-up email sent after a product demo. The goal is to give the prospect a leave-behind that reinforces what they saw, highlights the AI layer, and makes it easy for them to share internally with the decision maker.

## How It Works

```
┌──────────────────────────────────────────────────────────────────┐
│                    POST-DEMO EMAIL                                │
├──────────────────────────────────────────────────────────────────┤
│  Step 1: LOAD CONTEXT                                             │
│  - get_deal → deal title, stage, people, company                 │
│  - list_notes(deal_id) → find demo call notes                    │
│  - get_task (if task_id provided) → confirm task requirements    │
├──────────────────────────────────────────────────────────────────┤
│  Step 2: RESOLVE CONTACT + EMAIL CONFIG                          │
│  - enrich_person_email(person_id) if no email on file           │
│  - inbox_manager_config() → load workspace writing rules        │
│  - list_connected_accounts() → get sender accounts              │
├──────────────────────────────────────────────────────────────────┤
│  Step 3: COMPOSE + REVIEW                                        │
│  - Build email in the 5-section structure below                  │
│  - Show to user → iterate until approved                        │
│  - Prompt user to fill in [PRICING] before sending              │
├──────────────────────────────────────────────────────────────────┤
│  Step 4: SAVE DRAFT                                              │
│  - draft_email → saves to connected inbox as draft              │
│  - Return draft URL for review                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Load Deal Context

Accept one of: `deal_id`, `task_id`, or a person/company name.

```
- get_deal(deal_id) → title, stage, company, people
- list_notes(deal_id=...) → find demo call notes (look for notes titled "Demo Call", "Discovery", etc.)
- If task_id provided: get_task(task_id) → read task description for any specific requirements
```

From the demo call notes, extract:
- **Current tech stack**: especially the outreach tool
- **Decision maker name**: who the prospect needs to share with internally (use in CTA)
- **Features demoed**: to confirm what was shown
- **AI tools they use**: e.g. Claude for Work, GPT (use in AI section personalization)
- **Pain points / objections**: weave into the email body

### Step 2: Resolve Contact + Email Config

```
- If person has no email: enrich_person_email(person_id)
- inbox_manager_config() → follow agent_instructions strictly
- list_connected_accounts() → present email accounts to user, ask which to send from
```

### Step 3: Compose the Email

Follow the **5-section structure** below. Write in HTML for `draft_email`. Each section maps to a `<p>` or `<ul>` block.

---

## Email Structure

### Subject line
Short, benefit-oriented, references the demo or a specific topic discussed.
Example: `toflow recap: demo highlights and pricing`

### Opening
One line referencing the demo. Warm, not formal.
> "Great chatting yesterday. Here's the recap so you can share it with [DM name]."

If DM name is not in notes, use: "so you can share it internally."

---

### Section 1: What we demoed, end to end

Present as a **workflow journey** in this order. Do not reorder.

```html
<p><strong>What we demoed, end to end:</strong></p>
<ul>
  <li><strong>Prospecting</strong>: build targeted lists directly inside toflow; no separate tool needed</li>
  <li><strong>Enrichment</strong>: waterfall across multiple providers, ~80% email coverage; reduces dependence on [their enrichment tool if known, else ZoomInfo]</li>
  <li><strong>Multichannel sequences</strong>: email, LinkedIn (connection + message + InMail), and WhatsApp in a single automated flow</li>
  <li><strong>Unified inbox</strong>: all replies (including LinkedIn) in one place; team responds without sharing credentials</li>
  <li><strong>Multi-account LinkedIn and advanced features</strong>: respond on behalf of teammates securely; ICP scoring (5 configurable vectors, scored out of 100) so you always know who to prioritize</li>
</ul>
```

Adapt bullet copy based on what was actually demoed per the notes. Keep the flow order (prospecting to enrichment to sequences to inbox to advanced).

---


### Section 3: Pricing

Always use the pricing structure below. Fill in seat count and total based on what the user provides.

```html
<p style="margin: 0; margin-bottom: 8px; font-size: 14px; line-height: 1.6;"><strong>Pricing:</strong></p>
<p style="margin: 0; margin-bottom: 8px; font-size: 14px; line-height: 1.6;"><strong>Seats:</strong> [N] seats x $60/seat = <strong>$[TOTAL]/month</strong></p>
<ul style="margin: 0; margin-bottom: 8px; padding-left: 20px;">
  <li style="margin-bottom: 6px; font-size: 14px;">Each seat includes up to 3 connected email accounts and 1 LinkedIn account</li>
  <li style="margin-bottom: 6px; font-size: 14px;">Each seat comes with 1,000 credits/month (worth $10) for enrichment</li>
</ul>
<p style="margin: 0; margin-bottom: 8px; font-size: 14px; line-height: 1.6;"><strong>Additional enrichment credits:</strong> $1 = 100 credits. Credits are consumed per action:</p>
<ul style="margin: 0; margin-bottom: 16px; padding-left: 20px;">
  <li style="margin-bottom: 6px; font-size: 14px;">Email Finder: 2 credits per contact ($0.02)</li>
  <li style="margin-bottom: 6px; font-size: 14px;">Email Verifier: 0.5 credits per contact ($0.005)</li>
  <li style="margin-bottom: 6px; font-size: 14px;">LinkedIn Profile: 0.5 credits per contact ($0.005)</li>
  <li style="margin-bottom: 6px; font-size: 14px;">Sales Nav Profile: 1 credit per contact ($0.01)</li>
  <li style="margin-bottom: 6px; font-size: 14px;">Phone Finder: 20 credits per contact ($0.20)</li>
</ul>
```

---

### Section 5: CTA

Single ask: 20-minute call. Name the decision maker if known from notes.

```html
<p>Happy to get 20 minutes to walk through fit and next steps. What works later this week or early next?</p>
```

---

### Closing
First name only. No sign-off phrase.

```html
<p>[Sender first name]</p>
```

---

## Step 4: Review Loop

ALWAYS show the full draft in the conversation before saving. Iterate based on feedback.

When showing the draft, use this format:

```
---
**From:** [sender email]
**To:** [prospect email]
**Subject:** [subject]

[full email body rendered as markdown for readability]

---
⚠️ Remember to fill in [PRICING] before sending.
```

After user approves:
1. Call `draft_email(from_email=..., to_emails=[...], subject=..., html_body=..., person_id=...)`
2. Return the draft URL
3. Remind user to fill in `[PRICING]`

---

## HTML Formatting Rules

```html
<!-- Each paragraph -->
<p style="margin: 0; margin-bottom: 16px; font-size: 14px; line-height: 1.6;">...</p>

<!-- Lists -->
<ul style="margin: 0; margin-bottom: 16px; padding-left: 20px;">
  <li style="margin-bottom: 6px; font-size: 14px;">...</li>
</ul>

<!-- Bold labels in list items -->
<strong>Label</strong>: description text
```

No markdown in HTML body. Do NOT add a signature appended server-side automatically.

---

## What NOT to Do

- Do not invent pricing outside the defined structure always use the seat/credit breakdown above
- Do not reorder the demo journey sections (prospecting → enrichment → sequences → inbox → advanced)
- Do not call `draft_email` before the user approves the draft
- Do not use generic openers ("Hope this finds you well")
- Do not include more than one CTA
- Do not include a competitor comparison section