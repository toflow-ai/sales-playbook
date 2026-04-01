---
description: Analyze pipeline health from toflow — prioritize deals, flag risks, surface hygiene issues, and get a weekly action plan
argument-hint: "<optional: filter by stage, owner, or pipeline name>"
---

# /pipeline-review

Pull your live pipeline from toflow, score health, prioritize deals, and get a concrete action plan. All data comes from toflow — no CSV uploads needed.

## Usage

```
/pipeline-review [optional: filter]
```

Filter context: $ARGUMENTS

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                     PIPELINE REVIEW                              │
├─────────────────────────────────────────────────────────────────┤
│  DATA PULL (live from toflow)                                    │
│  ✓ list_pipelines + list_stages → pipeline structure            │
│  ✓ list_records (deal) → all open deals with full fields        │
│  ✓ validate_and_preview_report + run_report → aggregated data   │
│  ✓ list_notes → check last activity on stale deals              │
│  ✓ list_tasks → outstanding tasks per deal                      │
├─────────────────────────────────────────────────────────────────┤
│  ANALYSIS                                                        │
│  ✓ Health score across 4 dimensions                             │
│  ✓ Deal prioritization matrix                                    │
│  ✓ Risk flags: stale, stuck, past close date, single-threaded   │
│  ✓ Hygiene issues: missing fields                                │
│  ✓ Weekly action plan with specific next steps                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Get Pipeline Structure

```
1. list_pipelines() → get pipeline IDs and names
   - If $ARGUMENTS specifies a pipeline: filter to that one
   - If multiple pipelines: show list, ask user which to review

2. list_stages(pipeline_id=...) → get stage names, order, probabilities
   - Build stage map: stage_id → {name, order, probability}
```

### Step 2: Pull All Open Deals

```
filter_guide() → confirm filter syntax

list_records(
  resource_type=deal,
  filters=[
    {field: "status", operator: "is_not", value: "won"},
    {field: "status", operator: "is_not", value: "lost"}
  ],
  sort="Expected Close Date:asc",
  page_size=100
)

For each deal, note:
- deal_id, title, value, stage (resolve name from stage map)
- probability, priority, intent
- expected_close_date, created_at, updated_at
- company reference, people references
- owner
```

### Step 3: Run Aggregate Report

```
validate_and_preview_report(
  dataset_id=10,  // Deals dataset
  query={
    group_by="stage_name",
    metrics=[
      {field: "value", aggregation: "sum", alias: "total_value"},
      {field: "deal_id", aggregation: "count", alias: "deal_count"},
      {field: "probability", aggregation: "avg", alias: "avg_probability"}
    ]
  }
)
run_report(...) → pipeline by stage summary

run_report with group_by="close_month" → pipeline by close month
```

### Step 4: Flag Deals by Risk Type

For each deal, classify:

**Stale (no activity 14+ days):**
```
- Check deal updated_at field
- If updated_at < today - 14 days: flag as stale
- Check list_notes(resource_type=deal, resource_id=...) for recent notes
```

**Stuck (same stage 30+ days):**
- If deal age > 30 days AND still in early stage (discovery/qualification): flag

**Past close date:**
- If expected_close_date < today: flag

**Single-threaded (only one contact):**
- If deal.people has only 1 person: flag as risk

**Missing data (hygiene):**
- No expected_close_date
- No value (or value = 0)
- No associated people
- No company linked

### Step 5: Prioritize Deals

Rank using this weighted formula:
- Close Date (30%): Deals closing soonest score higher
- Value (25%): Larger deals score higher
- Stage (20%): Later stage (higher order) scores higher
- Intent (15%): Very Hot=4, Hot=3, Warm=2, Cold=1
- Risk (10%): Fewer risk flags = higher score

Produce three tiers:
- **Focus now** — closing <7 days OR very high value + hot
- **Keep warm** — closing <30 days, actively progressing
- **Nurture** — everything else

### Step 6: Generate Action Plan

For each Focus/Keep Warm deal, suggest a specific next action based on:
- Current stage + typical next step
- Last activity (stale? re-engage)
- Open tasks (complete outstanding commitments)
- Past close date (reschedule or close lost)

---

## Output

```markdown
# Pipeline Review | [Date]

**Pipeline:** [Name] | **Deals:** [N] | **Total Value:** $[X]

---

## Pipeline Health Score: [X/100]

| Dimension | Score | Issue |
|-----------|-------|-------|
| Stage Progression | [X]/25 | [X] deals stuck 30+ days |
| Activity Recency | [X]/25 | [X] deals silent 14+ days |
| Close Date Accuracy | [X]/25 | [X] past close dates |
| Contact Coverage | [X]/25 | [X] single-threaded |

---

## Top Priority Actions This Week

### 1. [Deal Name] — $[Value]
**Why:** [Closing soon / High value + stale / Hot intent]
**Stage:** [Stage] | **Close:** [Date] | **Intent:** [Level]
**Action:** [Specific next step — e.g., "Send proposal, close date is [date]"]

### 2. [Deal Name] — $[Value]
**Why:** [Reason]
**Action:** [Next step]

### 3. [Deal Name] — $[Value]
**Why:** [Reason]
**Action:** [Next step]

---

## Deal Matrix

### Focus Now (Close <7 Days or Critical)
| Deal | Value | Stage | Close Date | Intent | Next Action |
|------|-------|-------|------------|--------|-------------|
| [Deal] | $[X] | [Stage] | [Date] | [Intent] | [Action] |

### Keep Warm (Close <30 Days)
| Deal | Value | Stage | Close Date | Last Activity | Status |
|------|-------|-------|------------|---------------|--------|
| [Deal] | $[X] | [Stage] | [Date] | [N days ago] | [OK/Stale] |

### Nurture (30+ Days Out)
| Deal | Value | Stage | Close Date | Probability |
|------|-------|-------|------------|-------------|
| [Deal] | $[X] | [Stage] | [Date] | [X]% |

---

## Risk Flags

### Stale (No Activity 14+ Days)
| Deal | Value | Last Activity | Days Silent | Action |
|------|-------|---------------|-------------|--------|
| [Deal] | $[X] | [Date] | [N] | Re-engage / Downgrade / Close lost |

### Past Close Date
| Deal | Value | Was Due | Days Overdue | Action |
|------|-------|---------|--------------|--------|
| [Deal] | $[X] | [Date] | [N] | Update date / Push quarter / Close lost |

### Single-Threaded
| Deal | Value | Only Contact | Risk | Action |
|------|-------|-------------|------|--------|
| [Deal] | $[X] | [Name/Title] | Champion leaves = deal dies | Find second contact |

---

## Hygiene Issues

| Issue | Count | Deals | Suggested Fix |
|-------|-------|-------|---------------|
| Missing close date | [N] | [Names] | Set realistic date |
| Missing value | [N] | [Names] | Estimate and update |
| No contacts linked | [N] | [Names] | Add person to deal |
| No company linked | [N] | [Names] | Link company record |

---

## Pipeline Shape

### By Stage
| Stage | Deals | Value | Probability | Weighted |
|-------|-------|-------|-------------|---------|
| [Stage] | [N] | $[X] | [X]% | $[X] |

### By Close Month
| Month | Deals | Value |
|-------|-------|-------|
| [Month] | [N] | $[X] |

---

## Deals to Consider Closing Lost

| Deal | Value | Reason | Recommendation |
|------|-------|--------|----------------|
| [Deal] | $[X] | [60+ days no activity, no response] | Mark lost |

---

## Recommended Updates

Want me to apply any of these updates now?
- [ ] Update close dates for [N] overdue deals
- [ ] Set Intent to Cold for [N] stale deals
- [ ] Create follow-up tasks for priority deals
- [ ] Mark [N] dead deals as closed-lost
```

---

## Tips

1. **Run weekly** — Pipeline health decays fast
2. **Be ruthless about close lost** — Stale deals distort your forecast
3. **Multi-thread everything** — Every deal should have 2+ contacts
4. **Close dates mean something** — Only set what you'd bet on
