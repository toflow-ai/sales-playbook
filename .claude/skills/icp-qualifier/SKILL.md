---
name: icp-qualifier
description: Score and qualify toflow.ai prospects against the Ideal Customer Profile (ICP). Use when asked to qualify a prospect, score a lead, check ICP fit, or evaluate whether someone is a good target for toflow.ai outreach.
compatibility: Requires toflow MCP tools to be connected
---

# toflow.ai ICP Qualification Skill

This skill scores a prospect (person or company) against toflow.ai's Ideal Customer Profile and produces a structured qualification report with a numeric score, tier, and recommended next action.

---

## toflow.ai ICP — What You're Scoring Against

**Product in one line:** toflow.ai is an AI-native multi-channel outreach platform (email + LinkedIn + WhatsApp) that combines lead discovery, enrichment, and campaign execution in one workspace — replacing the fragmented Apollo → Clay → Outreach/Salesloft stack.

**Primary pain it solves:**
- SDRs stitching together 5-7 tools with manual handoffs
- Missed follow-ups, no pipeline visibility
- The quality-vs-volume tradeoff in personalised outreach

**Best-fit customer:**
- B2B SaaS or tech company
- Has an outbound sales motion (SDRs, BDRs, or founder-led outbound)
- 10–500 employees (sweet spot: 20–150)
- Currently using fragmented tools (Apollo, Outreach, Salesloft, HubSpot Sequences, Clay, Lemlist, Instantly, etc.)
- Open to AI-native tooling
- Budget exists: already paying for 2+ outbound tools

**Anti-ICP (disqualify fast):**
- Pure inbound-only companies (no outbound motion at all)
- Enterprise (>1000 employees) with procurement/legal walls
- Non-B2B (B2C, consumer, D2C)
- No sales team / no SDR function
- Agencies doing outreach on behalf of others (unless they want to use toflow for client campaigns)

---

## Scoring Model (100 points total)

Score each dimension, then sum for the final score.

### Dimension 1 — Outbound Motion (25 pts)
Does this company actively do outbound prospecting?

| Signal | Points |
|--------|--------|
| Has dedicated SDR/BDR team or role | 25 |
| Founder or AE doing outbound (no dedicated SDR) | 15 |
| Outbound mentioned in job postings or LinkedIn | 10 |
| No outbound signals found | 0 |

### Dimension 2 — Company Fit (20 pts)
Is the company profile aligned with toflow's sweet spot?

| Signal | Points |
|--------|--------|
| B2B SaaS / tech, 20–150 employees | 20 |
| B2B SaaS / tech, 150–500 employees | 15 |
| B2B non-tech (agency, consulting, professional services with outbound) | 10 |
| Too small (<10 employees, solo founder) | 5 |
| Enterprise (>500 employees) or B2C | 0 |

### Dimension 3 — Tool Stack Pain (20 pts)
Are they already spending on fragmented outbound tooling?

| Signal | Points |
|--------|--------|
| Uses 3+ outbound tools (Apollo + Clay + Outreach/Salesloft/Lemlist etc.) | 20 |
| Uses 2 outbound tools | 12 |
| Uses 1 tool (e.g., only HubSpot Sequences) | 6 |
| No outbound tool detected | 0 |

### Dimension 4 — Role Fit (20 pts)
Is the prospect the right person to talk to?

| Role | Points |
|------|--------|
| VP/Head of Sales, CRO, Sales Director | 20 |
| CEO/Founder (if <50 employees) | 18 |
| SDR/BDR Manager, Sales Enablement | 15 |
| AE or individual SDR | 8 |
| Marketing, RevOps (influencer, not buyer) | 5 |
| Non-sales role (Engineering, Finance, etc.) | 0 |

### Dimension 5 — Buying Signals (15 pts)
Any signals that suggest active interest or timing alignment?

| Signal | Points (additive, max 15) |
|--------|--------------------------|
| Recently hired SDRs or Sales Ops (LinkedIn / job postings) | +5 |
| Series A–C funding in last 12 months | +5 |
| Inbound enquiry or engaged with toflow content | +4 |
| Currently evaluating or switching outbound tools | +5 |
| Company headcount growing >20% YoY | +3 |

---

## ICP Score Ranges & Recommended Actions

| ICP Score | Label | Recommended Action |
|-----------|-------|--------------------|
| 80–100 | Hot — Strong ICP Fit | Prioritise immediately. Personalised multi-touch sequence (email + LinkedIn). Book a call. |
| 60–79 | Warm — Good Fit | Add to nurture sequence. Personalise first touch. Follow-up 2–3x. |
| 40–59 | Lukewarm — Partial Fit | Low-effort touch only. Generic sequence. Monitor for signals. |
| 20–39 | Weak Fit | Deprioritise. Only contact if bandwidth is free. |
| 0–19 | Disqualify | Remove from pipeline. Not worth pursuing now. |

---

## Step-by-Step Instructions

### Step 1 — Identify the prospect
- Accept a person name, LinkedIn URL, email, or toflow record ID from the user.
- If a LinkedIn URL is provided, use `enrich_person_by_linkedin` to fetch or create the person in toflow.
- If a name/email is provided, use `list_records` (resource_type=person) with a search filter to find them in the CRM.

### Step 2 — Gather data
Pull the following from the person and their company record:

**From the person:**
- Job title / seniority
- LinkedIn headline

**From the company (via `get_company` or `get_person`):**
- Company size (employee count)
- Industry
- Website
- Technology stack if available
- Recent funding

**External enrichment (if CRM data is thin):**
- Check LinkedIn profile for tool mentions, job postings, recent activity
- Look for hiring signals (SDR/BDR roles posted)

### Step 3 — Score each dimension
Work through all 5 dimensions systematically. For each:
1. State what evidence you found
2. Assign the points
3. Briefly justify

### Step 4 — Produce the qualification report

Output the report in this exact format:

---

## ICP Qualification Report

**Prospect:** [Name] — [Title] at [Company]
**LinkedIn:** [URL if available]
**Scored on:** [Date]

### Score Breakdown

| Dimension | Max | Score | Evidence |
|-----------|-----|-------|----------|
| Outbound Motion | 25 | X | [1-line evidence] |
| Company Fit | 20 | X | [1-line evidence] |
| Tool Stack Pain | 20 | X | [1-line evidence] |
| Role Fit | 20 | X | [1-line evidence] |
| Buying Signals | 15 | X | [1-line evidence] |
| **TOTAL** | **100** | **X** | |

### ICP Score: [0–100] — [Label]

### Recommended Action
[1–2 sentences: what to do next and why]

### Key Talking Points
- [Pain point 1 most relevant to this prospect]
- [Pain point 2]
- [Specific personalisation hook from their profile/activity]

### Red Flags / Risks
- [Any disqualifying signals or gaps in data]

---

### Step 5 — Update CRM (optional, ask user first)
If the user wants to save the score back to toflow, use `update_record` on the person to set these fields:
- **ICP Score** — the numeric score (0–100)
- **Key Talking Points** — the bullet points from the qualification report

Always confirm with the user before writing back to the CRM.

---

## Notes
- If critical data is missing (e.g., company size unknown), state the assumption you made and flag it as a data gap.
- When evidence is ambiguous, lean conservative (score lower, not higher).
- Do not guess tool stack — only score it if there's direct evidence (LinkedIn, job postings, integrations page, etc.).
- If the user provides a list of prospects, score them one by one and finish with a ranked summary table.
